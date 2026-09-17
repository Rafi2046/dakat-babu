import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A living ambient background with drifting luminous party particles and deep cosmic radial glow.
class AnimatedLivingBackground extends StatefulWidget {
  final Widget child;

  const AnimatedLivingBackground({super.key, required this.child});

  @override
  State<AnimatedLivingBackground> createState() => _AnimatedLivingBackgroundState();
}

class _AnimatedLivingBackgroundState extends State<AnimatedLivingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // Generate 18 ambient floating particles with soft role colors
    const colors = [
      AppColors.primary,
      AppColors.raja,
      AppColors.secondary,
      AppColors.mantri,
      AppColors.police,
      AppColors.chor,
    ];

    for (var i = 0; i < 18; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: 3.0 + _random.nextDouble() * 6.0,
          speed: 0.15 + _random.nextDouble() * 0.35,
          color: colors[i % colors.length],
          baseOpacity: 0.08 + _random.nextDouble() * 0.18,
          phase: _random.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Deep Gradient
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.darkBackgroundGradient,
          ),
        ),

        // Ambient Top-Right Radial Glow (Violet & Gold)
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Ambient Bottom-Left Radial Glow (Teal & Crimson)
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Drifting Living Particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              );
            },
          ),
        ),

        // Main Child Content
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  final double radius;
  final double speed;
  final Color color;
  final double baseOpacity;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.color,
    required this.baseOpacity,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = (p.y - (progress * p.speed)) % 1.0;
      final currentX = (p.x + math.sin(progress * 2 * math.pi + p.phase) * 0.04) % 1.0;
      final pulse = (math.sin(progress * 4 * math.pi + p.phase) + 1.0) / 2.0;
      final opacity = (p.baseOpacity * (0.6 + pulse * 0.4)).clamp(0.0, 1.0);

      final center = Offset(currentX * size.width, currentY * size.height);

      // Soft outer halo
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2.2);
      canvas.drawCircle(center, p.radius * 1.8, glowPaint);

      // Inner particle core
      final corePaint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.drawCircle(center, p.radius, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
