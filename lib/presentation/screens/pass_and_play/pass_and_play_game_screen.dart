import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/game/badge_catalog.dart';
import '../../../domain/game/game_role.dart';
import '../../viewmodels/pass_and_play_viewmodel.dart';
import '../../widgets/cpdb/cpdb.dart';
import '../../widgets/cpdb/game_card_placeholder.dart';

/// Pass & Pass match — privacy handoff + police accuse + results.
class PassAndPlayGameScreen extends ConsumerWidget {
  const PassAndPlayGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(passAndPlayViewModelProvider);
    final notifier = ref.read(passAndPlayViewModelProvider.notifier);

    if (state.players.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.home);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final quit = await ConfirmationDialog.show(
          context,
          title: 'Quit Match?',
          message: 'Progress will be lost.',
          confirmLabel: 'QUIT',
          isDestructive: true,
        );
        if (quit == true && context.mounted) context.go(AppRoutes.home);
      },
      child: AppShell(
        padding: EdgeInsets.zero,
        topBar: TopBar(
          title: state.stage == PassAndPlayStage.matchOver
              ? 'Final Score'
              : 'Round ${state.currentRound} / ${state.totalRounds}',
          showProfile: false,
          onBack: () async {
            final quit = await ConfirmationDialog.show(
              context,
              title: 'Quit Match?',
              message: 'Progress will be lost.',
              confirmLabel: 'QUIT',
              isDestructive: true,
            );
            if (quit == true && context.mounted) context.go(AppRoutes.home);
          },
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: RoundIndicator(
                  current: state.currentRound,
                  total: state.totalRounds,
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(state.stage),
                  child: _stage(context, ref, state, notifier),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stage(
    BuildContext context,
    WidgetRef ref,
    PassAndPlayState state,
    PassAndPlayViewModel notifier,
  ) {
    switch (state.stage) {
      case PassAndPlayStage.passToPlayer:
        return _passPhone(state, notifier);
      case PassAndPlayStage.peekRole:
        return _peek(state, notifier);
      case PassAndPlayStage.handToPolice:
        return _handPolice(state, notifier);
      case PassAndPlayStage.policeAccusing:
        return _accuse(state, notifier);
      case PassAndPlayStage.confirmSuspect:
        return _confirm(state, notifier);
      case PassAndPlayStage.roundResults:
        return _results(state, notifier);
      case PassAndPlayStage.matchOver:
        return _final(context, ref, state, notifier);
    }
  }

  Widget _passPhone(PassAndPlayState state, PassAndPlayViewModel notifier) {
    final p = state.currentPeekingPlayer;
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Pass the phone', style: AppTextStyles.heading1()),
          AppSpacing.gapVMd,
          CharacterAvatar(name: p?.name ?? '?', size: 96),
          AppSpacing.gapVMd,
          Text(
            'Player ${state.currentPeekIndex + 1}: ${p?.name ?? ''}',
            style: AppTextStyles.heading2(),
          ),
          AppSpacing.gapVSm,
          Text(
            'Only this player should look at the screen.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(),
          ),
          AppSpacing.gapVXl,
          GameButton(label: 'I HAVE THE PHONE', onPressed: notifier.readyToPeek),
        ],
      ),
    );
  }

  Widget _peek(PassAndPlayState state, PassAndPlayViewModel notifier) {
    final p = state.currentPeekingPlayer;
    final role = p?.role;
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: state.isCardRevealed && role != null
                  ? RoleCard(role: role)
                  : GameCardPlaceholder(
                      onTap: notifier.toggleCardReveal,
                      label: 'TAP TO REVEAL YOUR ROLE',
                    ),
            ),
          ),
          if (state.isCardRevealed)
            GameButton(
              label: 'DONE — HIDE & PASS',
              onPressed: notifier.finishPeekingCurrentPlayer,
            )
          else
            GameButton(
              label: 'REVEAL',
              onPressed: notifier.toggleCardReveal,
              variant: ButtonVariant.accent,
            ),
        ],
      ),
    );
  }

  Widget _handPolice(PassAndPlayState state, PassAndPlayViewModel notifier) {
    final police = state.policePlayer;
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Hand phone to Police', style: AppTextStyles.heading1()),
          AppSpacing.gapVMd,
          CharacterAvatar(
            name: police?.name ?? 'Police',
            assetPath: AppImages.policeStanding,
            size: 100,
          ),
          AppSpacing.gapVMd,
          Text(police?.name ?? '', style: AppTextStyles.heading2()),
          AppSpacing.gapVXl,
          GameButton(
            label: 'I AM POLICE — START',
            onPressed: notifier.beginPoliceInterrogation,
          ),
        ],
      ),
    );
  }

  Widget _accuse(PassAndPlayState state, PassAndPlayViewModel notifier) {
    final view = state.policeView;
    return GameRoomLayout(
      gameplay: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Police, choose a suspect!', style: AppTextStyles.heading3()),
            AppSpacing.gapVMd,
            Expanded(
              child: PlayerGrid(
                children: [
                  for (final s in state.suspects)
                    PlayerCard(
                      name: s.name,
                      visibleRole: () {
                        final cards = view?.players
                                .where((c) => c.playerId == s.id)
                                .toList() ??
                            const [];
                        return cards.isEmpty ? null : cards.first.visibleRole;
                      }(),
                      state: s.role == GameRole.babu
                          ? PlayerCardState.babu
                          : PlayerCardState.hidden,
                      onTap: () => notifier.selectSuspect(s.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      scoreboard: ScoreboardPanel(
        rows: [
          for (var i = 0; i < state.leaderboard.length; i++)
            ScoreRow(
              rank: i + 1,
              name: state.leaderboard[i].name,
              score: state.leaderboard[i].totalScore,
              highlight: state.leaderboard[i].id == state.policePlayer?.id,
            ),
        ],
      ),
    );
  }

  Widget _confirm(PassAndPlayState state, PassAndPlayViewModel notifier) {
    final accused = state.accusedPlayer;
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Are you sure?', style: AppTextStyles.heading1()),
          AppSpacing.gapVMd,
          if (accused != null)
            PlayerCard(
              name: accused.name,
              state: PlayerCardState.selected,
            ),
          AppSpacing.gapVXl,
          GameButton(
            label: 'CONFIRM SUSPECT',
            onPressed: notifier.confirmAccusation,
          ),
          AppSpacing.gapVMd,
          GameButton(
            label: 'CANCEL',
            onPressed: notifier.cancelSuspect,
            variant: ButtonVariant.outlined,
          ),
        ],
      ),
    );
  }

  Widget _results(PassAndPlayState state, PassAndPlayViewModel notifier) {
    final correct = state.isGuessCorrect == true;
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: ResultFlashCard(
                isCorrect: correct,
                title: correct ? 'CORRECT!' : 'WRONG GUESS!',
                subtitle: correct
                    ? 'Police found the Chor!'
                    : 'তুমি ভুলজনকে ধরেছো!',
                scoreLabel: correct
                    ? 'Police +1'
                    : '${state.accusedPlayer?.name ?? 'Suspect'} +1',
                characterAsset: correct
                    ? AppImages.policeStanding
                    : AppImages.chorStanding,
              ),
            ),
          ),
          AppSpacing.gapVSm,
          Expanded(
            flex: 2,
            child: ScoreboardPanel(
              title: 'ROUND SCORE',
              rows: [
                for (var i = 0; i < state.leaderboard.length; i++)
                  ScoreRow(
                    rank: i + 1,
                    name: state.leaderboard[i].name,
                    score: state.leaderboard[i].totalScore,
                  ),
              ],
            ),
          ),
          AppSpacing.gapVSm,
          GameButton(
            label: state.isLastRound ? 'FINAL SCORE' : 'NEXT ROUND',
            onPressed: notifier.nextRound,
          ),
        ],
      ),
    );
  }

  Widget _final(
    BuildContext context,
    WidgetRef ref,
    PassAndPlayState state,
    PassAndPlayViewModel notifier,
  ) {
    final board = state.leaderboard;
    final winner = board.first;

    return _FinalScoreBody(
      board: board,
      winnerName: winner.name,
      winnerId: winner.id,
      human: state.players.first,
      onPlayAgain: notifier.restartMatch,
      onHome: () => context.go(AppRoutes.home),
    );
  }
}

class _FinalScoreBody extends ConsumerStatefulWidget {
  final List<PassAndPlayPlayer> board;
  final String winnerName;
  final String winnerId;
  final PassAndPlayPlayer human;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const _FinalScoreBody({
    required this.board,
    required this.winnerName,
    required this.winnerId,
    required this.human,
    required this.onPlayAgain,
    required this.onHome,
  });

  @override
  ConsumerState<_FinalScoreBody> createState() => _FinalScoreBodyState();
}

class _FinalScoreBodyState extends ConsumerState<_FinalScoreBody> {
  var _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _persist());
  }

  Future<void> _persist() async {
    if (_saved) return;
    _saved = true;
    final store = ref.read(playerProfileStoreProvider);
    await store.recordMatchResult(
      matchScore: widget.human.totalScore,
      correctGuessesDelta: widget.human.correctGuesses,
      policeTagsDelta: widget.human.policeTags,
      won: widget.human.id == widget.winnerId,
    );
    final newly = BadgeCatalog.evaluateNewUnlocks(
      progress: BadgeProgress(
        correctGuesses: store.correctGuesses,
        policeTags: store.policeTags,
        gamesPlayed: store.gamesPlayed,
        wins: store.wins,
        bestStreak: store.bestStreak,
        highestScore: store.highestScore,
      ),
      alreadyUnlocked: store.unlockedBadgeIds,
    );
    for (final id in newly) {
      await store.unlockBadge(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          Text('FINAL SCORE', style: AppTextStyles.heading1()),
          AppSpacing.gapVMd,
          const Icon(Icons.emoji_events, color: Colors.amber, size: 72),
          Text(widget.winnerName, style: AppTextStyles.heading2()),
          AppSpacing.gapVLg,
          Expanded(
            child: ScoreboardPanel(
              rows: [
                for (var i = 0; i < widget.board.length; i++)
                  ScoreRow(
                    rank: i + 1,
                    name: widget.board[i].name,
                    score: widget.board[i].totalScore,
                    highlight: i == 0,
                  ),
              ],
            ),
          ),
          GameButton(label: 'PLAY AGAIN', onPressed: widget.onPlayAgain),
          AppSpacing.gapVMd,
          GameButton(
            label: 'HOME',
            onPressed: widget.onHome,
            variant: ButtonVariant.outlined,
          ),
        ],
      ),
    );
  }
}
