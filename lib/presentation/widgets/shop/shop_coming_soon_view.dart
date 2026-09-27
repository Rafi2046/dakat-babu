import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/home_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// Premium "Coming Soon" stub for the Shop tab — dark, tactile, no assets.
class ShopComingSoonView extends StatelessWidget {
  const ShopComingSoonView({super.key});

  static const Color _neon = AppColors.accent;
  static const Color _tapeYellow = Color(0xFFFFC107);
  static const Color _tapeBlack = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 320,
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _PoliceBarricadePadlock(),
                AppSpacing.gapVLg,
                Text(
                  l10n.comingSoon,
                  textAlign: TextAlign.center,
                  style: HomeTextStyles.hero(color: _neon).copyWith(
                    fontSize: 28,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: _neon.withValues(alpha: 0.85),
                        blurRadius: 18,
                      ),
                      Shadow(
                        color: _neon.withValues(alpha: 0.45),
                        blurRadius: 36,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.55, end: 1, duration: 1600.ms),
                AppSpacing.gapVSm,
                Text(
                  l10n.shopSubtitle,
                  textAlign: TextAlign.center,
                  style: HomeTextStyles.subtitle(
                    color: AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 3D padlock + police barricade tape built from Containers / Icons / shadows.
class _PoliceBarricadePadlock extends StatelessWidget {
  const _PoliceBarricadePadlock();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft neon glow behind the lock.
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ShopComingSoonView._neon.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.45, end: 1, duration: 1800.ms),
          // Barricade tape strip (angled).
          Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 150,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    ShopComingSoonView._tapeYellow,
                    Color(0xFFFFE082),
                    ShopComingSoonView._tapeYellow,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: ShopComingSoonView._tapeYellow
                        .withValues(alpha: 0.25),
                    blurRadius: 16,
                  ),
                ],
                border: Border.all(
                  color: ShopComingSoonView._tapeBlack.withValues(alpha: 0.35),
                ),
              ),
              child: CustomPaint(
                painter: _BarricadeStripePainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // 3D padlock body.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shackle
              Container(
                width: 48,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: const Color(0xFF9AA0B0),
                    width: 8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 2,
                      offset: const Offset(-1, -1),
                    ),
                  ],
                ),
              ),
              // Body
              Container(
                width: 72,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3A4050),
                      Color(0xFF1A1E28),
                      Color(0xFF0E1118),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 14,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: ShopComingSoonView._neon.withValues(alpha: 0.2),
                      blurRadius: 18,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.08),
                      blurRadius: 1,
                      offset: const Offset(-1, -1),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF4A5164),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: ShopComingSoonView._neon,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -8, end: 8, duration: 2200.ms, curve: Curves.easeInOut);
  }
}

class _BarricadeStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ShopComingSoonView._tapeBlack
      ..style = PaintingStyle.fill;

    const stripeWidth = 14.0;
    for (var x = -size.height; x < size.width + size.height; x += stripeWidth * 2) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth + size.height, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
