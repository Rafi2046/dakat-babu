import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/home_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/game/game_role.dart';
import '../../viewmodels/single_player_engine.dart';
import '../../widgets/parallax_lobby_background.dart';
import '../../widgets/tactile_menu_button.dart';

/// Offline Vs Computer UI driven by [singlePlayerEngineProvider].
class SinglePlayerScreen extends ConsumerStatefulWidget {
  final String humanName;

  const SinglePlayerScreen({super.key, this.humanName = 'You'});

  @override
  ConsumerState<SinglePlayerScreen> createState() => _SinglePlayerScreenState();
}

class _SinglePlayerScreenState extends ConsumerState<SinglePlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(singlePlayerEngineProvider.notifier)
          .startMatch(humanName: widget.humanName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePlayerEngineProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: ParallaxLobbyBackground(
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textLightPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'Vs Computer',
                        textAlign: TextAlign.center,
                        style: HomeTextStyles.hero(
                          color: AppColors.textLightPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                AppSpacing.gapVMd,
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.embossedPanel(
                    brightness,
                    accent: AppColors.secondary,
                  ),
                  child: Text(
                    state.statusMessage ?? '',
                    textAlign: TextAlign.center,
                    style: HomeTextStyles.body(color: AppColors.secondary),
                  ),
                ),
                AppSpacing.gapVLg,
                Expanded(child: _buildBody(state)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SinglePlayerState state) {
    switch (state.phase) {
      case SinglePlayerPhase.pickRole:
        return _RolePicker(
          enabled: !state.busy,
          onPick: (role) =>
              ref.read(singlePlayerEngineProvider.notifier).selectHumanRole(role),
        );
      case SinglePlayerPhase.botsThinking:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.secondary),
              AppSpacing.gapVMd,
              Text(
                'বটরা চিন্তা করছে...',
                style: HomeTextStyles.title(color: AppColors.textLightPrimary),
              ),
            ],
          ),
        );
      case SinglePlayerPhase.awaitingGuess:
        if (state.humanIsPolice && state.view != null) {
          return _SuspectGrid(
            state: state,
            onGuess: (id) => ref
                .read(singlePlayerEngineProvider.notifier)
                .submitHumanGuess(id),
          );
        }
        return Center(
          child: Text(
            'Police bot is choosing...',
            style: HomeTextStyles.title(color: AppColors.textLightSecondary),
          ),
        );
      case SinglePlayerPhase.result:
        return _ResultPane(
          state: state,
          onAgain: () =>
              ref.read(singlePlayerEngineProvider.notifier).playAgain(),
        );
    }
  }
}

class _RolePicker extends StatelessWidget {
  final bool enabled;
  final ValueChanged<GameRole> onPick;

  const _RolePicker({required this.enabled, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        for (final role in GameRole.values)
          _RoleCard(
            role: role,
            enabled: enabled,
            onTap: () => onPick(role),
          ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final GameRole role;
  final bool enabled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.enabled,
    required this.onTap,
  });

  Color get _accent {
    switch (role) {
      case GameRole.police:
        return AppColors.police;
      case GameRole.babu:
        return AppColors.raja;
      case GameRole.chor:
        return AppColors.chor;
      case GameRole.dakat:
        return AppColors.chintaykari;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.surfaceElevatedDark,
              border: Border.all(color: _accent, width: 2),
              boxShadow: AppColors.darkNeonGlow(_accent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.style_rounded, color: _accent, size: 36),
                AppSpacing.gapVSm,
                Text(
                  role.label,
                  style: HomeTextStyles.title(color: AppColors.textLightPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuspectGrid extends StatelessWidget {
  final SinglePlayerState state;
  final ValueChanged<String> onGuess;

  const _SuspectGrid({required this.state, required this.onGuess});

  @override
  Widget build(BuildContext context) {
    final suspects = state.view!.players
        .where((p) => p.playerId != state.humanId)
        .toList();

    return Column(
      children: [
        Text(
          'কাদের উপর সন্দেহ?',
          style: HomeTextStyles.title(color: AppColors.textLightPrimary),
        ),
        AppSpacing.gapVMd,
        Expanded(
          child: ListView.separated(
            itemCount: suspects.length,
            separatorBuilder: (_, _) => AppSpacing.gapVSm,
            itemBuilder: (context, i) {
              final card = suspects[i];
              return TactileMenuButton(
                text: card.name,
                icon: Icons.person_search_rounded,
                accentColor: AppColors.police,
                enabled: !state.busy,
                onTap: () => onGuess(card.playerId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultPane extends StatelessWidget {
  final SinglePlayerState state;
  final VoidCallback onAgain;

  const _ResultPane({required this.state, required this.onAgain});

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    final accent = result.isCorrect ? AppColors.success : AppColors.chor;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent, width: 2),
            boxShadow: AppColors.darkNeonGlow(accent),
            color: AppColors.surfaceElevatedDark,
          ),
          child: Column(
            children: [
              Icon(
                result.isCorrect
                    ? Icons.local_police_rounded
                    : Icons.directions_run_rounded,
                color: accent,
                size: 48,
              ),
              AppSpacing.gapVMd,
              Text(
                state.statusMessage ?? '',
                textAlign: TextAlign.center,
                style: HomeTextStyles.hero(color: accent),
              ),
              AppSpacing.gapVSm,
              Text(
                'Chor was: ${state.players.firstWhere((p) => p.id == result.chorPlayerId).name}',
                style: HomeTextStyles.subtitle(),
              ),
            ],
          ),
        ),
        const Spacer(),
        TactileMenuButton(
          text: 'Play Again',
          icon: Icons.replay_rounded,
          accentColor: AppColors.secondary,
          onTap: onAgain,
        ),
      ],
    );
  }
}
