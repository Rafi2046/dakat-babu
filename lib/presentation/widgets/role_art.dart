import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';

/// Displays the CPDB character standing art for a [GameRole].
class RoleVectorIcon extends StatelessWidget {
  final GameRole role;
  final double size;
  final bool hasGlow;

  const RoleVectorIcon({
    super.key,
    required this.role,
    this.size = 36.0,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: hasGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: role.color.withValues(alpha: 0.45),
                  blurRadius: size * 0.45,
                  spreadRadius: size * 0.05,
                ),
              ],
            )
          : null,
      child: ClipOval(
        child: Image.asset(
          role.standingAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: role.containerColor,
            child: Icon(Icons.person, color: role.color, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

/// Full role portrait for reveal cards.
class RolePortrait extends StatelessWidget {
  final GameRole role;
  final double height;

  const RolePortrait({super.key, required this.role, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      role.standingAsset,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => RoleVectorIcon(role: role, size: height * 0.5),
    );
  }
}
