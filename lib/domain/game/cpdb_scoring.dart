import 'game_role.dart';

/// Classic childhood CPDB point table (Babu / Police / Dakat / Chor).
abstract final class CpdbScoring {
  static const int babu = 900;
  static const int police = 800;
  static const int dakat = 600;
  static const int chor = 400;

  /// Base face value of each role (UI hints / scoreboard legend).
  static const Map<GameRole, int> basePoints = {
    GameRole.babu: babu,
    GameRole.police: police,
    GameRole.dakat: dakat,
    GameRole.chor: chor,
  };

  static int baseFor(GameRole role) => basePoints[role]!;
}
