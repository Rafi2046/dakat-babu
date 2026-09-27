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
    await ref.read(singlePlayerEngineProvider.notifier).pickMysteryCard(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePlayerEngineProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: state.phase == SinglePlayerPhase.result
          // Drop parallax under the result overlay — sensors + layers cause jank.
          ? Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.backgroundDark),
                if (state.resultWinner != null)
                  RoundResultOverlay(
                    winner: state.resultWinner!,
                    headlineOverride: state.statusMessage,
                    nextLabel: 'আবার খেলো',
                    playAudio: false,
                    onNextRound: () {
                      ref
                          .read(singlePlayerEngineProvider.notifier)
                          .playAgain();
                    },
                  ),
              ],
            )
          : ParallaxLobbyBackground(
              child: SafeArea(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(onBack: () => context.pop()),
                      AppSpacing.gapVSm,
                      _StatusBanner(message: state.statusMessage ?? ''),
                      AppSpacing.gapVMd,
                      Expanded(child: _buildPhase(state)),
                    ],
                  ),
                ),
              ),
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
          padding: const EdgeInsets.all(8),
          child: _BotTargetGrid(
            state: state,
            onGuess: (id) => ref
                .read(singlePlayerEngineProvider.notifier)
                .submitHumanGuess(id),
          ),
        );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surfaceElevatedDark.withValues(alpha: 0.85),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.45),
        ),
        boxShadow: AppColors.darkNeonGlow(AppColors.secondary, alpha: 0.22),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: HomeTextStyles.title(color: AppColors.secondary).copyWith(
          shadows: [
            Shadow(
              color: AppColors.secondary.withValues(alpha: 0.75),
              blurRadius: 14,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms);
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
        const gap = 14.0;
        final cardW = ((constraints.maxWidth - gap) / 2).clamp(130.0, 200.0);
        final cardH = ((constraints.maxHeight - gap) / 2).clamp(170.0, 260.0);

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
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: widget.locked
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onTap();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.94 : (widget.selected ? 1.04 : 1),
          duration: const Duration(milliseconds: 140),
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
              ? const [
                  Color(0xFF1A1E28),
                  Color(0xFF0E1118),
                  Color(0xFF080A10),
                ]
              : const [
                  Color(0xFF3A4258),
                  Color(0xFF1F2432),
                  Color(0xFF12161F),
                ],
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
            blurRadius: pressed ? 6 : 16,
            offset: Offset(0, pressed ? 3 : 10),
          ),
          if (highlight)
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.28),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          // Emboss highlight.
          BoxShadow(
            color: Colors.white.withValues(alpha: pressed ? 0.04 : 0.1),
            blurRadius: 0,
            offset: const Offset(-1.5, -1.5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Diagonal sheen.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevatedDark,
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '?',
                  style: HomeTextStyles.hero(color: AppColors.textLightPrimary)
                      .copyWith(fontSize: 40, height: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  'কার্ড ${index + 1}',
                  style: HomeTextStyles.caption(
                    color: AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          Icon(Icons.style_rounded, color: accent, size: 44),
          const SizedBox(height: 12),
          Text(
            role.label,
            style: HomeTextStyles.hero(color: AppColors.textLightPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'তোমার রোল',
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
