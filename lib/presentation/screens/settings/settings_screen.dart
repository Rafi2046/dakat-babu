import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../widgets/animated_living_background.dart';

/// Settings: music, sound, vibration, language, about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(playerProfileStoreProvider);

    return Scaffold(
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text('Settings', style: AppTextStyles.heading2()),
                ],
              ),
              AppSpacing.gapVLg,
              SwitchListTile(
                title: Text('Music', style: AppTextStyles.bodyLarge()),
                value: store.musicEnabled,
                onChanged: (v) async {
                  await store.setMusicEnabled(v);
                  ref.invalidate(playerProfileStoreProvider);
                },
              ),
              SwitchListTile(
                title: Text('Sound Effects', style: AppTextStyles.bodyLarge()),
                value: store.soundEnabled,
                onChanged: (v) async {
                  await store.setSoundEnabled(v);
                  // Store is same instance — force rebuild via setState pattern:
                  (context as Element).markNeedsBuild();
                },
              ),
              SwitchListTile(
                title: Text('Vibration', style: AppTextStyles.bodyLarge()),
                value: store.vibrationEnabled,
                onChanged: (v) async {
                  await store.setVibrationEnabled(v);
                  (context as Element).markNeedsBuild();
                },
              ),
              SwitchListTile(
                title: Text('Notifications', style: AppTextStyles.bodyLarge()),
                value: store.notificationsEnabled,
                onChanged: (v) async {
                  await store.setNotificationsEnabled(v);
                  (context as Element).markNeedsBuild();
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                title: Text('Game Rules', style: AppTextStyles.bodyLarge()),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => context.push('/how-to-play'),
              ),
              ListTile(
                title: Text('About', style: AppTextStyles.bodyLarge()),
                subtitle: Text('Chor Police Dakat Babu v1.0.0',
                    style: AppTextStyles.caption()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
