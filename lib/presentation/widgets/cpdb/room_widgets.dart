import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import 'game_button.dart';

/// Large room code with copy action.
class RoomCodeCard extends StatelessWidget {
  final String roomCode;
  final VoidCallback? onShare;

  const RoomCodeCard({
    super.key,
    required this.roomCode,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text('ROOM CODE', style: AppTextStyles.caption()),
          AppSpacing.gapVSm,
          Text(
            roomCode,
            style: AppTextStyles.heading1(color: AppColors.secondary),
          ),
          AppSpacing.gapVMd,
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'COPY',
                  icon: Icons.copy,
                  variant: ButtonVariant.outlined,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomCode));
                    AppToast.show(context, 'Code copied!');
                  },
                ),
              ),
              if (onShare != null) ...[
                AppSpacing.gapHSm,
                Expanded(
                  child: GameButton(
                    label: 'SHARE',
                    icon: Icons.share,
                    onPressed: onShare,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// QR code for `dakatbabu://join/{code}`.
class QRCard extends StatelessWidget {
  final String roomCode;
  final double size;

  const QRCard({super.key, required this.roomCode, this.size = 160});

  @override
  Widget build(BuildContext context) {
    final data = AppConstants.joinDeepLink(roomCode);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: data,
            size: size,
            backgroundColor: Colors.white,
          ),
        ),
        AppSpacing.gapVSm,
        Text(
          'Scan to join',
          style: AppTextStyles.caption(),
        ),
      ],
    );
  }
}

/// Ready / Waiting pill.
class ReadyIndicator extends StatelessWidget {
  final bool isReady;

  const ReadyIndicator({super.key, required this.isReady});

  @override
  Widget build(BuildContext context) {
    final color = isReady ? AppColors.success : AppColors.textLightMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        isReady ? 'READY' : 'WAITING',
        style: AppTextStyles.caption(color: color),
      ),
    );
  }
}

/// Lightweight toast helper (uses SnackBar).
abstract final class AppToast {
  static void show(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.surfaceElevatedDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
