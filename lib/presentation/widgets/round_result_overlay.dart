import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/home_text_styles.dart';
import '../../domain/game/game_role.dart';
import 'tactile_menu_button.dart';

/// Round-end overlay: dim scrim, light confetti, neon headline, next CTA.
///
/// Kept light for 60fps — no BackdropFilter blur, one confetti emitter.
class RoundResultOverlay extends ConsumerStatefulWidget {
  final GameRole winner;
  final VoidCallback onNextRound;
  final String? headlineOverride;
  final String nextLabel;

  /// When false, skips sting SFX (caller already played result audio).
  final bool playAudio;

  const RoundResultOverlay({
    super.key,
    required this.winner,
    required this.onNextRound,
    this.headlineOverride,
    this.nextLabel = 'পরবর্তী রাউন্ড',
    this.playAudio = true,
  });

  @override
  ConsumerState<RoundResultOverlay> createState() => _RoundResultOverlayState();
}

class _RoundResultOverlayState extends ConsumerState<RoundResultOverlay> {
  late final ConfettiController _confetti;

  bool get _policeWins => widget.winner == GameRole.police;

  Color get _accent =>
      _policeWins ? AppColors.police : AppColors.chor;

  String get _headline {
    if (widget.headlineOverride != null) return widget.headlineOverride!;
    return _policeWins ? 'চোর ধরা পড়েছে!' : 'চোর পালিয়ে গেছে!';
  }

  List<Color> get _colors => _policeWins
      ? const [
          Color(0xFF48CAE4),
          Color(0xFF0096C7),
          Color(0xFFFFFFFF),
        ]
      : const [
          Color(0xFFE63946),
          Color(0xFFFFB703),
          Color(0xFF1A1A1A),
        ];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 1600));
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  Future<void> _celebrate() async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    if (widget.playAudio) {
      await ref.read(audioManagerProvider).play(
            _policeWins ? AudioEvent.successSting : AudioEvent.failureSting,
          );
    }

    if (!mounted) return;
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Solid scrim — BackdropFilter blur was dropping frames hard.
          const ColoredBox(color: Color(0xE60B0E14)),

          Align(
            alignment: _policeWins ? Alignment.topCenter : Alignment.center,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: _policeWins ? math.pi / 2 : 0,
              blastDirectionality: _policeWins
                  ? BlastDirectionality.directional
                  : BlastDirectionality.explosive,
              emissionFrequency: 0.04,
              numberOfParticles: 10,
              maxBlastForce: 18,
              minBlastForce: 8,
              gravity: 0.28,
              shouldLoop: false,
              colors: _colors,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _Headline(text: _headline, accent: _accent),
                  const SizedBox(height: 12),
                  Text(
                    _policeWins ? 'Police wins the round' : 'Chor escapes!',
                    style: HomeTextStyles.subtitle(color: Colors.white70),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const Spacer(flex: 3),
                  TactileMenuButton(
                    text: widget.nextLabel,
                    icon: Icons.arrow_forward_rounded,
                    accentColor: _accent,
                    onTap: widget.onNextRound,
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  final String text;
  final Color accent;

  const _Headline({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    final style = HomeTextStyles.hero(color: Colors.white).copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 1.2,
      shadows: [
        Shadow(color: accent.withValues(alpha: 0.85), blurRadius: 16),
        const Shadow(
          color: Colors.black54,
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    );

    return Text(
      text,
      textAlign: TextAlign.center,
      style: style,
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          duration: 360.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
