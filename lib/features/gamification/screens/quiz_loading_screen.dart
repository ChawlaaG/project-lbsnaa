import 'package:flutter/material.dart';
import 'package:cadre_upsc/core/widgets/particle_background.dart';

import 'package:cadre_upsc/features/gamification/screens/quiz_screen.dart';
import 'package:cadre_upsc/features/gamification/services/quiz_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/features/gamification/models/quiz_entity.dart';

class QuizLoadingScreen extends StatefulWidget {
  final String topicId;
  final String subjectName;
  final String stateName; // e.g., "Bihar"
  final String difficulty;
  final bool isDailyTest; // Added for Phase 47

  const QuizLoadingScreen({
    super.key,
    required this.topicId,
    required this.subjectName,
    required this.stateName,
    this.difficulty = 'Officer',
    this.isDailyTest = false,
  });

  @override
  State<QuizLoadingScreen> createState() => _QuizLoadingScreenState();
}

class _QuizLoadingScreenState extends State<QuizLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  final QuizService _quizService = QuizService();
  
  // Tactical Log
  final List<String> _fullLog = [
    "Loading [State] Syllabus...",
    "Fetching [Subject] Questions...",
    "Analyzing [State] trends...",
    "Eliminating Easy Questions...",
    "Calibrating Difficulty to 'LBSNAA' Level...",
    "Preparing [State] Practice Quiz...",
  ];
  final List<String> _visibleLogs = [];
  Timer? _logTimer;
  Timer? _timeoutTimer;
  bool _showRetry = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 1. Start Animation
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 2. Start Tactical Log
    _startTacticalLog();

    // 3. Start Timeout Timer
    _startTimeoutTimer();

    // 4. Trigger Quiz Generation
    _loadQuiz();
  }

  void _startTacticalLog() {
    _logTimer?.cancel(); // Clear existing if any
    int index = 0;
    _logTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) return;
      if (index < _fullLog.length) {
        setState(() {
          String message = _fullLog[index]
              .replaceAll("[Subject]", widget.subjectName)
              .replaceAll("[State]", widget.stateName);
          _visibleLogs.insert(0, "> $message");
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel(); // Clear existing if any
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (mounted && _isLoading) {
        setState(() {
          _showRetry = true;
          _visibleLogs.insert(0, "!! ALERT: Connection Latency Detected. !!");
          _visibleLogs.insert(0, "!! Retry to re-establish uplink. !!");
        });
      }
    });
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _showRetry = false;
    });

    try {
      // Fetch User Difficulty (using ref if available, or just passed context if we had provider access here easily)
      // Since this is a StatefulWidget, we might need to change it to ConsumerStatefulWidget to access ref.
      // But to save refactoring time, let's fetch from Firestore directly or just assume 'Officer' if not found.
      // ACTUALLY: Best practice is to pass it in, but we want it global. 
      // Let's change this to ConsumerStatefulWidget to read the userProvider.
      
      // WAIT: I cannot easily change the whole class definition via replace_content without rewriting the whole file. 
      // I will use a quick Firestore fetch here for 100% accuracy, or if I can assume the UserProvider is available upstream.
      // Let's use Firestore for robustness here as we are inside an async method.
      
      String difficulty = widget.difficulty;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists) {
            // Only override if not explicitly passed a non-default (or just use widget.difficulty if provided)
            // Actually, if RapidFire passed it, we should use it. 
            // If it's the default 'Officer', we can check if user has a preference.
            if (widget.difficulty == 'Officer') {
              difficulty = doc.data()?['difficultyLevel'] ?? 'Officer';
            }
          }
        }
      } catch (e) {
        // failed to fetch, default to widget.difficulty
      }

      final startTime = DateTime.now();
      final quiz = await _quizService.getOrGenerateQuiz(widget.topicId, widget.subjectName, widget.stateName, difficulty: difficulty);

      if (!mounted) return;

      if (quiz != null) {
        // Enforce exactly 15 questions for Daily Test
        if (widget.isDailyTest) {
          if (quiz.questions.length > 15) {
            quiz.questions.removeRange(15, quiz.questions.length);
          } else if (quiz.questions.length < 15) {
            // Pad with sample questions if too few
            final samples = QuizEntity.sample().questions;
            for (int i = 0; quiz.questions.length < 15 && i < samples.length; i++) {
              quiz.questions.add(samples[i]);
            }
          }
        }

        // Ensure minimum 3 second display time for tactical logs
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        if (elapsed < 3) {
          await Future.delayed(Duration(seconds: 3 - elapsed));
        }

        if (!mounted) return;
        
        _logTimer?.cancel();
        _timeoutTimer?.cancel();
        
         // Construct title for QuizScreen
        final displayTitle = "${widget.stateName}: ${widget.subjectName}";

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => QuizScreen(
              topicId: widget.topicId,
              topicTitle: displayTitle,
              subjectName: widget.subjectName, // Phase 43: Analytics
              seededQuiz: quiz, 
              isDailyTest: widget.isDailyTest,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutQuart;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      } else {
        _handleError("Quiz not found. Please try again.");
      }

    } catch (e) {
      if (!mounted) return;
      _handleError("Connection Lost: $e");
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _showRetry = true;
      _visibleLogs.insert(0, "!! ERROR: $message !!");
    });
  }

  void _retry() {
    setState(() {
      _visibleLogs.clear();
      _visibleLogs.insert(0, "> Re-initializing Sequence...");
      _startTacticalLog();
      _startTimeoutTimer();
      _loadQuiz();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _logTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Navy
      body: Stack(
        children: [
           // Background Particles
           const Positioned.fill(
             child: ParticleBackground(
               numberOfParticles: 20,
               color: Colors.blueAccent,
             ),
           ),
           
           Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 // Radar Scanner Animation
                 SizedBox(
                   width: 120,
                   height: 120,
                   child: Stack(
                     alignment: Alignment.center,
                     children: [
                       // Static Circles
                       Container(
                         decoration: BoxDecoration(
                           shape: BoxShape.circle, 
                           border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 1)
                         ),
                       ),
                        Container(
                         width: 80,
                         height: 80,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle, 
                           border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 1)
                         ),
                       ),
                       // Rotating Scanner
                       RotationTransition(
                         turns: _scannerController,
                         child: Container(
                           decoration: BoxDecoration(
                             gradient: SweepGradient(
                               center: Alignment.center,
                               startAngle: 0.0,
                               endAngle: 6.28,
                               colors: [
                                 Colors.transparent,
                                 Colors.greenAccent.withValues(alpha: 0.1),
                                 Colors.greenAccent.withValues(alpha: 0.5),
                               ],
                               stops: const [0.5, 0.75, 1.0],
                             ),
                             shape: BoxShape.circle,
                           ),
                         ),
                       ),
                       const Icon(Icons.radar, size: 40, color: Colors.greenAccent),
                     ],
                   ),
                 ),
                 
                 const SizedBox(height: 30),
                 
                 // Tactical Log Console
                 Container(
                   width: MediaQuery.of(context).size.width * 0.85,
                   height: 200,
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.black.withValues(alpha: 0.8),
                     border: Border.all(color: Colors.greenAccent, width: 1),
                     borderRadius: BorderRadius.circular(8),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.greenAccent.withValues(alpha: 0.2),
                         blurRadius: 10,
                         spreadRadius: 2,
                       )
                     ]
                   ),
                   child: ListView.builder(
                     reverse: true, // Auto-scroll to bottom (newest first)
                     itemCount: _visibleLogs.length,
                     itemBuilder: (context, index) {
                       return Padding(
                         padding: const EdgeInsets.symmetric(vertical: 4.0),
                         child: Text(
                           _visibleLogs[index],
                           style: GoogleFonts.shareTechMono(
                             color: Colors.greenAccent,
                             fontSize: 12,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       );
                     },
                   ),
                 ),
                 
                 const SizedBox(height: 20),
                 
                 // Retry Button
                 if (_showRetry)
                   ElevatedButton.icon(
                     onPressed: _retry,
                     icon: const Icon(Icons.refresh, color: Colors.black),
                     label: const Text("TRY AGAIN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.greenAccent,
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     ),
                   ),
               ],
             ),
           ),
        ],
      ),
    );
  }
}

