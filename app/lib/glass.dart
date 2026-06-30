import 'dart:ui';
import 'package:flutter/material.dart';

class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final Color tint;
  final double borderOpacity;

  const Glass({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = 18,
    this.padding = const EdgeInsets.all(16),
    this.tint = Colors.white,
    this.borderOpacity = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint.withValues(alpha: 0.18),
                tint.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1020), Color(0xFF1A1140), Color(0xFF06121F)],
            ),
          ),
        ),
        _blob(const Alignment(-0.85, -0.75), const Color(0xFF6D5DF6), 320),
        _blob(const Alignment(0.9, -0.35), const Color(0xFF13C2C2), 280),
        _blob(const Alignment(-0.1, 0.85), const Color(0xFFEE6FA8), 300),
      ],
    );
  }

  Widget _blob(Alignment align, Color color, double size) {
    return Align(
      alignment: align,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}
