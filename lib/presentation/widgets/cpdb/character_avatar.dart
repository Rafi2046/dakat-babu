import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';

/// Circular avatar from asset or initials fallback.
class CharacterAvatar extends StatelessWidget {
  final String name;
  final String? assetPath;
  final double size;
  final Color? ringColor;
  final bool showRing;

  const CharacterAvatar({
    super.key,
    required this.name,
    this.assetPath,
    this.size = 48,
    this.ringColor,
    this.showRing = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = assetPath != null
        ? ClipOval(
            child: Image.asset(
              assetPath!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(),
            ),
          )
        : _initials();

    if (!showRing) return child;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ringColor ?? AppColors.primary,
          width: 2.5,
        ),
      ),
      child: child,
    );
  }

  Widget _initials() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: Text(
        name.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}
