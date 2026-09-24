import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/cpdb/cpdb.dart';

class ConnectionErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const ConnectionErrorScreen({
    super.key,
    this.title = 'Connection lost',
    this.message = 'Trying to reconnect failed. Check your network.',
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppImages.chorStanding,
            height: 160,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.wifi_off, size: 80, color: Colors.white),
          ),
          AppSpacing.gapVLg,
          Text(title, style: AppTextStyles.heading1()),
          AppSpacing.gapVMd,
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(),
          ),
          AppSpacing.gapVXl,
          GameButton(label: 'TRY AGAIN', onPressed: () => context.pop()),
          AppSpacing.gapVMd,
          GameButton(
            label: 'GO HOME',
            onPressed: () => context.go(AppRoutes.home),
            variant: ButtonVariant.outlined,
          ),
        ],
      ),
    );
  }
}
