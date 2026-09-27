import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/home_text_styles.dart';
import '../../../domain/game/game_role.dart';
import '../../viewmodels/single_player_engine.dart';
import '../../widgets/parallax_lobby_background.dart';
import '../../widgets/round_result_overlay.dart';
import '../../widgets/tactile_3d_flip_card.dart';
import '../../widgets/target_selection_glow.dart';

/// Classic Vs Computer — face-down mystery cards, random role draw.
class ClassicSinglePlayerScreen extends ConsumerStatefulWidget {
  final String humanName;

  const ClassicSinglePlayerScreen({super.key, this.humanName = 'You'});

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
      ref
          .read(singlePlayerEngineProvider.notifier)
          .startMatch(humanName: widget.humanName);
    });
  }

  Future<void> _onMysteryTap(int index) async {
    final state = ref.read(singlePlayerEngineProvider);
    if (state.phase != SinglePlayerPhase.pickCard || state.busy) return;

    HapticFeedback.heavyImpact();
    await ref
        .read(singlePlayerEngineProvider.notifier)
        .pickMysteryCard(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePlayerEngineProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: ParallaxLobbyBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(onBack: () => context.pop()),
                    AppSpacing.gapVMd,
                    _StatusBanner(message: state.statusMessage ?? ''),
                    AppSpacing.gapVLg,
                    Expanded(child: _buildPhase(state)),
                  ],
                ),
              ),
            ),
            if (state.phase == SinglePlayerPhase.result &&
                state.resultWinner != null)
              RoundResultOverlay(
                winner: state.resultWinner!,
                headlineOverride: state.statusMessage,
                nextLabel: 'আবার খেলো',
                onNextRound: () {
                  ref.read(singlePlayerEngineProvider.notifier).playAgain();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase(SinglePlayerState state) {
    switch (state.phase) {
      case SinglePlayerPhase.pickCard:
      case SinglePlayerPhase.revealing:
        return _MysteryCardGrid(
          state: state,
          onTap: _onMysteryTap,
        );
      case SinglePlayerPhase.policeSearching:
        return _PoliceSearchingView(message: state.statusMessage ?? '');
      case SinglePlayerPhase.awaitingGuess:
        return TargetSelectionGlow(
          isActive: true,
          padding: const EdgeInsets.all(8),
          child: _BotTargetGrid(
            state: state,
            onGuess: (id) => ref
                .read(singlePlayerEngineProvider.notifier)
                .submitHumanGuess(id),
          ),
        );
      case SinglePlayerPhase.pickRole:
        // Should not appear on classic screen — show mystery grid fallback.
        return _MysteryCardGrid(state: state, onTap: _onMysteryTap);
      case SinglePlayerPhase.result:
        return const SizedBox.shrink();
    }
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 48),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;

  const _StatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: HomeTextStyles.title(color: AppColors.secondary).copyWith(
        shadows: [
          Shadow(
            color: AppColors.secondary.withValues(alpha: 0.75),
            blurRadius: 16,
          ),
          Shadow(
            color: AppColors.secondary.withValues(alpha: 0.35),
            blurRadius: 28,
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.7, end: 1, duration: 1400.ms);
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
        final cardW = (constraints.maxWidth - 14) / 2;
        final cardH = (constraints.maxHeight - 14) / 2;
        final w = cardW.clamp(120.0, 180.0);
        final h = cardH.clamp(160.0, 240.0);

        return Center(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                _MysterySlot(
                  index: i,
                  width: w,
                  height: h,
                  selected: state.selectedCardIndex == i,
                  locked: locked,
                  revealedRole: state.selectedCardIndex == i
                      ? state.humanRole
                      : null,
                  isRevealed: state.selectedCardIndex == i &&
                      state.humanRole != null,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MysterySlot extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dimmed = locked && !selected;

    return Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : onTap,
        child: Tactile3DFlipCard(
          key: ValueKey('mystery_$index'),
          width: width,
          height: height,
          role: revealedRole,
          isRevealed: isRevealed,
          playFlipSound: false,
          enableTap: false,
          backFace: _MysteryBack(index: index),
        ),
      ),
    );
  }
}

class _MysteryBack extends StatelessWidget {
  final int index;

  const _MysteryBack({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A3144),
            Color(0xFF151922),
            Color(0xFF0B0E14),
          ],
        ),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.45),
          width: 2,
        ),
        boxShadow: AppColors.darkNeonGlow(AppColors.secondary, alpha: 0.25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline_rounded,
            size: 40,
            color: AppColors.secondary.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 8),
          Text(
            '?',
            style: HomeTextStyles.hero(color: AppColors.textLightPrimary)
                .copyWith(fontSize: 36),
          ),
          Text(
            'কার্ড ${index + 1}',
            style: HomeTextStyles.caption(color: AppColors.textLightSecondary),
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
          const Icon(
            Icons.local_police_rounded,
            size: 64,
            color: AppColors.police,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1.08, 1.08),
                duration: 900.ms,
              ),
          AppSpacing.gapVLg,
          Text(
            message.isEmpty ? 'পুলিশ চোর খুঁজছে...' : message,
            textAlign: TextAlign.center,
            style: HomeTextStyles.hero(color: AppColors.police).copyWith(
              shadows: [
                Shadow(
                  color: AppColors.police.withValues(alpha: 0.7),
                  blurRadius: 18,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 1600.ms,
                color: Colors.white.withValues(alpha: 0.55),
              )
              .fade(begin: 0.65, end: 1, duration: 1200.ms),
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
          'কাদের উপর সন্দেহ? (চোর খুঁজো)',
          textAlign: TextAlign.center,
          style: HomeTextStyles.title(color: AppColors.textLightPrimary),
        ),
        AppSpacing.gapVMd,
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
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.surfaceElevatedDark,
                      border: Border.all(
                        color: AppColors.police.withValues(alpha: 0.55),
                        width: 1.6,
                      ),
                      boxShadow: AppColors.darkNeonGlow(
                        AppColors.police,
                        alpha: 0.22,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.person_search_rounded,
                          color: AppColors.police,
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
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textLightMuted,
                        ),
                        const SizedBox(width: 12),
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
