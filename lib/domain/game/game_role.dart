/// Canonical roles for Chor Police Dakat Babu (exactly four, no duplicates).
enum GameRole {
  /// Must identify the Chor among suspects.
  police,

  /// Wealthy visible role; known to other players after distribution.
  babu,

  /// Hidden thief — Police's only correct target.
  chor,

  /// Hidden decoy — not a valid win target for Police.
  dakat;

  /// Parses a role string; returns null if unknown.
  static GameRole? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.toLowerCase().trim();
    // Legacy aliases from Raja/Mantri era.
    switch (normalized) {
      case 'raja':
        return GameRole.babu;
      case 'mantri':
        return GameRole.babu;
      case 'police':
        return GameRole.police;
      case 'chor':
        return GameRole.chor;
      case 'dakat':
        return GameRole.dakat;
      case 'babu':
        return GameRole.babu;
      default:
        return null;
    }
  }

  /// Display label.
  String get label {
    switch (this) {
      case GameRole.police:
        return 'Police';
      case GameRole.babu:
        return 'Babu';
      case GameRole.chor:
        return 'Chor';
      case GameRole.dakat:
        return 'Dakat';
    }
  }
}
