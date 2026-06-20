import 'dart:math';
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  final Color color;
  final int numberOfParticles;

  const ParticleBackground({
    super.key,
    this.color = const Color(0xFF03DAC6),
    this.numberOfParticles = 6,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initParticles(Size size) {
    if (_initialized) return;
    _initialized = true;
    final random = Random();
    _particles = List.generate(widget.numberOfParticles, (_) {
      return _Particle(
        position: Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        speed: random.nextDouble() * 0.4 + 0.1,
        theta: random.nextDouble() * 2 * pi,
        radius: random.nextDouble() * 2.5 + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initParticles(size); // only runs once
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return RepaintBoundary(
              child: CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  color: widget.color,
                  controllerValue: _controller.value,
                  size: size,
                ),
                size: size,
              ),
            );
          },
        );
      },
    );
  }
}

class _Particle {
  Offset position;
  double speed;
  double theta;
  double radius;

  _Particle({
    required this.position,
    required this.speed,
    required this.theta,
    required this.radius,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double controllerValue;
  final Size size;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.controllerValue,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      particle.position += Offset(
        particle.speed * cos(particle.theta),
        particle.speed * sin(particle.theta),
      );

      // Wrap around screen
      if (particle.position.dx < 0) particle.position = Offset(size.width, particle.position.dy);
      if (particle.position.dx > size.width) particle.position = Offset(0, particle.position.dy);
      if (particle.position.dy < 0) particle.position = Offset(particle.position.dx, size.height);
      if (particle.position.dy > size.height) particle.position = Offset(particle.position.dx, 0);

      canvas.drawCircle(particle.position, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.controllerValue != controllerValue;
}
