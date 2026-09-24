import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/game/game_engine.dart';
import '../../domain/game/game_role.dart';
import 'pass_and_play_viewmodel.dart';

/// Robot difficulty for solo mode.
enum RobotDifficulty { easy, medium, hard }

/// Solo match: 1 human + 3 AI using [GameEngine].
class RobotMatchState {
  final PassAndPlayState game;
  final RobotDifficulty difficulty;
  final String humanPlayerId;
  final bool waitingForAiGuess;

  const RobotMatchState({
    required this.game,
    this.difficulty = RobotDifficulty.medium,
    this.humanPlayerId = 'p_1',
    this.waitingForAiGuess = false,
  });

  RobotMatchState copyWith({
    PassAndPlayState? game,
    RobotDifficulty? difficulty,
    bool? waitingForAiGuess,
  }) {
    return RobotMatchState(
      game: game ?? this.game,
      difficulty: difficulty ?? this.difficulty,
      humanPlayerId: humanPlayerId,
      waitingForAiGuess: waitingForAiGuess ?? this.waitingForAiGuess,
    );
  }
}

class RobotMatchViewModel extends StateNotifier<RobotMatchState> {
  final Random _random;
  late final PassAndPlayViewModel _inner;

  RobotMatchViewModel({Random? random})
      : _random = random ?? Random(),
        _inner = PassAndPlayViewModel(random: random ?? Random()),
        super(RobotMatchState(game: const PassAndPlayState()));

  void start({
    required String humanName,
    RobotDifficulty difficulty = RobotDifficulty.medium,
    int totalRounds = AppConstants.defaultTotalRounds,
  }) {
    _inner.initMatch(
      playerNames: [
        humanName,
        'Bot Rafi',
        'Bot Sami',
        'Bot Tanvir',
      ],
      totalRounds: totalRounds,
    );
    // Auto-peek all roles privately for bots; human peeks via UI.
    state = RobotMatchState(
      game: _inner.state,
      difficulty: difficulty,
    );
  }

  PassAndPlayViewModel get controller => _inner;

  void syncFromInner() {
    state = state.copyWith(game: _inner.state);
  }

  /// If Police is a bot, auto-select a suspect based on difficulty.
  Future<void> maybeAutoPoliceGuess() async {
    final game = _inner.state;
    final police = game.policePlayer;
    if (police == null) return;
    if (police.id == state.humanPlayerId) return;
    if (game.stage != PassAndPlayStage.policeAccusing) return;

    state = state.copyWith(waitingForAiGuess: true);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final suspects = game.suspects;
    if (suspects.isEmpty) return;

    String pickId;
    switch (state.difficulty) {
      case RobotDifficulty.easy:
        pickId = suspects[_random.nextInt(suspects.length)].id;
      case RobotDifficulty.medium:
        // 50% chance to pick Chor if somehow known — otherwise weighted random
        // Prefer not repeating last wrong if we tracked it; simple: 40% babu bias avoid
        final nonBabu =
            suspects.where((s) => s.role != GameRole.babu).toList();
        final pool = nonBabu.isEmpty ? suspects : nonBabu;
        pickId = pool[_random.nextInt(pool.length)].id;
      case RobotDifficulty.hard:
        // Hard: never pick visible Babu first; 70% pick among hidden (chor/dakat)
        final hidden =
            suspects.where((s) => s.role != GameRole.babu).toList();
        if (hidden.isNotEmpty && _random.nextDouble() < 0.7) {
          // Still can't know chor — 50/50 between hidden
          pickId = hidden[_random.nextInt(hidden.length)].id;
        } else {
          pickId = suspects[_random.nextInt(suspects.length)].id;
        }
    }

    // Bots shouldn't use private role knowledge of chor — strip role from pick:
    // Re-pick using only ids (roles are known to engine but AI uses id list only).
    final idOnly = suspects.map((s) => s.id).toList()..shuffle(_random);
    if (state.difficulty == RobotDifficulty.easy) {
      pickId = idOnly.first;
    }

    _inner.makeAccusation(pickId);
    state = state.copyWith(game: _inner.state, waitingForAiGuess: false);
  }
}

final robotMatchViewModelProvider =
    StateNotifierProvider<RobotMatchViewModel, RobotMatchState>((ref) {
  return RobotMatchViewModel();
});
