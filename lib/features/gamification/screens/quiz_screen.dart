import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/providers/user_provider.dart';
import '../models/quiz_entity.dart';
import '../services/quiz_service.dart';
import '../services/daily_test_service.dart'; // Phase 47: Daily Test
import '../../../core/services/sound_service.dart';
import '../../../core/services/user_service.dart'; // Phase 16
import '../../../core/widgets/app_bar_profile_button.dart';
import '../../../core/widgets/glass_container.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicTitle;
  final String? subjectName; // Added for Analytics
  final QuizEntity? seededQuiz;
  final bool isDailyTest; // Added for Daily Test Logic

  const QuizScreen({
    super.key, 
    required this.topicId, 
    required this.topicTitle, 
    this.subjectName,
    this.seededQuiz,
    this.isDailyTest = false,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> with TickerProviderStateMixin {
  QuizEntity? _quiz;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _timeLeft = 60;
  Timer? _timer;
  late AnimationController _timerPulseController;
  late Animation<double> _timerPulseAnimation;
  
  // Scoring
  double _score = 0.0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _skippedCount = 0;
  
  // State for current question
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  bool _isSkipped = false;

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
    
    // Timer pulse animation
    _setupTimerPulse();
  }

  void _setupTimerPulse() {
    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _timerPulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _timerPulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchQuiz() async {
    try {
      // 1. If we have a seeded quiz (passed from Loading Screen), use it directly
      if (widget.seededQuiz != null && widget.seededQuiz!.questions.isNotEmpty) {
        if (mounted) {
          setState(() {
            _quiz = widget.seededQuiz;
            _isLoading = false;
          });
          _startTimer();
        }
        return;
      }

      // 2. Otherwise fetch from Firestore
      final quiz = await QuizService().getQuiz(widget.topicId);
      
      if (mounted) {
        if (quiz != null && quiz.questions.isNotEmpty) {
          setState(() {
            _quiz = quiz;
            _isLoading = false;
          });
          _startTimer();
        } else {
          // Fallback: No quiz found or empty in Firestore, load 5 default sample questions
          debugPrint('No quiz found for ${widget.topicId}, loading samples.');
          setState(() {
            _quiz = QuizEntity.sample();
            _isLoading = false;
          });
          _startTimer();
        }
      }
    } catch (e) {
      debugPrint('Error fetching quiz: $e');
      if (mounted) {
        setState(() {
          _quiz = QuizEntity.sample();
          _isLoading = false;
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
        if (_timeLeft <= 10 && _timeLeft > 0) {
           _timerPulseController.forward(from: 0.0);
           SoundService().playButtonTap(); // Add an urgent tick sound, buttonTap might be too subtle, maybe need a specific tick sound
        }
      } else {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    _timer?.cancel();
    if (!_isAnswered) {
      _skipQuestion(); // Auto-skip on time up
    }
  }

  void _skipQuestion() {
    if (_isAnswered) return;
    
    _timer?.cancel();
    setState(() {
      _isAnswered = true;
      _isSkipped = true;
      _skippedCount++;
    });
    SoundService().playButtonTap(); // Tactical skip sound
  }

  void _submitAnswer(int optionIndex) {
    if (_isAnswered) return;

    _timer?.cancel();
    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = optionIndex;
    });

    final question = _quiz!.questions[_currentQuestionIndex];
    if (optionIndex == question.correctOptionIndex) {
      _score += 2.0;
      _correctCount++;
      SoundService().playLevelUp(); // Correct sound
    } else {
      _score -= 0.66;
      _wrongCount++;
      SoundService().playError(); // Incorrect sound 
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quiz!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _isSkipped = false;
        _selectedOptionIndex = null;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final user = ref.read(userProvider);
    final totalQ = _quiz!.questions.length;
    final maxScore = totalQ * 2;
    final passingScore = maxScore * 0.4; // 40% passing
    final passed = _score >= passingScore;

    // Generate hashes from question texts to track answered questions
    final answeredHashes = _quiz!.questions.map((q) => q.questionText.hashCode.toString()).toList();

    // Save Result (Classic)
    await QuizService().saveQuizResult(
        user.uid, 
        widget.topicId,
        _score, 
        totalQ, 
        passed,
        subject: widget.subjectName,
        squadId: user.squadId,
        answeredQuestionHashes: answeredHashes,
    );

    // Save Result (Daily Test Offline Logic)
    if (widget.isDailyTest) {
      await DailyTestService().saveDailyScore(_score);
    }

    // Phase 16: Log Activity
    await UserService().updateActivity(
      userId: user.uid,
      squadId: user.squadId ?? '',
      userName: user.name ?? 'Cadet',
      actionType: passed ? 'conquered' : 'failed',
      description: passed ? 'completed ${widget.topicTitle} Practice' : 'failed ${widget.topicTitle} Practice',
    );

    if (!mounted) return;

    // Phase 54: Navigate to Mission Debrief
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          passed: passed,
          score: _score,
          totalQuestions: totalQ,
          correctCount: _correctCount,
          wrongCount: _wrongCount,
          skippedCount: _skippedCount,
          topicId: widget.topicId,
          topicTitle: widget.topicTitle,
        ),
      ),
    );

    if (!mounted) return;

    if (widget.isDailyTest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text("DAILY MISSION COMPLETED!", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (result == 'retry') {
      _restartQuiz();
    } else {
       // Exit or Map
       Navigator.pop(context, passed); 
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _correctCount = 0;
      _wrongCount = 0;
      _skippedCount = 0;
      _isAnswered = false;
      _isSkipped = false;
      _selectedOptionIndex = null;
      _timeLeft = 60;
      _isLoading = false; 
    });
    _startTimer();
  }

  // _buildActionButton removed as it was part of the legacy dialog system.

  @override
  void dispose() {
    _timer?.cancel();
    _timerPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text("Unable to load quiz data.", style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Text("Topic: ${widget.topicTitle}", style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchQuiz();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2), foregroundColor: Colors.cyanAccent),
                child: const Text("RETRY MISSION"),
              ),
            ],
          ),
        ),
      );
    }

    final question = _quiz!.questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("PRACTICE: ${widget.topicTitle}", style: GoogleFonts.orbitron(fontSize: 14), overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          tooltip: 'End Quiz',
          onPressed: () async {
            final abort = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                title: Text('END QUIZ?', style: GoogleFonts.blackOpsOne(color: Colors.redAccent)),
                content: const Text('Are you sure you want to exit? Your progress will be lost.', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('CANCEL', style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('EXIT', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            );
            if (abort == true && mounted) Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _buildTimerWidget(),
          ),
          const AppBarProfileButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Progress
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _quiz!.questions.length,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
            ),
            _buildScoreBadge(),
            const SizedBox(height: 24),
            
            // Question Card
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: GlassContainer(
                key: ValueKey<int>(_currentQuestionIndex), // Important for AnimatedSwitcher
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                padding: const EdgeInsets.all(20),
                child: _buildQuestionDisplay(question),
              ),
            ),
            const SizedBox(height: 24),

            // Skip Button
            if (!_isAnswered) 
              Center(
                child: TextButton.icon(
                  onPressed: _skipQuestion,
                  icon: const Icon(Icons.skip_next, color: Colors.white54, size: 18),
                  label: Text(
                    "SKIP QUESTION",
                    style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),

            // Options
            ...List.generate(question.options.length, (index) {
              final isSelected = _selectedOptionIndex == index;
              final isCorrect = index == question.correctOptionIndex;
              
              Color tileColor = Colors.white.withValues(alpha: 0.05);
              Color borderColor = Colors.white24;

              if (_isAnswered) {
                if (isCorrect) {
                  tileColor = Colors.green.withValues(alpha: 0.2);
                  borderColor = Colors.greenAccent;
                } else if (isSelected && !isCorrect) {
                  tileColor = Colors.red.withValues(alpha: 0.2);
                  borderColor = Colors.redAccent;
                }
              } else if (_isSkipped) {
                if (isCorrect) {
                  borderColor = Colors.cyanAccent.withValues(alpha: 0.5);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0), // Increased Padding (Phase 47)
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  transform: isSelected && _isAnswered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
                  transformAlignment: Alignment.center,
                  child: InkWell(
                    onTap: _isAnswered ? null : () {
                      HapticFeedback.lightImpact();
                      _submitAnswer(index);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // Increased Internal Padding
                      decoration: BoxDecoration(
                        color: tileColor,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected && !_isAnswered ? [
                          BoxShadow(color: Colors.white24, blurRadius: 8, spreadRadius: 1)
                        ] : null,
                      ),
                      child: Text(
                        question.options[index],
                        style: GoogleFonts.merriweather(color: Colors.white, fontSize: 16, height: 1.4), // Serif for Options too
                      ),
                    ),
                  ),
                ),
              );
            }),

             if (_isAnswered) ...[
               AnimatedSize(
                 duration: const Duration(milliseconds: 400),
                 curve: Curves.easeInOutBack,
                 child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 24.0),
                   child: GlassContainer(
                     color: Colors.cyanAccent.withValues(alpha: 0.05),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                     padding: const EdgeInsets.all(16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 18),
                             const SizedBox(width: 8),
                             Text(
                               "EXPLANATION",
                               style: GoogleFonts.orbitron(
                                 color: Colors.cyanAccent,
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold,
                                 letterSpacing: 1.2,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),
                         Text(
                           question.explanation,
                           style: GoogleFonts.merriweather(
                             color: Colors.white70,
                             fontSize: 14,
                             height: 1.5,
                             fontStyle: FontStyle.italic,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
               ElevatedButton(
                 onPressed: _nextQuestion,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                   foregroundColor: Colors.cyanAccent,
                   side: const BorderSide(color: Colors.cyanAccent),
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
                 child: Text(
                   _currentQuestionIndex < _quiz!.questions.length - 1 ? "NEXT QUESTION" : "VIEW RESULTS",
                   style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                 ),
               ),
             ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTimerWidget() {
    final progress = _timeLeft / 60.0;
    final timerColor = _timeLeft < 10 ? Colors.redAccent : Colors.amber;
    
    Widget timerCore = SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(timerColor),
            strokeWidth: 3,
          ),
          Text(
            '$_timeLeft',
            style: TextStyle(
              color: timerColor,
              fontWeight: FontWeight.bold,
              fontSize: _timeLeft < 10 ? 14 : 13,
            ),
          ),
        ],
      ),
    );

    if (_timeLeft <= 10) {
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: _timerPulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _timerPulseAnimation.value,
              child: child,
            );
          },
          child: timerCore,
        ),
      );
    }
    return RepaintBoundary(child: timerCore);
  }

  Widget _buildScoreBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMiniMetric("CORRECT", _correctCount.toString(), Colors.greenAccent),
        _buildMiniMetric("SKIPPED", _skippedCount.toString(), Colors.white54),
        Column(
          children: [
            Text(
              "SCORE",
              style: GoogleFonts.shareTechMono(color: Colors.amber, fontSize: 10),
            ),
            Text(
              _score.toStringAsFixed(2),
              style: GoogleFonts.orbitron(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        _buildMiniMetric("WRONG", _wrongCount.toString(), Colors.redAccent),
        _buildMiniMetric("Q", "${_currentQuestionIndex + 1}/${_quiz!.questions.length}", Colors.cyanAccent),
      ],
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.shareTechMono(color: color.withValues(alpha: 0.7), fontSize: 8)),
      ],
    );
  }

  Widget _buildQuestionDisplay(QuestionEntity question) {
    // Phase 47: Operation Typesetter - Structured Rendering
    
    // CASE A: Structured Statement Analysis
    if (question.type == 'statement_analysis' && question.statements != null && question.statements!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Stem
          if (question.stem != null)
             Text(
               question.stem!, 
               style: GoogleFonts.merriweather(
                 fontSize: 18, 
                 height: 1.5, 
                 fontWeight: FontWeight.bold, 
                 color: const Color(0xFFE2E8F0) // Slate 200
               )
             ),
          
          const SizedBox(height: 20),
          
          // 2. Statements (The "Cards")
          ...question.statements!.map((stmt) {
             return Container(
               width: double.infinity,
               margin: const EdgeInsets.only(bottom: 12),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF1E293B), // Slate 800
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.white10),
               ),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Bullet or Number? statements usually have "1. " inside them from logic
                   Expanded(
                     child: Text(
                       stmt, 
                       style: GoogleFonts.robotoMono(
                         fontSize: 15, 
                         height: 1.4, 
                         color: Colors.cyanAccent
                       )
                     ),
                   ),
                 ],
               ),
             );
          }),

          const SizedBox(height: 20),

          // 3. The Ask
          if (question.ask != null)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               decoration: BoxDecoration(
                 border: Border(left: BorderSide(color: Colors.amber, width: 4)),
               ),
               child: Text(
                 question.ask!, 
                 style: GoogleFonts.merriweather(
                   fontSize: 16, 
                   height: 1.4, 
                   fontStyle: FontStyle.italic, 
                   color: Colors.amberAccent
                 )
               ),
             ),
        ],
      );
    }

    // CASE B: Simple MCQ with Stem (Structured)
    if (question.type == 'simple_mcq' && question.stem != null) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(
               question.stem!, 
               style: GoogleFonts.merriweather(
                 fontSize: 18, 
                 height: 1.6, 
                 fontWeight: FontWeight.bold, 
                 color: Colors.white
               )
             ),
             if (question.ask != null) ...[
                const SizedBox(height: 16),
                Text(
                 question.ask!, 
                 style: GoogleFonts.merriweather(
                   fontSize: 16, 
                   height: 1.5, 
                   fontStyle: FontStyle.italic, 
                   color: Colors.amberAccent
                 )
               ),
             ]
         ],
       );
    }
    
    // CASE C: Legacy / Fallback (Raw Text)
    // Try to parse if it looks like statements but isn't structured (Legacy Bank data)
    return Text(
      question.questionText, 
      style: GoogleFonts.merriweather(
        fontSize: 18, 
        height: 1.6, 
        fontWeight: FontWeight.bold, 
        color: Colors.white
      )
    );
  }
}

