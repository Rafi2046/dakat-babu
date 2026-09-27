import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/home_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../domain/game/game_role.dart';
import 'tactile_menu_button.dart';

/// One player's round payout for the result overlay.
class RoundScoreChip {
  final String name;
  final GameRole role;
  final int points;

  const RoundScoreChip({
    required this.name,
    required this.role,
    required this.points,
  });
}

/// Round-end overlay with classic point pop chips (+900 / +800 / 0…).
class RoundResultOverlay extends ConsumerStatefulWidget {
  final GameRole winner;
  final VoidCallback onNextRound;
  final String? headlineOverride;
  final String nextLabel;
  final bool playAudio;

  /// Classic per-role payouts this round (ordered for display).
  final List<RoundScoreChip> scoreChips;

  const RoundResultOverlay({
    super.key,
    required this.winner,
    required this.onNextRound,
    this.headlineOverride,
    this.nextLabel = 'পরবর্তী রাউন্ড',
    this.playAudio = true,
    this.scoreChips = const [],
  });

  @override
  ConsumerState<RoundResultOverlay> createState() => _RoundResultOverlayState();
}

class _RoundResultOverlayState extends ConsumerState<RoundResultOverlay> {
  late final ConfettiController _confetti;

  bool get _policeWins => widget.winner == GameRole.police;

  Color get _accent => _policeWins ? AppColors.police : AppColors.chor;

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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _Headline(text: _headline, accent: _accent),
                  const SizedBox(height: 10),
                  Text(
                    _policeWins
                        ? 'Police caught Chor — classic payout'
                        : 'Chor escapes — classic payout',
                    style: HomeTextStyles.subtitle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 160.ms, duration: 280.ms),
                  const SizedBox(height: 22),
                  if (widget.scoreChips.isNotEmpty)
                    _ScoreChipGrid(chips: widget.scoreChips)
                  else
                    const SizedBox.shrink(),
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

class _ScoreChipGrid extends StatelessWidget {
  final List<RoundScoreChip> chips;

  const _ScoreChipGrid({required this.chips});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < chips.length; i++)
          _PopScoreChip(chip: chips[i], index: i),
      ],
    );
  }
}

class _PopScoreChip extends StatelessWidget {
  final RoundScoreChip chip;
  final int index;

  const _PopScoreChip({required this.chip, required this.index});

  @override
  Widget build(BuildContext context) {
    final zero = chip.points <= 0;
    final accent = zero ? AppColors.chor : chip.role.color;
    final label = zero ? '0' : '+${chip.points}';

    Widget body = Container(
      width: 148,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.35),
            const Color(0xFF141821),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.75), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chip.role.label.toUpperCase(),
            style: HomeTextStyles.caption(color: accent).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            chip.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeTextStyles.body(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: HomeTextStyles.hero(color: zero ? AppColors.chor : Colors.white)
                .copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: [
                Shadow(color: accent.withValues(alpha: 0.8), blurRadius: 12),
              ],
            ),
          ),
        ],
      ),
    );

    body = body
        .animate(delay: (90 * index).ms)
        .fadeIn(duration: 220.ms)
        .scale(
          begin: const Offset(0.55, 0.55),
          end: const Offset(1, 1),
          duration: 420.ms,
          curve: Curves.easeOutBack,
        )
        .then(delay: 40.ms)
        .shimmer(
          duration: 700.ms,
          color: Colors.white.withValues(alpha: 0.18),
        );

    if (zero) {
      body = body
          .animate(delay: (90 * index + 280).ms)
          .shake(hz: 6, duration: 320.ms, rotation: 0.04);
    }

    return body;
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
