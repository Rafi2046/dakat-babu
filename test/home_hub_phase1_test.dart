import 'package:dakat_babu/core/constants/app_strings_bn.dart';
import 'package:dakat_babu/core/constants/home_text_styles.dart';
import 'package:dakat_babu/core/di/providers.dart';
import 'package:dakat_babu/core/routes/app_routes.dart';
import 'package:dakat_babu/data/local/home_daily_gift_store.dart';
import 'package:dakat_babu/data/local/player_profile_store.dart';
import 'package:dakat_babu/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HomeTextStyles use bundled NotoSansBengali family', () {
    expect(HomeTextStyles.fontFamily, 'NotoSansBengali');
    expect(HomeTextStyles.title().fontFamily, 'NotoSansBengali');
    expect(HomeTextStyles.title().fontWeight, FontWeight.w700);
    expect(HomeTextStyles.hero().fontWeight, FontWeight.w800);
    expect(HomeTextStyles.body().fontWeight, FontWeight.w600);
    expect(HomeTextStyles.caption().fontWeight, FontWeight.w500);
  });

  group('HomeScreen Phase 1', () {
    late HomeDailyGiftStore gift;
    late List<String> navigated;
    late GoRouter router;

    Future<void> pumpFrames(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    }

    Future<void> pumpHome(
      WidgetTester tester, {
      Size size = const Size(360, 740),
    }) async {
      SharedPreferences.setMockInitialValues({
        'profile_name': 'Agent Kabir',
        'stat_highest_score': 34,
        'stat_games_played': 10,
        'stat_wins': 7,
        'stat_correct_guesses': 5,
        'stat_police_tags': 3,
      });
      final prefs = await SharedPreferences.getInstance();
      final profile = PlayerProfileStore(prefs);
      gift = HomeDailyGiftStore(prefs);
      navigated = <String>[];

      router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.createJoin,
            builder: (_, _) {
              navigated.add(AppRoutes.createJoin);
              return const Scaffold(body: Text('create-join'));
            },
          ),
          GoRoute(
            path: AppRoutes.modeSelect,
            builder: (_, _) {
              navigated.add(AppRoutes.modeSelect);
              return const Scaffold(body: Text('mode-select'));
            },
          ),
          GoRoute(
            path: AppRoutes.robot,
            builder: (_, _) {
              navigated.add(AppRoutes.robot);
              return const Scaffold(body: Text('robot'));
            },
          ),
          GoRoute(
            path: AppRoutes.passAndPlaySetup,
            builder: (_, _) {
              navigated.add(AppRoutes.passAndPlaySetup);
              return const Scaffold(body: Text('pass-setup'));
            },
          ),
          GoRoute(
            path: AppRoutes.personalScore,
            builder: (_, _) {
              navigated.add(AppRoutes.personalScore);
              return const Scaffold(body: Text('score'));
            },
          ),
          GoRoute(
            path: AppRoutes.howToPlay,
            builder: (_, _) {
              navigated.add(AppRoutes.howToPlay);
              return const Scaffold(body: Text('how'));
            },
          ),
          GoRoute(
            path: AppRoutes.badges,
            builder: (_, _) {
              navigated.add(AppRoutes.badges);
              return const Scaffold(body: Text('badges'));
            },
          ),
        ],
      );

      await tester.binding.setSurfaceSize(size);
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerProfileStoreProvider.overrideWithValue(profile),
            homeDailyGiftStoreProvider.overrideWithValue(gift),
            audioManagerProvider.overrideWithValue(
              AudioManager(
                musicEnabled: () => profile.musicEnabled,
                sfxEnabled: () => profile.soundEnabled,
                enablePlayback: false,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await pumpFrames(tester);
    }

    Future<void> tapLabel(WidgetTester tester, String label) async {
      final finder = find.text(label);
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await pumpFrames(tester);
      await tester.tap(finder);
      await pumpFrames(tester);
    }

    testWidgets('small portrait renders Bangla hub without exceptions',
        (tester) async {
      FlutterErrorDetails? overflow;
      final old = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          overflow = details;
        }
        old?.call(details);
      };
      addTearDown(() => FlutterError.onError = old);

      await pumpHome(tester, size: const Size(320, 568));

      expect(find.text(AppStringsBn.featuredTitle), findsOneWidget);
      expect(find.text(AppStringsBn.playOnline), findsOneWidget);
      expect(find.text(AppStringsBn.navLobby), findsOneWidget);
      expect(find.text('Agent Kabir'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(AppStringsBn.playMultiplayer),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(AppStringsBn.playMultiplayer), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(AppStringsBn.collect),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(AppStringsBn.collect), findsOneWidget);
      expect(overflow, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mode cards navigate to existing routes', (tester) async {
      await pumpHome(tester);

      await tapLabel(tester, AppStringsBn.playOnline);
      expect(navigated, contains(AppRoutes.createJoin));
      router.pop();
      await pumpFrames(tester);

      await tapLabel(tester, AppStringsBn.playMultiplayer);
      expect(navigated, contains(AppRoutes.modeSelect));
      router.pop();
      await pumpFrames(tester);

      await tapLabel(tester, AppStringsBn.withComputer);
      expect(navigated, contains(AppRoutes.robot));
      router.pop();
      await pumpFrames(tester);

      await tapLabel(tester, AppStringsBn.passAndPlay);
      expect(navigated, contains(AppRoutes.passAndPlaySetup));
    });

    testWidgets('bottom nav targets + lobby label remains', (tester) async {
      await pumpHome(tester);
      expect(find.text(AppStringsBn.navLobby), findsOneWidget);

      Future<void> tapBottom(IconData icon, String route) async {
        navigated.clear();
        await tester.tap(find.byIcon(icon).last);
        await tester.pump(const Duration(milliseconds: 100));
        expect(navigated, contains(route));
        router.pop();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tapBottom(Icons.bar_chart_rounded, AppRoutes.personalScore);
      await tapBottom(Icons.badge_outlined, AppRoutes.howToPlay);
      await tapBottom(Icons.military_tech, AppRoutes.badges);

      navigated.clear();
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(AppStringsBn.comingSoon), findsOneWidget);
      expect(navigated, isEmpty);
      expect(find.text(AppStringsBn.navLobby), findsOneWidget);
    });

    testWidgets('daily gift claim updates UI for same day', (tester) async {
      await pumpHome(tester);

      await tester.scrollUntilVisible(
        find.text(AppStringsBn.collect),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(AppStringsBn.collect));
      await pumpFrames(tester);

      expect(gift.isClaimedToday(), isTrue);
      expect(find.text(AppStringsBn.collected), findsWidgets);
      expect(find.text(AppStringsBn.collect), findsNothing);
    });
  });
}
