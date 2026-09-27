import 'audio_event.dart';

/// Centralized asset paths for [AudioEvent]s.
///
/// Replace files under `assets/sounds/` without changing callers.
/// Until final production audio exists, [resolvedPath] falls back to the
/// bundled placeholder WAVs (`ticking`, `sting`, `success`, `failure`).
abstract final class AudioCatalog {
  static const String _ui = 'sounds/ui';
  static const String _lobby = 'sounds/lobby';
  static const String _role = 'sounds/role';
  static const String _game = 'sounds/gameplay';
  static const String _result = 'sounds/result';
  static const String _final = 'sounds/final';
  static const String _music = 'sounds/music';

  static const String placeholderTick = 'sounds/ticking.wav';
  static const String placeholderSting = 'sounds/sting.wav';
  static const String placeholderSuccess = 'sounds/success.wav';
  static const String placeholderFailure = 'sounds/failure.wav';

  /// Intended production path for each event (replaceable assets).
  static const Map<AudioEvent, String> paths = {
    // Home
    AudioEvent.homeTheme: '$_music/home_theme.wav',
    AudioEvent.buttonTap: '$_ui/button_tap.wav',
    AudioEvent.cardTap: '$_ui/card_tap.wav',
    AudioEvent.navigationWhoosh: '$_ui/navigation_whoosh.wav',
    AudioEvent.toggleClick: '$_ui/toggle_click.wav',
    AudioEvent.coinSoft: '$_ui/coin_soft.wav',

    // Lobby
    AudioEvent.playerJoined: '$_lobby/player_joined.wav',
    AudioEvent.playerReady: '$_lobby/player_ready.wav',
    AudioEvent.playerLeft: '$_lobby/player_left.wav',
    AudioEvent.roomCreated: '$_lobby/room_created.wav',
    AudioEvent.roomJoined: '$_lobby/room_joined.wav',
    AudioEvent.gameStartStinger: '$_lobby/game_start_stinger.wav',

    // Role
    AudioEvent.roleShuffle: '$_role/role_shuffle.wav',
    AudioEvent.roleCardFlip: '$_role/role_card_flip.wav',
    AudioEvent.rolePolice: '$_role/role_police.wav',
    AudioEvent.roleChor: '$_role/role_chor.wav',
    AudioEvent.roleDakat: '$_role/role_dakat.wav',
    AudioEvent.roleBabu: '$_role/role_babu.wav',

    // Gameplay
    AudioEvent.timerTick: '$_game/timer_tick.wav',
    AudioEvent.timerWarning: '$_game/timer_warning.wav',
    AudioEvent.suspectSelected: '$_game/suspect_selected.wav',
    AudioEvent.confirmGuess: '$_game/confirm_guess.wav',
    AudioEvent.guessLocked: '$_game/guess_locked.wav',
    AudioEvent.tensionSting: '$_game/tension_sting.wav',

    // Result
    AudioEvent.correctGuess: '$_result/correct_guess.wav',
    AudioEvent.wrongGuess: '$_result/wrong_guess.wav',
    AudioEvent.policeTag: '$_result/police_tag.wav',
    AudioEvent.scoreIncrement: '$_result/score_increment.wav',
    AudioEvent.coinReward: '$_result/coin_reward.wav',
    AudioEvent.roundComplete: '$_result/round_complete.wav',
    AudioEvent.successSting: '$_result/success_sting.wav',
    AudioEvent.failureSting: '$_result/failure_sting.wav',

    // Final
    AudioEvent.victorySting: '$_final/victory_sting.wav',
    AudioEvent.defeatSting: '$_final/defeat_sting.wav',
    AudioEvent.trophyReveal: '$_final/trophy_reveal.wav',
    AudioEvent.badgeUnlock: '$_final/badge_unlock.wav',
  };

  /// Temporary stand-ins while production files are missing.
  static const Map<AudioEvent, String> placeholders = {
    AudioEvent.homeTheme: placeholderSting,
    AudioEvent.buttonTap: placeholderTick,
    AudioEvent.cardTap: placeholderTick,
    AudioEvent.navigationWhoosh: placeholderTick,
    AudioEvent.toggleClick: placeholderTick,
    AudioEvent.coinSoft: placeholderSuccess,
    AudioEvent.playerJoined: placeholderTick,
    AudioEvent.playerReady: placeholderTick,
    AudioEvent.playerLeft: placeholderTick,
    AudioEvent.roomCreated: placeholderSting,
    AudioEvent.roomJoined: placeholderSting,
    AudioEvent.gameStartStinger: placeholderSting,
    AudioEvent.roleShuffle: placeholderTick,
    AudioEvent.roleCardFlip: placeholderSting,
    AudioEvent.rolePolice: placeholderSting,
    AudioEvent.roleChor: placeholderFailure,
    AudioEvent.roleDakat: placeholderSting,
    AudioEvent.roleBabu: placeholderSuccess,
    AudioEvent.timerTick: placeholderTick,
    AudioEvent.timerWarning: placeholderTick,
    AudioEvent.suspectSelected: placeholderTick,
    AudioEvent.confirmGuess: placeholderSting,
    AudioEvent.guessLocked: placeholderSting,
    AudioEvent.tensionSting: placeholderSting,
    AudioEvent.correctGuess: placeholderSuccess,
    AudioEvent.wrongGuess: placeholderFailure,
    AudioEvent.policeTag: placeholderSuccess,
    AudioEvent.scoreIncrement: placeholderSuccess,
    AudioEvent.coinReward: placeholderSuccess,
    AudioEvent.roundComplete: placeholderSting,
    AudioEvent.successSting: placeholderSuccess,
    AudioEvent.failureSting: placeholderFailure,
    AudioEvent.victorySting: placeholderSuccess,
    AudioEvent.defeatSting: placeholderFailure,
    AudioEvent.trophyReveal: placeholderSuccess,
    AudioEvent.badgeUnlock: placeholderSuccess,
  };

  static AudioChannel channelFor(AudioEvent event) {
    if (event == AudioEvent.homeTheme) return AudioChannel.music;
    return AudioChannel.sfx;
  }

  /// Prefer production path; callers may fall back to [placeholderFor].
  static String pathFor(AudioEvent event) => paths[event]!;

  static String placeholderFor(AudioEvent event) => placeholders[event]!;
}
