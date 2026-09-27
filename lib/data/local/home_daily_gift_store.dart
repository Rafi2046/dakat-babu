import 'package:shared_preferences/shared_preferences.dart';

/// Local date-based daily gift claim (no economy backend).
class HomeDailyGiftStore {
  HomeDailyGiftStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kClaimedDate = 'home_daily_gift_claimed_date';

  static String _todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  bool isClaimedToday([DateTime? now]) {
    return _prefs.getString(_kClaimedDate) == _todayKey(now);
  }

  Future<void> claimToday([DateTime? now]) async {
    await _prefs.setString(_kClaimedDate, _todayKey(now));
  }
}
