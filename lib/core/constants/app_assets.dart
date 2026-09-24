/// Asset path constants for images, icons, and audio clips.
abstract final class AppAssets {
  // --- Base Directories ---
  static const String _imagesBase = 'assets/images';
  static const String _iconsBase = 'assets/icons';
  static const String _soundsBase = 'assets/sounds';

  // --- Brand Images & Illustrations ---
  /// Main DakatBabu game logo.
  static const String logo = '$_imagesBase/brand/logo_chor_police_dakat_babu.png';

  /// Splash screen brand mark.
  static const String splashLogo = '$_imagesBase/dakat_babu_splash.png';

  /// App store / launcher style icon art.
  static const String appIcon = '$_imagesBase/brand/app_icon.png';

  /// Standing hero — Police.
  static const String policeStanding =
      '$_imagesBase/characters/police/standing.png';

  /// Standing hero — Chor.
  static const String chorStanding = '$_imagesBase/characters/chor/standing.png';

  /// Standing hero — Dakat.
  static const String dakatStanding =
      '$_imagesBase/characters/dakat/standing.png';

  /// Standing hero — Babu.
  static const String babuStanding = '$_imagesBase/characters/babu/standing.png';

  /// Role card — Police.
  static const String roleCardPolice = '$_imagesBase/role_cards/police.png';

  /// Role card — Chor.
  static const String roleCardChor = '$_imagesBase/role_cards/chor.png';

  /// Role card — Dakat.
  static const String roleCardDakat = '$_imagesBase/role_cards/dakat.png';

  /// Role card — Babu.
  static const String roleCardBabu = '$_imagesBase/role_cards/babu.png';

  /// Background decorative party ornament pattern.
  static const String patternBackground = '$_imagesBase/bg_pattern.png';

  /// Dhaka city street backdrop.
  static const String bgDhakaCityStreet =
      '$_imagesBase/backgrounds/dhaka_city_street.png';

  /// Crown illustration for Raja role.
  static const String rajaCrown = '$_imagesBase/roles/raja_crown.png';

  /// Royal decree scroll for Mantri role.
  static const String mantriScroll = '$_imagesBase/roles/mantri_scroll.png';

  /// Handcuffs & badge for Police role.
  static const String policeBadge = '$_imagesBase/roles/police_badge.png';

  /// Mask & dagger for Chor role.
  static const String chorMask = '$_imagesBase/roles/chor_mask.png';

  // --- UI Icons ---
  /// Host player crown badge icon.
  static const String iconCrown = '$_iconsBase/ic_crown.svg';

  /// Copy to clipboard action icon.
  static const String iconCopy = '$_iconsBase/ic_copy.svg';

  /// Game sound mute/unmute toggle icon.
  static const String iconAudio = '$_iconsBase/ic_audio.svg';

  // --- Sound Effects ---
  /// Dramatic sting when player uncovers their role card.
  static const String soundRoleReveal = '$_soundsBase/role_reveal.mp3';

  /// Tension ticking sound during Police guess countdown.
  static const String soundTimerTick = '$_soundsBase/timer_tick.mp3';

  /// Celebratory fanfare when Police correctly finds the Chor.
  static const String soundPoliceWin = '$_soundsBase/police_win.mp3';

  /// Deceptive laugh when Chor outsmarts the Police.
  static const String soundChorWin = '$_soundsBase/chor_win.mp3';
}
