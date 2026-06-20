import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/core/widgets/particle_background.dart';
import 'package:share_plus/share_plus.dart';

import 'package:confetti/confetti.dart';
import 'package:cadre_upsc/core/services/sound_service.dart';

class QuizResultScreen extends StatefulWidget {
  final bool passed;
  final double score;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final String topicId;
  final String topicTitle;

  const QuizResultScreen({
    super.key,
    required this.passed,
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> with TickerProviderStateMixin {
  late AnimationController _stampController;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;

  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // 1. Stamp Animation (Impact effect)
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _stampScale = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.bounceOut),
    );
    _stampOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    // 2. Score Tally Animation
    _scoreController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    
    _scoreAnimation = Tween<double>(begin: 0.0, end: widget.score.toDouble()).animate(
       CurvedAnimation(parent: _scoreController, curve: Curves.easeOutExpo)
    );

    // Sequence
    Future.delayed(const Duration(milliseconds: 500), () {
      _stampController.forward();
      // Play Stamp Sound
      if (widget.passed) {
        SoundService().playLevelUp();
        _confettiController.play();
      } else {
        SoundService().playError();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 1200), () {
      _scoreController.forward();
      // Play Tally Sound
      if (widget.passed) SoundService().playButtonTap(); // Subtle tick for score
    });
  }

  @override
  void dispose() {
    _stampController.dispose();
    _scoreController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxScore = widget.totalQuestions * 2;
    final primaryColor = widget.passed ? Colors.greenAccent : Colors.redAccent;
    final statusText = widget.passed ? "MISSION\nACCOMPLISHED" : "KEEP\nFIGHTING";

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Navy
      body: Stack(
        children: [
          // Background
           const Positioned.fill(
             child: ParticleBackground(
               numberOfParticles: 15,
               color: Colors.blueGrey,
             ),
           ),
           
           Center(
             child: SingleChildScrollView(
               padding: const EdgeInsets.symmetric(vertical: 24),
               child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 // 1. Mission Folder Header
                 Text(
                    "QUIZ RESULTS",
                   style: GoogleFonts.shareTechMono(
                     color: Colors.white54,
                     fontSize: 14,
                     letterSpacing: 2.0,
                   ),
                 ),
                 const SizedBox(height: 10),
                 Text(
                   widget.topicTitle.toUpperCase(),
                   style: GoogleFonts.rajdhani(
                     color: Colors.white,
                     fontSize: 20,
                     fontWeight: FontWeight.bold,
                     letterSpacing: 1.5,
                   ),
                 ),
                 const SizedBox(height: 40),

                 // 2. The Stamp (Animated)
                 AnimatedBuilder(
                   animation: _stampController,
                   builder: (context, child) {
                     return Transform.scale(
                       scale: _stampScale.value,
                       child: Opacity(
                         opacity: _stampOpacity.value,
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                           decoration: BoxDecoration(
                             border: Border.all(color: primaryColor, width: 4),
                             borderRadius: BorderRadius.circular(8),
                             boxShadow: [
                               BoxShadow(
                                 color: primaryColor.withValues(alpha: 0.3),
                                 blurRadius: 20,
                                 spreadRadius: 5,
                               )
                             ]
                           ),
                           child: Text(
                             statusText,
                             textAlign: TextAlign.center,
                             style: GoogleFonts.blackOpsOne( // Stencil font if available, or heavy bold
                               color: primaryColor,
                               fontSize: 32,
                               letterSpacing: 2.0,
                             ),
                           ),
                         ),
                       ),
                     );
                   },
                 ),

                 const SizedBox(height: 50),

                 // 3. Score Tally
                  AnimatedBuilder(
                     animation: _scoreController,
                     builder: (context, child) {
                       return Column(
                         children: [
                           Text(
                             "${_scoreAnimation.value.toStringAsFixed(2)} / $maxScore",
                             style: GoogleFonts.orbitron(
                               color: Colors.amberAccent,
                               fontSize: 42,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                           Text(
                             "TOTAL SCORE", 
                             style: GoogleFonts.shareTechMono(color: Colors.amber, fontSize: 12)
                           ),
                           const SizedBox(height: 24),
                           
                           // Metrics Grid
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               _buildMetricItem("CORRECT", widget.correctCount.toString(), Colors.greenAccent),
                               _buildMetricDivider(),
                               _buildMetricItem("WRONG", widget.wrongCount.toString(), Colors.redAccent),
                               _buildMetricDivider(),
                               _buildMetricItem("SKIPPED", widget.skippedCount.toString(), Colors.white54),
                             ],
                           ),
                         ],
                       );
                     }
                  ),
                 
                  const SizedBox(height: 60),

                  // 3.5 Service Rank
                  _buildRankBadge(widget.score, maxScore),
                  
                  const SizedBox(height: 40),

                  // 4. Tactical Action Grid
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                      _buildTacticalButton(
                        icon: Icons.refresh,
                         label: "TRY AGAIN",
                        color: Colors.cyanAccent,
                        onTap: () {
                           SoundService().playButtonTap();
                           Navigator.pop(context, "retry"); 
                        }
                      ),
                       _buildTacticalButton(
                         icon: Icons.share, 
                          label: "SHARE",
                         color: Colors.amber, 
                         onTap: () {
                            SoundService().playButtonTap();
                            final scorePct = (widget.score / maxScore) * 100;
                            String rank = "RECRUIT";
                            if (scorePct >= 90) {
                              rank = "SECRETARY GEN";
                            } else if (scorePct >= 75) rank = "OFFICER ON DUTY";
                            else if (scorePct >= 50) rank = "CADET IN TRAINING";
                            else if (scorePct >= 33) rank = "PROBATIONER";
                            
                             Share.share("Scored ${widget.score.toStringAsFixed(2)} in ${widget.topicTitle}!\nRank: $rank\n\n#CADRE #UPSC");
                         }
                       ),
                      _buildTacticalButton(
                        icon: Icons.map,
                         label: "GO BACK",
                        color: Colors.white70,
                        onTap: () {
                           SoundService().playButtonTap();
                           Navigator.pop(context, "exit");
                        }
                      ),
                   ],
                 )
               ],
             ),
           ),
          ),
       // Victory Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(double score, int maxScore) {
    final percentage = (score / maxScore) * 100;
    String rank;
    Color color;
    IconData icon;

    if (percentage >= 90) {
      rank = "SECRETARY GEN";
      color = Colors.amberAccent;
      icon = Icons.stars;
    } else if (percentage >= 75) {
      rank = "OFFICER ON DUTY";
      color = Colors.blueAccent;
      icon = Icons.military_tech;
    } else if (percentage >= 50) {
      rank = "CADET IN TRAINING";
      color = Colors.greenAccent;
      icon = Icons.shield;
    } else if (percentage >= 33) {
      rank = "PROBATIONER";
      color = Colors.orangeAccent;
      icon = Icons.assignment_ind;
    } else {
      rank = "RECRUIT";
      color = Colors.redAccent;
      icon = Icons.person_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            "SERVICE RANK",
            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Text(
            rank,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${percentage.toStringAsFixed(0)}% accuracy",
            style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.shareTechMono(color: color.withValues(alpha: 0.7), fontSize: 10)),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white10,
    );
  }

  Widget _buildTacticalButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
             BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1)
          ]
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label, 
              style: GoogleFonts.rajdhani(color: color, fontWeight: FontWeight.bold)
            )
          ],
        ),
      ),
    );
  }
}

