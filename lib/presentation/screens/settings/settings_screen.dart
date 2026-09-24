import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/cpdb/cpdb.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(playerProfileStoreProvider);

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
          SwitchListTile(
            title: Text('Music', style: AppTextStyles.bodyLarge()),
            value: store.musicEnabled,
            onChanged: (v) async {
              await store.setMusicEnabled(v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text('Sound Effects', style: AppTextStyles.bodyLarge()),
            value: store.soundEnabled,
            onChanged: (v) async {
              await store.setSoundEnabled(v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text('Vibration', style: AppTextStyles.bodyLarge()),
            value: store.vibrationEnabled,
            onChanged: (v) async {
              await store.setVibrationEnabled(v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text('Notifications', style: AppTextStyles.bodyLarge()),
            value: store.notificationsEnabled,
            onChanged: (v) async {
              await store.setNotificationsEnabled(v);
              setState(() {});
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
