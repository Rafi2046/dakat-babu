import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/di/providers.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/local/home_daily_gift_store.dart';
import 'data/local/player_profile_store.dart';
import 'data/services/supabase_service.dart';

/// Entry point for Chor Police Dakat Babu.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Warm Bangla font so Home does not flash fallback glyphs on cold start.
  GoogleFonts.notoSansBengali();
  GoogleFonts.notoSansBengali(fontWeight: FontWeight.w500);
  GoogleFonts.notoSansBengali(fontWeight: FontWeight.w600);
  GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700);
  GoogleFonts.notoSansBengali(fontWeight: FontWeight.w800);
  await GoogleFonts.pendingFonts();

  final prefs = await SharedPreferences.getInstance();
  final profileStore = PlayerProfileStore(prefs);
  final dailyGiftStore = HomeDailyGiftStore(prefs);

  final supabaseService = SupabaseService();
  await supabaseService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        supabaseServiceProvider.overrideWithValue(supabaseService),
        playerProfileStoreProvider.overrideWithValue(profileStore),
        homeDailyGiftStoreProvider.overrideWithValue(dailyGiftStore),
      ],
      child: const DakatBabuApp(),
    ),
  );
}

/// Root widget configuring theme, router, and state management.
class DakatBabuApp extends ConsumerWidget {
  const DakatBabuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
