/// Semantic audio events. UI and gameplay call these — never raw asset paths.
enum AudioEvent {
  // Home
  homeTheme,
  buttonTap,
  cardTap,
  navigationWhoosh,
  toggleClick,
  coinSoft,

  // Lobby
  playerJoined,
  playerReady,
  playerLeft,
  roomCreated,
  roomJoined,
  gameStartStinger,

  // Role reveal
  roleShuffle,
  roleCardFlip,
  rolePolice,
  roleChor,
  roleDakat,
  roleBabu,

  // Gameplay
  timerTick,
  timerWarning,
  suspectSelected,
  confirmGuess,
  guessLocked,
  tensionSting,

  // Result
  correctGuess,
  wrongGuess,
  policeTag,
  scoreIncrement,
  coinReward,
  roundComplete,

  // Final
  victorySting,
  defeatSting,
  trophyReveal,
  badgeUnlock,
}

/// Channel used for volume / mute routing.
enum AudioChannel {
  music,
  sfx,
}
