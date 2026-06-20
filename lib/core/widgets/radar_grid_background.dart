import 'dart:math';
import 'package:flutter/material.dart';

class RadarGridBackground extends StatefulWidget {
  final Color color;
  const RadarGridBackground({super.key, this.color = const Color(0xFF00F0FF)});

  @override
  State<RadarGridBackground> createState() => _RadarGridBackgroundState();
}

class _RadarGridBackgroundState extends State<RadarGridBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _RadarGridPainter(_controller, widget.color),
        child: Container(),
      ),
    );
  }
}

class _RadarGridPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _RadarGridPainter(this.animation, this.color) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Paint sweepPaint = Paint()
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = max(size.width, size.height);

    // Draw Grid (Circles)
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, (radius / 5) * i, linePaint);
    }

    // Draw Grid (Lines)
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi) / 4;
      canvas.drawLine(
        center,
        Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius),
        linePaint,
      );
    }

    // Draw Radar Sweep
    final sweepShader = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: 2 * pi,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.2),
      ],
      stops: const [0.8, 1.0],
      transform: GradientRotation(animation.value * 2 * pi - pi / 2),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    sweepPaint.shader = sweepShader;
    canvas.drawCircle(center, radius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

