import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/extensions.dart';

/// Private role reveal card.
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        gradient: role.gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(
            color: role.color.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('তোমার রোল', style: AppTextStyles.caption(color: Colors.white70)),
          AppSpacing.gapVSm,
          Text(
            role.shortName.toUpperCase(),
            style: AppTextStyles.heading1(color: Colors.white),
          ),
          AppSpacing.gapVMd,
          Image.asset(
            role.standingAsset,
            height: compact ? 120 : 200,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.person,
              size: compact ? 80 : 120,
              color: Colors.white,
            ),
          ),
          AppSpacing.gapVMd,
          Text(
            instructionOverride ?? role.instructions,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
