import 'package:dakat_babu/data/local/home_daily_gift_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeDailyGiftStore', () {
    late HomeDailyGiftStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      store = HomeDailyGiftStore(prefs);
    });

    test('available before claim', () {
      final day = DateTime(2026, 9, 27);
      expect(store.isClaimedToday(day), isFalse);
    });

    test('becomes claimed after collecting same local date', () async {
      final day = DateTime(2026, 9, 27);
      await store.claimToday(day);
      expect(store.isClaimedToday(day), isTrue);
    });

    test('remains claimed for the same local date', () async {
      final day = DateTime(2026, 9, 27, 8);
      await store.claimToday(day);
      expect(store.isClaimedToday(DateTime(2026, 9, 27, 23, 59)), isTrue);
    });

    test('becomes available again on a new local date', () async {
      await store.claimToday(DateTime(2026, 9, 27));
      expect(store.isClaimedToday(DateTime(2026, 9, 28)), isFalse);
    });
  });
}
