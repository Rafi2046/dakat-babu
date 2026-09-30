import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import 'game_button.dart';

/// Dramatic correct / wrong flash overlay card with rich animations, sound FX, and confetti.
class ResultFlashCard extends ConsumerStatefulWidget {
  final bool isCorrect;
  final String title;
  final String subtitle;
  final String? scoreLabel;
  final String? characterAsset;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool playAudio;

  const ResultFlashCard({
    super.key,
    required this.isCorrect,
    required this.title,
    required this.subtitle,
    this.scoreLabel,
    this.characterAsset,
    this.onContinue,
    this.continueLabel = 'CONTINUE',
    this.playAudio = true,
  });

  @override
  ConsumerState<ResultFlashCard> createState() => _ResultFlashCardState();
}

class _ResultFlashCardState extends ConsumerState<ResultFlashCard> {
  late final ConfettiController _confettiController;

  static const List<Color> _celebrationColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFF00E676), // Bright green
    Color(0xFF00E5FF), // Cyan
    Color(0xFF7C4DFF), // Purple
    Color(0xFFFFFFFF), // White
    Color(0xFFFF3D00), // Coral
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  Future<void> _celebrate() async {
    if (!mounted) return;

    if (widget.isCorrect) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    if (widget.playAudio) {
      final audio = ref.read(audioManagerProvider);
      await audio.play(
        widget.isCorrect ? AudioEvent.correctGuess : AudioEvent.wrongGuess,
      );
      if (widget.isCorrect) {
        await Future<void>.delayed(const Duration(milliseconds: 140));
        if (mounted) {
          await audio.play(AudioEvent.policeTag);
        }
      }
    }

    if (!mounted) return;
    if (widget.isCorrect) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isCorrect ? AppColors.success : AppColors.error;

    Widget cardContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            AppColors.surfaceDark,
            const Color(0xFF0E131E),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: color.withValues(alpha: 0.85),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 32,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon badge with glowing background and dynamic pop animation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(
                color: color.withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              widget.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 44,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.2, 0.2),
                end: const Offset(1.15, 1.15),
                duration: 380.ms,
                curve: Curves.easeOutBack,
              )
              .then(delay: 50.ms)
              .scale(
                begin: const Offset(1.15, 1.15),
                end: const Offset(1.0, 1.0),
                duration: 150.ms,
              )
              .rotate(
                begin: widget.isCorrect ? -0.15 : 0.15,
                end: 0,
                duration: 350.ms,
                curve: Curves.easeOutBack,
              ),
          AppSpacing.gapVSm,

          // Main Title
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1(color: color).copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 18,
                ),
                const Shadow(
                  color: Colors.black87,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          )
              .animate(delay: 100.ms)
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                duration: 320.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 200.ms),
          AppSpacing.gapVSm,

          // Subtitle
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(color: Colors.white.withValues(alpha: 0.9)).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 220.ms),

          // Character animation
          if (widget.characterAsset != null) ...[
            AppSpacing.gapVSm,
            Image.asset(
              widget.characterAsset!,
              height: 108,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                widget.isCorrect ? Icons.local_police : Icons.person,
                color: color,
                size: 72,
              ),
            )
                .animate(delay: 200.ms)
                .slideY(
                  begin: 0.35,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 250.ms)
                .then(delay: 400.ms)
                .shimmer(
                  duration: 1200.ms,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
          ],

          // Score payout pill banner with glowing effect and shimmer
          if (widget.scoreLabel != null) ...[
            AppSpacing.gapVSm,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.35),
                    color.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.65),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isCorrect ? Icons.stars_rounded : Icons.info_outline_rounded,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.scoreLabel!,
                      style: AppTextStyles.heading3(color: Colors.white).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 280.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1, 1),
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 250.ms)
                .then(delay: 350.ms)
                .shimmer(
                  duration: 1400.ms,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
          ],

          if (widget.onContinue != null) ...[
            AppSpacing.gapVLg,
            GameButton(label: widget.continueLabel, onPressed: widget.onContinue)
                .animate(delay: 400.ms)
                .fadeIn(duration: 250.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
          ],
        ],
      ),
    );

    // Apply entry bounce/shake animation
    cardContent = cardContent
        .animate()
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          duration: 380.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 220.ms);

    if (!widget.isCorrect) {
      cardContent = cardContent
          .animate(delay: 150.ms)
          .shake(hz: 6, duration: 360.ms, offset: const Offset(6, 0));
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        cardContent,
        if (widget.isCorrect)
          Positioned(
            top: -10,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 16,
              maxBlastForce: 24,
              minBlastForce: 10,
              gravity: 0.3,
              shouldLoop: false,
              colors: _celebrationColors,
            ),
          ),
      ],
    );
  }
}

