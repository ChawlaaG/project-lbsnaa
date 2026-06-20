import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cadre_upsc/core/widgets/particle_background.dart';

/// Shown dramatically when user breaks their streak.
class StreakBrokenScreen extends StatefulWidget {
  final int previousStreak;

  const StreakBrokenScreen({super.key, required this.previousStreak});

  @override
  State<StreakBrokenScreen> createState() => _StreakBrokenScreenState();
}

class _StreakBrokenScreenState extends State<StreakBrokenScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 3.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4)));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParticleBackground(numberOfParticles: 20, color: Colors.red),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated stamp
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => Transform.scale(
                      scale: _scale.value,
                      child: Opacity(
                        opacity: _opacity.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent, width: 4),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10)
                            ],
                          ),
                          child: Text(
                            'STREAK\nLOST',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.blackOpsOne(
                                color: Colors.redAccent, fontSize: 40, letterSpacing: 4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  Text(
                    'STREAK BROKEN',
                    style: GoogleFonts.orbitron(
                        color: Colors.white70, fontSize: 14, letterSpacing: 3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.previousStreak} DAY STREAK ENDED',
                    style: GoogleFonts.orbitron(
                        color: Colors.white38, fontSize: 12, letterSpacing: 2),
                  ),

                  const SizedBox(height: 32),

                  // Rank decay notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_down, color: Colors.redAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('STREAK RESET',
                                  style: GoogleFonts.orbitron(
                                      color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Keep practicing to build your streak again.',
                                  style: GoogleFonts.shareTechMono(
                                      color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('CONTINUE',
                        style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
