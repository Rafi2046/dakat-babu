import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// A custom-drawn illustrated vector icon for each [GameRole].
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
    Color glowColor;
    switch (role) {
      case GameRole.raja:
        glowColor = AppColors.rajaGlow;
        break;
      case GameRole.mantri:
        glowColor = AppColors.mantriGlow;
        break;
      case GameRole.police:
        glowColor = AppColors.policeGlow;
        break;
      case GameRole.chor:
        glowColor = AppColors.chorGlow;
        break;
      case GameRole.chintaykari:
        glowColor = AppColors.chintaykariGlow;
        break;
      case GameRole.batpar:
        glowColor = AppColors.batparGlow;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: hasGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: size * 0.45,
                  spreadRadius: size * 0.05,
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _getPainter(role),
      ),
    );
  }

  CustomPainter _getPainter(GameRole role) {
    switch (role) {
      case GameRole.raja:
        return const _RajaCrownPainter();
      case GameRole.mantri:
        return const _MantriScrollPainter();
      case GameRole.police:
        return const _PoliceShieldPainter();
      case GameRole.chor:
      case GameRole.chintaykari:
      case GameRole.batpar:
        return const _ChorMaskPainter();
    }
  }
}

/// Custom painter for the Raja's 5-peak Royal Crown with jeweled rubies.
class _RajaCrownPainter extends CustomPainter {
  const _RajaCrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Crown body path
    final crownPath = Path()
      ..moveTo(w * 0.12, h * 0.80)
      ..lineTo(w * 0.10, h * 0.38) // Left peak
      ..lineTo(w * 0.30, h * 0.52) // Inner dip
      ..lineTo(w * 0.50, h * 0.22) // Center majestic peak
      ..lineTo(w * 0.70, h * 0.52) // Inner dip
      ..lineTo(w * 0.90, h * 0.38) // Right peak
      ..lineTo(w * 0.88, h * 0.80) // Base right
      ..close();

    final goldGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFEA79), Color(0xFFFFB703), Color(0xFFD48B00)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final crownPaint = Paint()
      ..shader = goldGradient
      ..style = PaintingStyle.fill;

    // Outer glow/shadow
    canvas.drawPath(crownPath, crownPaint);

    // Crown border outline
    final strokePaint = Paint()
      ..color = const Color(0xFFFFF6A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04;
    canvas.drawPath(crownPath, strokePaint);

    // Crown Base Band
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.76, w * 0.80, h * 0.14),
      Radius.circular(w * 0.06),
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFB703), Color(0xFFFFA000), Color(0xFFFFD166)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(baseRect, basePaint);

    // Jewels (Rubies and Emeralds)
    final rubyPaint = Paint()..color = const Color(0xFFE63946);
    final gemHighlight = Paint()..color = Colors.white;

    // Center peak jewel
    canvas.drawCircle(Offset(w * 0.50, h * 0.24), w * 0.06, rubyPaint);
    canvas.drawCircle(Offset(w * 0.48, h * 0.22), w * 0.02, gemHighlight);

    // Left peak jewel
    canvas.drawCircle(Offset(w * 0.10, h * 0.39), w * 0.045, rubyPaint);
    // Right peak jewel
    canvas.drawCircle(Offset(w * 0.90, h * 0.39), w * 0.045, rubyPaint);

    // Base band gems
    final emeraldPaint = Paint()..color = const Color(0xFF06D6A0);
    canvas.drawCircle(Offset(w * 0.30, h * 0.83), w * 0.035, rubyPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.83), w * 0.045, emeraldPaint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.83), w * 0.035, rubyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the Mantri's Ancient Decree Parchment Scroll & Royal Seal.
class _MantriScrollPainter extends CustomPainter {
  const _MantriScrollPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Parchment Scroll body
    final scrollPath = Path()
      ..moveTo(w * 0.22, h * 0.16)
      ..cubicTo(w * 0.40, h * 0.12, w * 0.60, h * 0.20, w * 0.78, h * 0.16)
      ..lineTo(w * 0.82, h * 0.78)
      ..cubicTo(w * 0.60, h * 0.74, w * 0.40, h * 0.82, w * 0.20, h * 0.78)
      ..close();

    final parchmentGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8D5FF), Color(0xFFC77DFF), Color(0xFF9D4EDD)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final scrollPaint = Paint()..shader = parchmentGradient;
    canvas.drawPath(scrollPath, scrollPaint);

    // Golden Outline
    final strokePaint = Paint()
      ..color = const Color(0xFFE0AAFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;
    canvas.drawPath(scrollPath, strokePaint);

    // Top & Bottom Scroll Rollers
    final rollerPaint = Paint()..color = const Color(0xFFFFD166);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.11, w * 0.68, h * 0.08),
        Radius.circular(w * 0.04),
      ),
      rollerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.76, w * 0.68, h * 0.08),
        Radius.circular(w * 0.04),
      ),
      rollerPaint,
    );

    // Decree Script Lines
    final scriptPaint = Paint()
      ..color = const Color(0x77FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.025;

    canvas.drawLine(Offset(w * 0.32, h * 0.30), Offset(w * 0.68, h * 0.30), scriptPaint);
    canvas.drawLine(Offset(w * 0.32, h * 0.40), Offset(w * 0.62, h * 0.40), scriptPaint);
    canvas.drawLine(Offset(w * 0.32, h * 0.50), Offset(w * 0.54, h * 0.50), scriptPaint);

    // Royal Crimson Wax Seal
    final sealPaint = Paint()..color = const Color(0xFFE63946);
    canvas.drawCircle(Offset(w * 0.64, h * 0.62), w * 0.12, sealPaint);

    // Seal emblem star
    final sealStarPaint = Paint()..color = const Color(0xFFFFD166);
    canvas.drawCircle(Offset(w * 0.64, h * 0.62), w * 0.06, sealStarPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the Police's Tactical Star-Shield Law Enforcement Badge.
class _PoliceShieldPainter extends CustomPainter {
  const _PoliceShieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shield Path
    final shieldPath = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.88, h * 0.22)
      ..cubicTo(w * 0.88, h * 0.58, w * 0.68, h * 0.82, w * 0.50, h * 0.92)
      ..cubicTo(w * 0.32, h * 0.82, w * 0.12, h * 0.58, w * 0.12, h * 0.22)
      ..close();

    final shieldGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF00B4D8), Color(0xFF0077B6), Color(0xFF023E8A)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final shieldPaint = Paint()..shader = shieldGradient;
    canvas.drawPath(shieldPath, shieldPaint);

    // Metallic Shield Rim
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFCAF0F8), Color(0xFF90E0EF), Color(0xFF0096C7)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05;
    canvas.drawPath(shieldPath, rimPaint);

    // Central 5-pointed Sheriff Badge Star
    _drawStar(canvas, Offset(w * 0.50, h * 0.48), 5, w * 0.20, w * 0.09);
  }

  void _drawStar(Canvas canvas, Offset center, int points, double outerR, double innerR) {
    final path = Path();
    var angle = -math.pi / 2;
    final step = math.pi / points;

    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += step;
    }
    path.close();

    final starPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEA79), Color(0xFFFFB703)],
      ).createShader(Rect.fromCircle(center: center, radius: outerR));
    canvas.drawPath(path, starPaint);

    final starRim = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, starRim);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the Chor's Sleek Midnight Bandit Domino Mask.
class _ChorMaskPainter extends CustomPainter {
  const _ChorMaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bandit Mask Outline
    final maskPath = Path()
      ..moveTo(w * 0.50, h * 0.42) // Nose bridge center dip
      ..cubicTo(w * 0.40, h * 0.22, w * 0.16, h * 0.22, w * 0.06, h * 0.38) // Top-left arch
      ..cubicTo(w * 0.02, h * 0.54, w * 0.12, h * 0.74, w * 0.34, h * 0.76) // Bottom-left sweep
      ..cubicTo(w * 0.44, h * 0.76, w * 0.48, h * 0.60, w * 0.50, h * 0.58) // Bottom nose bridge
      ..cubicTo(w * 0.52, h * 0.60, w * 0.56, h * 0.76, w * 0.66, h * 0.76) // Bottom-right sweep
      ..cubicTo(w * 0.88, h * 0.74, w * 0.98, h * 0.54, w * 0.94, h * 0.38) // Top-right arch
      ..cubicTo(w * 0.84, h * 0.22, w * 0.60, h * 0.22, w * 0.50, h * 0.42) // Return to nose bridge
      ..close();

    final maskGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF5D73), Color(0xFFE63946), Color(0xFF800F2F)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final maskPaint = Paint()..shader = maskGradient;
    canvas.drawPath(maskPath, maskPaint);

    // Mask outline
    final strokePaint = Paint()
      ..color = const Color(0xFFFFB3C1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;
    canvas.drawPath(maskPath, strokePaint);

    // Left Eye cutout
    final leftEye = Path()
      ..moveTo(w * 0.20, h * 0.48)
      ..cubicTo(w * 0.24, h * 0.38, w * 0.36, h * 0.40, w * 0.38, h * 0.52)
      ..cubicTo(w * 0.36, h * 0.60, w * 0.24, h * 0.58, w * 0.20, h * 0.48)
      ..close();

    // Right Eye cutout
    final rightEye = Path()
      ..moveTo(w * 0.80, h * 0.48)
      ..cubicTo(w * 0.76, h * 0.38, w * 0.64, h * 0.40, w * 0.62, h * 0.52)
      ..cubicTo(w * 0.64, h * 0.60, w * 0.76, h * 0.58, w * 0.80, h * 0.48)
      ..close();

    final eyePaint = Paint()..color = const Color(0xFF0F111A);
    canvas.drawPath(leftEye, eyePaint);
    canvas.drawPath(rightEye, eyePaint);

    // Starlight Sneaky Glint in corner of right eye
    final glintPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.68, h * 0.46), w * 0.03, glintPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.46), w * 0.03, glintPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom illustrated background watermark texture painter for role cards.
class RolePatternPainter extends CustomPainter {
  final GameRole role;

  const RolePatternPainter({required this.role});

  @override
  void paint(Canvas canvas, Size size) {
    switch (role) {
      case GameRole.raja:
        _drawRoyalLattice(canvas, size);
        break;
      case GameRole.mantri:
        _drawMandalaSeal(canvas, size);
        break;
      case GameRole.police:
        _drawPoliceSecurityGrid(canvas, size);
        break;
      case GameRole.chor:
      case GameRole.chintaykari:
      case GameRole.batpar:
        _drawStealthCrosshatch(canvas, size);
        break;
    }
  }

  void _drawRoyalLattice(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.raja.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 24.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  void _drawMandalaSeal(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mantri.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width * 0.85, size.height * 0.5);
    for (var r = 16.0; r < size.width * 0.7; r += 20.0) {
      canvas.drawCircle(center, r, paint);
    }
  }

  void _drawPoliceSecurityGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.police.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const step = 20.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 10), paint);
    }
  }

  void _drawStealthCrosshatch(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.chor.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const gap = 16.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x - 30, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
