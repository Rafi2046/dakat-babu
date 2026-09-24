import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistent local player profile, stats, settings, and badge unlocks.
class PlayerProfileStore {
  PlayerProfileStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kName = 'profile_name';
  static const _kAvatar = 'profile_avatar';
  static const _kCorrect = 'stat_correct_guesses';
  static const _kPoliceTags = 'stat_police_tags';
  static const _kHighest = 'stat_highest_score';
  static const _kGames = 'stat_games_played';
  static const _kWins = 'stat_wins';
  static const _kLosses = 'stat_losses';
  static const _kStreak = 'stat_best_streak';
  static const _kCurrentStreak = 'stat_current_streak';
  static const _kMusic = 'setting_music';
  static const _kSound = 'setting_sound';
  static const _kVibration = 'setting_vibration';
  static const _kNotifications = 'setting_notifications';
  static const _kLanguage = 'setting_language';
  static const _kBadges = 'badges_unlocked';

  String get playerName => _prefs.getString(_kName) ?? 'Player';
  Future<void> setPlayerName(String name) => _prefs.setString(_kName, name);

  String get avatarId => _prefs.getString(_kAvatar) ?? 'default';
  Future<void> setAvatarId(String id) => _prefs.setString(_kAvatar, id);

  int get correctGuesses => _prefs.getInt(_kCorrect) ?? 0;
  int get policeTags => _prefs.getInt(_kPoliceTags) ?? 0;
  int get highestScore => _prefs.getInt(_kHighest) ?? 0;
  int get gamesPlayed => _prefs.getInt(_kGames) ?? 0;
  int get wins => _prefs.getInt(_kWins) ?? 0;
  int get losses => _prefs.getInt(_kLosses) ?? 0;
  int get bestStreak => _prefs.getInt(_kStreak) ?? 0;
  int get currentStreak => _prefs.getInt(_kCurrentStreak) ?? 0;

  bool get musicEnabled => _prefs.getBool(_kMusic) ?? true;
  bool get soundEnabled => _prefs.getBool(_kSound) ?? true;
  bool get vibrationEnabled => _prefs.getBool(_kVibration) ?? true;
  bool get notificationsEnabled => _prefs.getBool(_kNotifications) ?? true;
  String get language => _prefs.getString(_kLanguage) ?? 'en';

  Future<void> setMusicEnabled(bool v) => _prefs.setBool(_kMusic, v);
  Future<void> setSoundEnabled(bool v) => _prefs.setBool(_kSound, v);
  Future<void> setVibrationEnabled(bool v) => _prefs.setBool(_kVibration, v);
  Future<void> setNotificationsEnabled(bool v) =>
      _prefs.setBool(_kNotifications, v);
  Future<void> setLanguage(String code) => _prefs.setString(_kLanguage, code);

  Set<String> get unlockedBadgeIds {
    final raw = _prefs.getString(_kBadges);
    if (raw == null || raw.isEmpty) return {};
    final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
    return list.toSet();
  }

  Future<void> unlockBadge(String id) async {
    final set = unlockedBadgeIds..add(id);
    await _prefs.setString(_kBadges, jsonEncode(set.toList()));
  }

  /// Records end-of-match stats for the local human player.
  Future<void> recordMatchResult({
    required int matchScore,
    required int correctGuessesDelta,
    required int policeTagsDelta,
    required bool won,
  }) async {
    await _prefs.setInt(_kCorrect, correctGuesses + correctGuessesDelta);
    await _prefs.setInt(_kPoliceTags, policeTags + policeTagsDelta);
    if (matchScore > highestScore) {
      await _prefs.setInt(_kHighest, matchScore);
    }
    await _prefs.setInt(_kGames, gamesPlayed + 1);
    if (won) {
      await _prefs.setInt(_kWins, wins + 1);
      final streak = currentStreak + 1;
      await _prefs.setInt(_kCurrentStreak, streak);
      if (streak > bestStreak) await _prefs.setInt(_kStreak, streak);
    } else {
      await _prefs.setInt(_kLosses, losses + 1);
      await _prefs.setInt(_kCurrentStreak, 0);
    }
  }
}
