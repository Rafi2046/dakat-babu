import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';

/// Cinematic tension wrapper for Police target-selection phase.
///
/// When [isActive] is false, returns [child] unchanged. When active, adds a
/// soft dual-edge siren glow (Chor red / Police blue) plus a breathing neon
/// aura around the child card grid — subtle enough for dark UI.
class TargetSelectionGlow extends StatelessWidget {
  final bool isActive;
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const TargetSelectionGlow({
    super.key,
    required this.isActive,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return child;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Soft edge siren wash — does not eat taps.
        Positioned.fill(
          child: IgnorePointer(
            child: const _SirenEdgeGlow()
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .fade(
                  begin: 0.28,
                  end: 0.72,
                  duration: 1400.ms,
                  curve: Curves.easeInOut,
                )
                .tint(
                  begin: 0,
                  end: 0.35,
                  color: AppColors.police.withValues(alpha: 0.35),
                  duration: 1800.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ),

        // Breathing neon frame around the target grid.
        Padding(
          padding: padding,
          child: _BreathingTargetFrame(
            borderRadius: borderRadius,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _SirenEdgeGlow extends StatelessWidget {
  const _SirenEdgeGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.chor.withValues(alpha: 0.22),
            Colors.transparent,
            AppColors.police.withValues(alpha: 0.22),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.05,
            colors: [
              Colors.transparent,
              AppColors.chor.withValues(alpha: 0.08),
              AppColors.police.withValues(alpha: 0.1),
            ],
            stops: const [0.45, 0.78, 1.0],
          ),
        ),
      ),
    );
  }
}

class _BreathingTargetFrame extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const _BreathingTargetFrame({
    required this.child,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      effects: [
        CustomEffect(
          duration: 1200.ms,
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            final t = value.clamp(0.0, 1.0);
            final blur = 10.0 + (t * 18.0);
            final spread = 0.5 + (t * 4.5);
            final glowAlpha = 0.22 + (t * 0.28);

            return Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                  color: Color.lerp(
                    AppColors.police.withValues(alpha: 0.35),
                    AppColors.chor.withValues(alpha: 0.45),
                    t,
                  )!,
                  width: 1.4 + (t * 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.police.withValues(alpha: glowAlpha),
                    blurRadius: blur,
                    spreadRadius: spread,
                  ),
                  BoxShadow(
                    color: AppColors.chor.withValues(alpha: glowAlpha * 0.7),
                    blurRadius: blur * 0.85,
                    spreadRadius: spread * 0.6,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: child,
              ),
            );
          },
        ),
      ],
      child: child,
    );
  }
}
