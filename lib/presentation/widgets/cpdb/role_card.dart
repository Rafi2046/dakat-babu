import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/game/game_role.dart';

/// Private role reveal card — premium badge presentation.
class RoleCard extends StatelessWidget {
  final GameRole role;
  final String? instructionOverride;
  final bool compact;

  const RoleCard({
    super.key,
    required this.role,
    this.instructionOverride,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeH = compact ? 140.0 : 220.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 20,
        compact ? 16 : 20,
        compact ? 16 : 20,
        compact ? 16 : 22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(role.color, Colors.black, 0.15)!,
            Color.lerp(role.color, const Color(0xFF0B0E14), 0.55)!,
            const Color(0xFF0B0E14),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: role.color.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'তোমার রোল',
            style: AppTextStyles.caption(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          AppSpacing.gapVSm,
          Text(
            role.shortName.toUpperCase(),
            style: AppTextStyles.heading1(color: Colors.white).copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: role.color.withValues(alpha: 0.7),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 12 : 18),
          // Floating badge — true PNG alpha, soft neon under-glow.
          SizedBox(
            height: badgeH,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: badgeH * 0.72,
                  height: badgeH * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: role.color.withValues(alpha: 0.55),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  role.badgeAsset,
                  height: badgeH,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Image.asset(
                    role.standingAsset,
                    height: badgeH,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.military_tech_rounded,
                      size: badgeH * 0.45,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            instructionOverride ?? role.instructions,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}
