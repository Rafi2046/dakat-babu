import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../widgets/cpdb/cpdb.dart';
import '../../widgets/settings/settings_bottom_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(playerProfileStoreProvider);
    final audio = ref.watch(audioSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return AppShell(
      padding: EdgeInsets.zero,
      topBar: TopBar(
        title: 'Settings',
        onBack: () => context.pop(),
        showProfile: false,
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          ListTile(
            title: Text('Quick Audio & Theme', style: AppTextStyles.bodyLarge()),
            subtitle: Text(
              'Music · SFX · Light/Dark',
              style: AppTextStyles.caption(),
            ),
            trailing: const Icon(Icons.tune_rounded, color: Colors.white54),
            onTap: () => SettingsBottomSheet.show(context),
          ),
          SwitchListTile(
            title: Text('Music', style: AppTextStyles.bodyLarge()),
            value: audio.isMusicOn,
            onChanged: (v) async {
              await ref.read(audioSettingsProvider.notifier).setMusicOn(v);
              final mgr = ref.read(audioManagerProvider);
              await mgr.play(AudioEvent.toggleClick);
              if (!v) {
                await mgr.stopMusic();
              } else {
                await mgr.play(AudioEvent.homeTheme);
              }
            },
          ),
          SwitchListTile(
            title: Text('Sound Effects', style: AppTextStyles.bodyLarge()),
            value: audio.isSfxOn,
            onChanged: (v) async {
              await ref.read(audioSettingsProvider.notifier).setSfxOn(v);
              final mgr = ref.read(audioManagerProvider);
              if (v) {
                await mgr.play(AudioEvent.toggleClick);
              } else {
                await mgr.stopSfx();
              }
            },
          ),
          SwitchListTile(
            title: Text('Dark Mode', style: AppTextStyles.bodyLarge()),
            value: themeMode != ThemeMode.light,
            onChanged: (_) {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          SwitchListTile(
            title: Text('Vibration', style: AppTextStyles.bodyLarge()),
            value: store.vibrationEnabled,
            onChanged: (v) async {
              await store.setVibrationEnabled(v);
            },
          ),
          SwitchListTile(
            title: Text('Notifications', style: AppTextStyles.bodyLarge()),
            value: store.notificationsEnabled,
            onChanged: (v) async {
              await store.setNotificationsEnabled(v);
            },
          ),
          SwitchListTile(
            title: Text(
              locale.languageCode == 'bn' ? 'বাংলা / EN' : 'EN / বাংলা',
              style: AppTextStyles.bodyLarge(),
            ),
            value: locale.languageCode == 'bn',
            onChanged: (_) {
              ref.read(localeProvider.notifier).toggleLocale();
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            title: Text('Game Rules', style: AppTextStyles.bodyLarge()),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => context.push(AppRoutes.howToPlay),
          ),
          ListTile(
            title: Text('About', style: AppTextStyles.bodyLarge()),
            subtitle: Text(
              'Chor Police Dakat Babu v1.0.0',
              style: AppTextStyles.caption(),
            ),
          ),
        ],
      ),
    );
  }
}
