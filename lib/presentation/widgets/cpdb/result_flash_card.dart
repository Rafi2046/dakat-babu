import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'game_button.dart';

/// Dramatic correct / wrong flash card with rich animations, sound FX, and confetti in a compact, sleek form.
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            AppColors.surfaceDark,
            const Color(0xFF0D121B),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.75),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Icon + Title + Subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(
                    color: color.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: color,
                  size: 24,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.2, 0.2),
                    end: const Offset(1.15, 1.15),
                    duration: 350.ms,
                    curve: Curves.easeOutBack,
                  )
                  .then(delay: 40.ms)
                  .scale(
                    begin: const Offset(1.15, 1.15),
                    end: const Offset(1.0, 1.0),
                    duration: 120.ms,
                  ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.heading2(color: color).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.7),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 180.ms)
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1, 1),
                          duration: 250.ms,
                          curve: Curves.easeOutBack,
                        ),
                    Text(
                      widget.subtitle,
                      style: AppTextStyles.caption(
                        color: Colors.white.withValues(alpha: 0.85),
                      ).copyWith(fontSize: 11.5, fontWeight: FontWeight.w500),
                    ).animate(delay: 140.ms).fadeIn(duration: 180.ms),
                  ],
                ),
              ),
            ],
          ),

          // Middle content: Character + Score Breakdown pill side-by-side
          if (widget.characterAsset != null || widget.scoreLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.characterAsset != null)
                  Container(
                    width: 48,
                    height: 52,
                    alignment: Alignment.center,
                    child: Image.asset(
                      widget.characterAsset!,
                      height: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        widget.isCorrect ? Icons.local_police : Icons.person,
                        color: color,
                        size: 36,
                      ),
                    )
                        .animate(delay: 180.ms)
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 350.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 200.ms)
                        .then(delay: 300.ms)
                        .shimmer(
                          duration: 1200.ms,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                  ),
                if (widget.characterAsset != null && widget.scoreLabel != null)
                  const SizedBox(width: 8),
                if (widget.scoreLabel != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.28),
                            color.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.isCorrect
                                ? Icons.stars_rounded
                                : Icons.info_outline_rounded,
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.scoreLabel!,
                              style: AppTextStyles.caption(color: Colors.white)
                                  .copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: color.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 240.ms)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 200.ms)
                        .then(delay: 300.ms)
                        .shimmer(
                          duration: 1400.ms,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                  ),
              ],
            ),
          ],

          if (widget.onContinue != null) ...[
            const SizedBox(height: 10),
            GameButton(
              label: widget.continueLabel,
              onPressed: widget.onContinue,
            ),
          ],
        ],
      ),
    );

    // Entry animation
    cardContent = cardContent
        .animate()
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 320.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 200.ms);

    if (!widget.isCorrect) {
      cardContent = cardContent
          .animate(delay: 120.ms)
          .shake(hz: 6, duration: 320.ms, offset: const Offset(5, 0));
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
              numberOfParticles: 14,
              maxBlastForce: 20,
              minBlastForce: 8,
              gravity: 0.3,
              shouldLoop: false,
              colors: _celebrationColors,
            ),
          ),
      ],
    );
  }
}


