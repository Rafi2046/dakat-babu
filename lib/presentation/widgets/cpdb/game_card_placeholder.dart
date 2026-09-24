import 'package:flutter/material.dart';

import '../../../core/constants/app_text_styles.dart';

/// Face-down role placeholder.
class GameCardPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const GameCardPlaceholder({
    super.key,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 320,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Text(label, style: AppTextStyles.heading3()),
      ),
    );
  }
}
