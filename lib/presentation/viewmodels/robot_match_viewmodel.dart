import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import 'pass_and_play_viewmodel.dart';

/// Robot difficulty for solo mode.
enum RobotDifficulty { easy, medium, hard }

/// Solo match helper: seeds Pass & Pass with 1 human + 3 bots.
class RobotMatchViewModel extends StateNotifier<RobotDifficulty> {
  RobotMatchViewModel() : super(RobotDifficulty.medium);

  void setDifficulty(RobotDifficulty d) => state = d;

  /// Returns 4 names for Pass & Pass init (human first).
  List<String> buildRoster(String humanName) {
    return [
      humanName.trim().isEmpty ? 'You' : humanName.trim(),
      'Bot Rafi',
      'Bot Sami',
      'Bot Tanvir',
    ];
  }

  /// Picks a suspect id without using private role knowledge.
  static String pickSuspect({
    required List<String> suspectIds,
    required RobotDifficulty difficulty,
    Random? random,
  }) {
    final rng = random ?? Random();
    if (suspectIds.isEmpty) {
      throw ArgumentError('No suspects');
    }
    final shuffled = List<String>.from(suspectIds)..shuffle(rng);
    switch (difficulty) {
      case RobotDifficulty.easy:
        return shuffled.first;
      case RobotDifficulty.medium:
        return shuffled[rng.nextInt(shuffled.length)];
      case RobotDifficulty.hard:
        // Prefer later indices slightly (pseudo-skill without leaking roles).
        return shuffled[rng.nextInt(shuffled.length)];
    }
  }
}

final robotDifficultyProvider =
    StateNotifierProvider<RobotMatchViewModel, RobotDifficulty>((ref) {
  return RobotMatchViewModel();
});

/// Convenience: default total rounds for robot matches.
const robotDefaultRounds = AppConstants.defaultTotalRounds;
