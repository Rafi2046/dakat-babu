import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/di/providers.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/supabase_service.dart';

/// Entry point for DakatBabu multiplayer game.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend service with graceful local fallback
  final supabaseService = SupabaseService();
  await supabaseService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        supabaseServiceProvider.overrideWithValue(supabaseService),
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
