import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';

/// Robot difficulty for solo mode.
enum RobotDifficulty { easy, medium, hard }

/// Solo match helper: seeds Pass & Pass with 1 human + 3 bots.
class RobotMatchViewModel extends StateNotifier<RobotDifficulty> {
  RobotMatchViewModel() : super(RobotDifficulty.medium);

  void setDifficulty(RobotDifficulty d) => state = d;

  List<String> buildRoster(String humanName) {
    return [
      humanName.trim().isEmpty ? 'You' : humanName.trim(),
      'Bot Rafi',
      'Bot Sami',
      'Bot Tanvir',
    ];
  }

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
      case RobotDifficulty.medium:
      case RobotDifficulty.hard:
        return shuffled[rng.nextInt(shuffled.length)];
    }
  }
}

final robotDifficultyProvider =
    StateNotifierProvider<RobotMatchViewModel, RobotDifficulty>((ref) {
  return RobotMatchViewModel();
});

const robotDefaultRounds = AppConstants.defaultTotalRounds;
