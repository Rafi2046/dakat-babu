import 'dart:math' as math;
import 'dart:ui';

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

/// Cinematic round-end overlay: blur, confetti, neon Bangla headline, next CTA.
///
/// [winner] should be [GameRole.police] or [GameRole.chor] (other roles fall
/// back to Chor styling as "escape" energy).
class RoundResultOverlay extends ConsumerStatefulWidget {
  final GameRole winner;
  final VoidCallback onNextRound;
  final String? headlineOverride;
  final String nextLabel;

  const RoundResultOverlay({
    super.key,
    required this.winner,
    required this.onNextRound,
    this.headlineOverride,
    this.nextLabel = 'পরবর্তী রাউন্ড',
  });

  @override
  ConsumerState<RoundResultOverlay> createState() => _RoundResultOverlayState();
}

class _RoundResultOverlayState extends ConsumerState<RoundResultOverlay> {
  late final ConfettiController _topLeftConfetti;
  late final ConfettiController _topRightConfetti;
  late final ConfettiController _centerConfetti;

  bool get _policeWins => widget.winner == GameRole.police;

  Color get _accent =>
      _policeWins ? AppColors.police : AppColors.chor;

  String get _headline {
    if (widget.headlineOverride != null) return widget.headlineOverride!;
    return _policeWins ? 'চোর ধরা পড়েছে!' : 'চোর পালিয়ে গেছে!';
  }

  List<Color> get _policeColors => const [
        Color(0xFF48CAE4),
        Color(0xFF0096C7),
        Color(0xFF023E8A),
        Color(0xFFC0C0C0),
        Color(0xFFFFFFFF),
      ];

  List<Color> get _chorColors => const [
        Color(0xFFE63946),
        Color(0xFF9E0012),
        Color(0xFF1A1A1A),
        Color(0xFFFFB703),
        Color(0xFFFFD166),
      ];

  @override
  void initState() {
    super.initState();
    _topLeftConfetti = ConfettiController(duration: const Duration(seconds: 3));
    _topRightConfetti =
        ConfettiController(duration: const Duration(seconds: 3));
    _centerConfetti = ConfettiController(duration: const Duration(seconds: 2));

    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  Future<void> _celebrate() async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();

    final audio = ref.read(audioManagerProvider);
    await audio.play(
      _policeWins ? AudioEvent.successSting : AudioEvent.failureSting,
    );

    if (!mounted) return;
    if (_policeWins) {
      _topLeftConfetti.play();
      _topRightConfetti.play();
    } else {
      _centerConfetti.play();
    }
  }

  @override
  void dispose() {
    _topLeftConfetti.dispose();
    _topRightConfetti.dispose();
    _centerConfetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dim + blur so the board stays faintly visible underneath.
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),

          if (_policeWins) ...[
            Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _topLeftConfetti,
                blastDirection: math.pi / 4,
                blastDirectionality: BlastDirectionality.directional,
                emissionFrequency: 0.06,
                numberOfParticles: 18,
                maxBlastForce: 28,
                minBlastForce: 12,
                gravity: 0.22,
                colors: _policeColors,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _topRightConfetti,
                blastDirection: 3 * math.pi / 4,
                blastDirectionality: BlastDirectionality.directional,
                emissionFrequency: 0.06,
                numberOfParticles: 18,
                maxBlastForce: 28,
                minBlastForce: 12,
                gravity: 0.22,
                colors: _policeColors,
              ),
            ),
          ] else
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _centerConfetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.12,
                numberOfParticles: 10,
                maxBlastForce: 16,
                minBlastForce: 6,
                gravity: 0.35,
                colors: _chorColors,
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _Headline(
                    text: _headline,
                    accent: _accent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _policeWins ? 'Police wins the round' : 'Chor escapes!',
                    style: HomeTextStyles.subtitle(color: Colors.white70),
                  )
                      .animate()
                      .fadeIn(delay: 280.ms, duration: 400.ms),
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
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.15,
      shadows: [
        Shadow(color: accent.withValues(alpha: 0.95), blurRadius: 18),
        Shadow(color: accent.withValues(alpha: 0.55), blurRadius: 36),
        const Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
      ],
    );

    return Text(
      text,
      textAlign: TextAlign.center,
      style: style,
    )
        .animate()
        .fadeIn(duration: 220.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.55, 0.55),
          end: const Offset(1, 1),
          duration: 520.ms,
          curve: Curves.easeOutBack,
        )
        .rotate(
          begin: -0.06,
          end: 0,
          duration: 520.ms,
          curve: Curves.easeOutCubic,
        )
        .then()
        .shimmer(
          duration: 1200.ms,
          color: accent.withValues(alpha: 0.45),
        );
  }
}
