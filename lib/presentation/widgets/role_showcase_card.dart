import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import 'role_art.dart';

/// A sleek, modern showcase card for each [GameRole]
/// styled for a compact 2x2 grid with delicate glassmorphism and crisp vector iconography.
class RoleShowcaseCard extends StatelessWidget {
  final GameRole role;

  const RoleShowcaseCard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final roleColor = role.color;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x35141926),
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: roleColor.withValues(alpha: 0.22),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Subtle watermark pattern
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.5,
                    child: CustomPaint(
                      painter: RolePatternPainter(role: role),
                    ),
                  ),
                ),

                // Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top row: Vector icon + subtle points tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RoleVectorIcon(role: role, size: 24, hasGlow: false),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '+${role.points} pts',
                            style: AppTextStyles.caption(color: roleColor).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Role details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.displayName,
                          style: AppTextStyles.bodyMedium(color: Colors.white).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getSubtitle(role),
                          style: AppTextStyles.caption(
                            color: Colors.white.withValues(alpha: 0.65),
                          ).copyWith(fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  String _getSubtitle(GameRole role) {
    switch (role) {
      case GameRole.raja:
        return 'Declares court & glory';
      case GameRole.mantri:
        return 'Secret court advisor';
      case GameRole.police:
        return 'Finds & catches thief';
      case GameRole.chor:
        return 'Escapes & steals points';
    }
  }
}
