import 'package:flutter/material.dart';

class PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const PulseIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 80.0,
  });

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size * 2.5,
          height: widget.size * 2.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.1 * _fadeAnimation.value),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.5 * _fadeAnimation.value),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2 * _fadeAnimation.value),
                blurRadius: 20 * _scaleAnimation.value,
                spreadRadius: 5 * _scaleAnimation.value,
              )
            ],
          ),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                widget.icon,
                size: widget.size,
                color: widget.color.withValues(alpha: _fadeAnimation.value),
              ),
            ),
          ),
        );
      },
    );
  }
}

