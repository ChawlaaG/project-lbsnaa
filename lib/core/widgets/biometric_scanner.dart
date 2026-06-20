import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BiometricScanner extends StatefulWidget {
  final double size;
  final Color color;

  const BiometricScanner({
    super.key,
    this.size = 120.0,
    this.color = const Color(0xFF00F0FF), // Neon Cyan
  });

  @override
  State<BiometricScanner> createState() => _BiometricScannerState();
}

class _BiometricScannerState extends State<BiometricScanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black54,
        border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Static Fingerprint/Identity Icon
          Icon(
            Icons.fingerprint,
            size: widget.size * 0.6,
            color: widget.color.withValues(alpha: 0.2),
          ),
          
          // 2. Spinning Border or Radar
          RotationTransition(
            turns: _controller,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    widget.color.withValues(alpha: 0.1),
                    widget.color.withValues(alpha: 0.5),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Scanning Line (Safe Animation using Align)
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Align(
                alignment: Alignment(0, _scanAnimation.value),
                child: Container(
                  width: widget.size,
                  height: 2,
                  decoration: BoxDecoration(
                    color: widget.color,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                ),
              );
            },
          ),
          
          // 4. Label
          Positioned(
            bottom: 10,
            child: Text(
              "SCANNING...",
              style: GoogleFonts.shareTechMono(
                fontSize: 10,
                color: widget.color,
                letterSpacing: 2,
              ),
            ),
          )
        ],
      ),
    );
  }
}

