import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enableBlur; // Feature Flag for Performance

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 5.0, // Reduced from 10.0 for better performance
    this.opacity = 0.1,
    this.color = Colors.white,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.enableBlur = false, // Disabled by default — BackdropFilter is expensive on Android
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: enableBlur 
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: _buildContent(),
            )
          : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: enableBlur ? opacity : opacity + 0.1), // Increase opacity if no blur
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}
