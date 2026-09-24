/// Catalog of unlockable badges.
class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String iconAsset;
  final bool Function(BadgeProgress progress) isUnlocked;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.isUnlocked,
  });
}

/// Snapshot used to evaluate badge conditions.
class BadgeProgress {
  final int correctGuesses;
  final int policeTags;
  final int gamesPlayed;
  final int wins;
  final int bestStreak;
  final int highestScore;

  const BadgeProgress({
    this.correctGuesses = 0,
    this.policeTags = 0,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.bestStreak = 0,
    this.highestScore = 0,
  });
}

/// Built-in badge definitions.
abstract final class BadgeCatalog {
  static final List<BadgeDefinition> all = [
    BadgeDefinition(
      id: 'first_win',
      name: 'First Win',
      description: 'Win your first match',
      iconAsset: 'assets/images/badges/winner.png',
      isUnlocked: (p) => p.wins >= 1,
    ),
    BadgeDefinition(
      id: 'correct_10',
      name: '10 Correct Guesses',
      description: 'Catch the Chor 10 times',
      iconAsset: 'assets/images/badges/police.png',
      isUnlocked: (p) => p.correctGuesses >= 10,
    ),
    BadgeDefinition(
      id: 'correct_50',
      name: '50 Correct Guesses',
      description: 'Catch the Chor 50 times',
      iconAsset: 'assets/images/badges/champion.png',
      isUnlocked: (p) => p.correctGuesses >= 50,
    ),
    BadgeDefinition(
      id: 'police_master',
      name: 'Police Master',
      description: 'Earn 18 Police Tags',
      iconAsset: 'assets/images/badges/police.png',
      isUnlocked: (p) => p.policeTags >= 18,
    ),
    BadgeDefinition(
      id: 'games_10',
      name: '10 Games Played',
      description: 'Play 10 matches',
      iconAsset: 'assets/images/badges/babu.png',
      isUnlocked: (p) => p.gamesPlayed >= 10,
    ),
    BadgeDefinition(
      id: 'games_50',
      name: '50 Games Played',
      description: 'Play 50 matches',
      iconAsset: 'assets/images/badges/dakat.png',
      isUnlocked: (p) => p.gamesPlayed >= 50,
    ),
    BadgeDefinition(
      id: 'games_100',
      name: '100 Games Played',
      description: 'Play 100 matches',
      iconAsset: 'assets/images/badges/champion.png',
      isUnlocked: (p) => p.gamesPlayed >= 100,
    ),
    BadgeDefinition(
      id: 'win_streak',
      name: 'Win Streak',
      description: 'Win 5 matches in a row',
      iconAsset: 'assets/images/badges/winner.png',
      isUnlocked: (p) => p.bestStreak >= 5,
    ),
    BadgeDefinition(
      id: 'chor_master',
      name: 'Chor Master',
      description: 'Reach highest score 20+',
      iconAsset: 'assets/images/badges/chor.png',
      isUnlocked: (p) => p.highestScore >= 20,
    ),
    BadgeDefinition(
      id: 'multiplayer_master',
      name: 'Multiplayer Master',
      description: 'Play 25 games',
      iconAsset: 'assets/images/badges/champion.png',
      isUnlocked: (p) => p.gamesPlayed >= 25,
    ),
  ];

  /// Evaluates and returns newly unlocked badge ids.
  static List<String> evaluateNewUnlocks({
    required BadgeProgress progress,
    required Set<String> alreadyUnlocked,
  }) {
    final newly = <String>[];
    for (final badge in all) {
      if (alreadyUnlocked.contains(badge.id)) continue;
      if (badge.isUnlocked(progress)) newly.add(badge.id);
    }
    return newly;
  }
}
