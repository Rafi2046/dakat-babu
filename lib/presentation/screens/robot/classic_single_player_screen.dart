import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/home_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/game/game_role.dart';
import '../../../domain/game/player_view.dart';
import '../../viewmodels/single_player_engine.dart';
import '../../widgets/round_result_overlay.dart';
import '../../widgets/tactile_3d_flip_card.dart';
import '../../widgets/target_selection_glow.dart';

/// Classic Vs Computer arena — mystery draw, accusation, live scoreboard.
class ClassicSinglePlayerScreen extends ConsumerStatefulWidget {
  final String humanName;
  final int totalRounds;

  const ClassicSinglePlayerScreen({
    super.key,
    this.humanName = 'You',
    this.totalRounds = 5,
  });

  @override
  ConsumerState<ClassicSinglePlayerScreen> createState() =>
      _ClassicSinglePlayerScreenState();
}

class _ClassicSinglePlayerScreenState
    extends ConsumerState<ClassicSinglePlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(singlePlayerEngineProvider.notifier).startMatch(
            humanName: widget.humanName,
            totalRounds: widget.totalRounds,
          );
    });
  }

  Future<void> _onMysteryTap(int index) async {
    final state = ref.read(singlePlayerEngineProvider);
    if (state.phase != SinglePlayerPhase.pickCard || state.busy) return;
    await ref.read(singlePlayerEngineProvider.notifier).pickMysteryCard(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePlayerEngineProvider);
    final showOverlay = state.phase == SinglePlayerPhase.result ||
        state.phase == SinglePlayerPhase.matchOver;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Static arena bg — parallax was causing NaN jank + “stuck” feel.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.darkBackgroundGradient,
            ),
          ),
          if (!showOverlay)
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: AppSpacing.screenPadding.copyWith(bottom: 0),
                    child: Column(
                      children: [
                        _ArenaHeader(
                          onBack: () => context.pop(),
                          round: state.currentRound,
                          totalRounds: state.totalRounds,
                          stage: state.stageLabel,
                        ),
                        AppSpacing.gapVSm,
                        if (state.humanRole != null &&
                            state.phase != SinglePlayerPhase.pickCard)
                          _IdentityStrip(
                            role: state.humanRole!,
                            isPolice: state.humanIsPolice,
                          ),
                        AppSpacing.gapVSm,
                        _StageBanner(message: state.statusMessage ?? ''),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildPhase(state),
                    ),
                  ),
                  _LiveScoreboard(state: state),
                ],
              ),
            ),
          if (state.phase == SinglePlayerPhase.result &&
              state.resultWinner != null)
            RoundResultOverlay(
              winner: state.resultWinner!,
              headlineOverride: state.statusMessage,
              nextLabel:
                  state.isLastRound ? 'ম্যাচ শেষ দেখো' : 'পরবর্তী রাউন্ড',
              playAudio: false,
              onNextRound: () {
                ref
                    .read(singlePlayerEngineProvider.notifier)
                    .continueAfterResult();
              },
            ),
          if (state.phase == SinglePlayerPhase.matchOver)
            _MatchOverOverlay(
              state: state,
              onPlayAgain: () {
                ref.read(singlePlayerEngineProvider.notifier).playAgain();
              },
              onExit: () => context.pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildPhase(SinglePlayerState state) {
    switch (state.phase) {
      case SinglePlayerPhase.pickCard:
      case SinglePlayerPhase.revealing:
      case SinglePlayerPhase.pickRole:
        return _MysteryCardGrid(state: state, onTap: _onMysteryTap);
      case SinglePlayerPhase.policeSearching:
        return _PoliceSearchingView(message: state.statusMessage ?? '');
      case SinglePlayerPhase.awaitingGuess:
        return TargetSelectionGlow(
          isActive: true,
          padding: const EdgeInsets.all(4),
          child: _BotTargetGrid(
            state: state,
            onGuess: (id) => ref
                .read(singlePlayerEngineProvider.notifier)
                .submitHumanGuess(id),
          ),
        );
      case SinglePlayerPhase.result:
      case SinglePlayerPhase.matchOver:
        return const SizedBox.shrink();
    }
  }
}

class _ArenaHeader extends StatelessWidget {
  final VoidCallback onBack;
  final int round;
  final int totalRounds;
  final String stage;

  const _ArenaHeader({
    required this.onBack,
    required this.round,
    required this.totalRounds,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textLightPrimary,
            ),
            Expanded(
              child: Text(
                'Vs Computer',
                textAlign: TextAlign.center,
                style: HomeTextStyles.hero(color: AppColors.textLightPrimary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.homeOnline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.homeOnline),
              ),
              child: Text(
                'BOT',
                style: HomeTextStyles.caption(color: AppColors.homeOnline),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _Pill(
              label: 'ROUND $round / $totalRounds',
              color: AppColors.chor,
            ),
            const Spacer(),
            Text(
              'Stage: $stage',
              style: HomeTextStyles.caption(color: AppColors.textLightSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: HomeTextStyles.caption(color: color).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IdentityStrip extends StatelessWidget {
  final GameRole role;
  final bool isPolice;

  const _IdentityStrip({required this.role, required this.isPolice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surfaceElevatedDark,
        border: Border.all(color: role.color.withValues(alpha: 0.55)),
        boxShadow: AppColors.darkNeonGlow(role.color, alpha: 0.18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: role.color.withValues(alpha: 0.25),
            child: Icon(Icons.person, size: 18, color: role.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'YOUR IDENTITY: ${role.label}',
              style: HomeTextStyles.body(color: AppColors.textLightPrimary),
            ),
          ),
          if (isPolice)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.police.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Catch Chor!',
                style: HomeTextStyles.caption(color: AppColors.police),
              ),
            ),
        ],
      ),
    );
  }
}

class _StageBanner extends StatelessWidget {
  final String message;

  const _StageBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surfaceElevatedDark.withValues(alpha: 0.9),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: HomeTextStyles.body(color: AppColors.secondary),
      ),
    );
  }
}

/// Always-visible live scoreboard (arena footer).
class _LiveScoreboard extends StatelessWidget {
  final SinglePlayerState state;

  const _LiveScoreboard({required this.state});

  @override
  Widget build(BuildContext context) {
    final ranked = state.rankedPlayers;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.9)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE SCOREBOARD',
                    style: HomeTextStyles.caption(color: AppColors.accent)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Police +1 · Wrong → suspect +1',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeTextStyles.caption(
                        color: AppColors.textLightMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < ranked.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _ScoreRow(
                    rank: i + 1,
                    player: ranked[i],
                    isYou: ranked[i].id == state.humanId,
                    role: state.roleOf(ranked[i].id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int rank;
  final EnginePlayer player;
  final bool isYou;
  final GameRole? role;

  const _ScoreRow({
    required this.rank,
    required this.player,
    required this.isYou,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final badge = role?.label ?? (isYou ? 'You' : 'Bot');
    final badgeColor = role?.color ?? AppColors.textLightMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '#$rank',
              style: HomeTextStyles.caption(color: AppColors.textLightMuted),
            ),
          ),
          Expanded(
            child: Text(
              isYou ? '${player.name} (You)' : player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeTextStyles.body(
                color:
                    isYou ? AppColors.secondary : AppColors.textLightPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeTextStyles.caption(color: badgeColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${player.score} pts',
            style: HomeTextStyles.body(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _MatchOverOverlay extends StatelessWidget {
  final SinglePlayerState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _MatchOverOverlay({
    required this.state,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final leader = state.rankedPlayers.first;
    return Material(
      color: const Color(0xE60B0E14),
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const Spacer(),
              Text(
                'ম্যাচ শেষ!',
                style: HomeTextStyles.hero(color: AppColors.accent).copyWith(
                  fontSize: 34,
                  shadows: [
                    Shadow(
                      color: AppColors.accent.withValues(alpha: 0.7),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVMd,
              Text(
                'বিজয়ী: ${leader.name} · ${leader.score} pts',
                style: HomeTextStyles.title(color: AppColors.textLightPrimary),
              ),
              AppSpacing.gapVLg,
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _LiveScoreboard(state: state),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPlayAgain,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'আবার খেলো',
                    style: HomeTextStyles.body(color: AppColors.backgroundDark),
                  ),
                ),
              ),
              AppSpacing.gapVSm,
              TextButton(
                onPressed: onExit,
                child: Text(
                  'মেনুতে ফিরে যাও',
                  style: HomeTextStyles.body(color: AppColors.textLightSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MysteryCardGrid extends StatelessWidget {
  final SinglePlayerState state;
  final ValueChanged<int> onTap;

  const _MysteryCardGrid({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = state.selectedCardIndex != null ||
        state.phase == SinglePlayerPhase.revealing;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final maxH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 360.0;
        // Avoid min sizes that overflow the arena and clip taps.
        final cardW = ((maxW - gap) / 2).clamp(96.0, 180.0);
        final cardH = ((maxH - gap) / 2).clamp(110.0, 220.0);

        return Center(
          child: SizedBox(
            width: cardW * 2 + gap,
            height: cardH * 2 + gap,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
                childAspectRatio: cardW / cardH,
              ),
              itemBuilder: (context, i) {
                return _MysterySlot(
                  index: i,
                  width: cardW,
                  height: cardH,
                  selected: state.selectedCardIndex == i,
                  locked: locked,
                  revealedRole: state.selectedCardIndex == i
                      ? state.humanRole
                      : null,
                  isRevealed: state.selectedCardIndex == i &&
                      state.humanRole != null,
                  onTap: () => onTap(i),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MysterySlot extends StatefulWidget {
  final int index;
  final double width;
  final double height;
  final bool selected;
  final bool locked;
  final GameRole? revealedRole;
  final bool isRevealed;
  final VoidCallback onTap;

  const _MysterySlot({
    required this.index,
    required this.width,
    required this.height,
    required this.selected,
    required this.locked,
    required this.revealedRole,
    required this.isRevealed,
    required this.onTap,
  });

  @override
  State<_MysterySlot> createState() => _MysterySlotState();
}

class _MysterySlotState extends State<_MysterySlot> {
  bool _pressed = false;
  bool _tapped = false;

  @override
  void didUpdateWidget(covariant _MysterySlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locked && !widget.selected && _tapped) {
      _tapped = false;
    }
  }

  void _handleTap() {
    if (widget.locked || _tapped) return;
    setState(() {
      _tapped = true;
      _pressed = false;
    });
    HapticFeedback.heavyImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final dimmed = widget.locked && !widget.selected;
    final accent = widget.revealedRole?.color ?? AppColors.secondary;

    return Opacity(
      opacity: dimmed ? 0.32 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.locked
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: () {
          if (_pressed) setState(() => _pressed = false);
        },
        onTap: widget.locked ? null : _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : (widget.selected ? 1.03 : 1),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Tactile3DFlipCard(
            key: ValueKey('mystery_${widget.index}'),
            width: widget.width,
            height: widget.height,
            role: widget.revealedRole,
            isRevealed: widget.isRevealed,
            playFlipSound: false,
            enableTap: false,
            duration: const Duration(milliseconds: 650),
            backFace: _MysteryBack(
              index: widget.index,
              pressed: _pressed,
              highlight: !widget.locked,
            ),
            frontFace: widget.revealedRole == null
                ? null
                : _RoleFront(role: widget.revealedRole!, accent: accent),
          ),
        ),
      ),
    );
  }
}

class _MysteryBack extends StatelessWidget {
  final int index;
  final bool pressed;
  final bool highlight;

  const _MysteryBack({
    required this.index,
    required this.pressed,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pressed
              ? const [Color(0xFF1A1E28), Color(0xFF0E1118), Color(0xFF080A10)]
              : const [Color(0xFF3A4258), Color(0xFF1F2432), Color(0xFF12161F)],
        ),
        border: Border.all(
          color: highlight
              ? AppColors.secondary.withValues(alpha: pressed ? 0.75 : 0.55)
              : AppColors.borderDark,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: pressed ? 6 : 14,
            offset: Offset(0, pressed ? 3 : 8),
          ),
          if (highlight)
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.25),
              blurRadius: 14,
            ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline_rounded,
                color: AppColors.secondary.withValues(alpha: 0.9), size: 28),
            const SizedBox(height: 6),
            Text(
              '?',
              style: HomeTextStyles.hero(color: AppColors.textLightPrimary)
                  .copyWith(fontSize: 34),
            ),
            Text(
              'কার্ড ${index + 1}',
              style: HomeTextStyles.caption(color: AppColors.textLightSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleFront extends StatelessWidget {
  final GameRole role;
  final Color accent;

  const _RoleFront({required this.role, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, Colors.black, 0.35)!,
            AppColors.surfaceElevatedDark,
            AppColors.backgroundDark,
          ],
        ),
        border: Border.all(color: accent, width: 2.2),
        boxShadow: AppColors.darkNeonGlow(accent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_rounded, color: accent, size: 40),
          const SizedBox(height: 8),
          Text(
            role.label,
            style: HomeTextStyles.hero(color: AppColors.textLightPrimary),
          ),
        ],
      ),
    );
  }
}

class _PoliceSearchingView extends StatelessWidget {
  final String message;

  const _PoliceSearchingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_police_rounded,
                  size: 56, color: AppColors.police)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1.06, 1.06),
                duration: 900.ms,
              ),
          AppSpacing.gapVMd,
          Text(
            message.isEmpty ? 'পুলিশ চোর খুঁজছে...' : message,
            textAlign: TextAlign.center,
            style: HomeTextStyles.title(color: AppColors.police),
          ),
        ],
      ),
    );
  }
}

class _BotTargetGrid extends StatelessWidget {
  final SinglePlayerState state;
  final ValueChanged<String> onGuess;

  const _BotTargetGrid({required this.state, required this.onGuess});

  @override
  Widget build(BuildContext context) {
    final bots = state.players.where((p) => p.id != state.humanId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tap Suspect to Accuse as Chor',
          textAlign: TextAlign.center,
          style: HomeTextStyles.title(color: AppColors.textLightPrimary),
        ),
        AppSpacing.gapVSm,
        Expanded(
          child: ListView.separated(
            itemCount: bots.length,
            separatorBuilder: (_, _) => AppSpacing.gapVSm,
            itemBuilder: (context, i) {
              final bot = bots[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: state.busy ? null : () => onGuess(bot.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surfaceElevatedDark,
                      border: Border.all(
                        color: AppColors.police.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.police.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'SUSPECT ${String.fromCharCode(65 + i)}',
                            style: HomeTextStyles.caption(
                              color: AppColors.police,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bot.name,
                            style: HomeTextStyles.body(
                              color: AppColors.textLightPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'ACCUSE',
                          style: HomeTextStyles.caption(color: AppColors.chor),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
