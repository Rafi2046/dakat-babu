import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import 'role_art.dart';

/// An interactive 3D Flip Card widget for secret role unmasking.
///
/// Front side: Unrevealed royal chit card with confidentiality cues.
/// Back side: Revealed role card with custom vector art, instructions, and points.
class FlipRoleCard extends StatefulWidget {
  final GameRole? role;
  final bool isRevealed;
  final VoidCallback onToggle;

  const FlipRoleCard({
    super.key,
    required this.role,
    required this.isRevealed,
    required this.onToggle,
  });

  @override
  State<FlipRoleCard> createState() => _FlipRoleCardState();
}

class _FlipRoleCardState extends State<FlipRoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.isRevealed ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void didUpdateWidget(FlipRoleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed != oldWidget.isRevealed) {
      if (widget.isRevealed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi;
        final isFront = angle < (math.pi / 2);

        return GestureDetector(
          onTap: widget.onToggle,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront
                ? _buildFrontCard()
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBackCard(),
                  ),
          ),
        );
      },
    );
  }

  /// Front: Unrevealed Chit Card
  Widget _buildFrontCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0x38121624),
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock / Peek Emblem
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    PhosphorIcons.lockKey(PhosphorIconsStyle.bold),
                    size: 26,
                    color: AppColors.primaryLight,
                  ),
                ),
                AppSpacing.gapVSm,

                // Prompt
                Text(
                  'TAP TO REVEAL SECRET ROLE',
                  style: AppTextStyles.button(color: AppColors.primaryLight)
                      .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),

                // Privacy advice
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                      size: 13,
                      color: AppColors.textLightSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Keep your screen hidden from rivals!',
                      style: AppTextStyles.caption(
                        color: AppColors.textLightSecondary,
                      ).copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Back: Revealed Secret Role Card
  Widget _buildBackCard() {
    final role = widget.role ?? GameRole.chor;
    final roleColor = role.color;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0x38121624),
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: roleColor.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Subtle role watermark
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.4,
                    child: CustomPaint(
                      painter: RolePatternPainter(role: role),
                    ),
                  ),
                ),

                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Vector Art & Points Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoleVectorIcon(role: role, size: 44, hasGlow: true),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            '+${role.points} PTS',
                            style: AppTextStyles.caption(color: roleColor).copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Role Name
                    Text(
                      role.displayName.toUpperCase(),
                      style: AppTextStyles.heroTitle(color: roleColor)
                          .copyWith(fontSize: 26, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),

                    // Instructions
                    Text(
                      role.instructions,
                      style: AppTextStyles.bodyMedium(
                        color: Colors.white.withValues(alpha: 0.9),
                      ).copyWith(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Tap to hide hint
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
                          size: 12,
                          color: AppColors.textLightMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to flip & hide secret card',
                          style: AppTextStyles.caption(
                            color: AppColors.textLightMuted,
                          ).copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
