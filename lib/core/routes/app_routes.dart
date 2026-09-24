/// Named routes and URL path helpers for Chor Police Dakat Babu.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String modeSelect = '/modes';
  static const String createJoin = '/create-join';
  static const String settings = '/settings';
  static const String badges = '/badges';
  static const String howToPlay = '/how-to-play';
  static const String personalScore = '/my-score';
  static const String robot = '/robot';
  static const String connectionError = '/connection-error';

  static const String lobby = '/lobby/:roomCode';
  static const String gameRound = '/game/:roomCode';
  static const String results = '/results/:roomCode';
  static const String scoreboard = '/scoreboard/:roomCode';
  static const String passAndPlaySetup = '/pass-and-play-setup';
  static const String passAndPlayGame = '/pass-and-play';

  static const String splashName = 'splash';
  static const String homeName = 'home';
  static const String modeSelectName = 'modeSelect';
  static const String createJoinName = 'createJoin';
  static const String settingsName = 'settings';
  static const String badgesName = 'badges';
  static const String howToPlayName = 'howToPlay';
  static const String personalScoreName = 'personalScore';
  static const String robotName = 'robot';
  static const String connectionErrorName = 'connectionError';
  static const String lobbyName = 'lobby';
  static const String gameRoundName = 'gameRound';
  static const String resultsName = 'results';
  static const String scoreboardName = 'scoreboard';
  static const String passAndPlaySetupName = 'passAndPlaySetup';
  static const String passAndPlayGameName = 'passAndPlayGame';

  static const String paramRoomCode = 'roomCode';

  static String lobbyPath(String roomCode) => '/lobby/$roomCode';
  static String gameRoundPath(String roomCode) => '/game/$roomCode';
  static String resultsPath(String roomCode) => '/results/$roomCode';
  static String scoreboardPath(String roomCode) => '/scoreboard/$roomCode';
}
