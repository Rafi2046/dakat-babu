import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/home_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../tactile_menu_button.dart';

/// Premium tactile settings sheet — Music, SFX, and theme toggle.
class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final audio = ref.watch(audioSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode != ThemeMode.light;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: AppSpacing.screenPadding,
        decoration: AppTheme.embossedPanel(
          brightness,
          accent: AppColors.secondary,
          radius: 24,
        ).copyWith(
          color: brightness == Brightness.dark
              ? AppColors.surfaceElevatedDark
              : AppColors.embossFaceLight,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLightMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.gapVMd,
              Text(
                'Settings',
                textAlign: TextAlign.center,
                style: HomeTextStyles.hero(
                  color: brightness == Brightness.dark
                      ? AppColors.textLightPrimary
                      : AppColors.textDarkPrimary,
                ),
              ),
              AppSpacing.gapVLg,
              _TactileToggleRow(
                label: 'Music',
                icon: Icons.music_note_rounded,
                value: audio.isMusicOn,
                accent: AppColors.primary,
                onChanged: (v) async {
                  await ref.read(audioSettingsProvider.notifier).setMusicOn(v);
                  final mgr = ref.read(audioManagerProvider);
                  if (v) {
                    await mgr.play(AudioEvent.toggleClick);
                    await mgr.play(AudioEvent.homeTheme);
                  } else {
                    await mgr.stopMusic();
                  }
                },
              ),
              AppSpacing.gapVMd,
              _TactileToggleRow(
                label: 'Sound Effects',
                icon: Icons.graphic_eq_rounded,
                value: audio.isSfxOn,
                accent: AppColors.secondary,
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
              AppSpacing.gapVMd,
              _TactileToggleRow(
                label: isDark ? 'Dark Mode' : 'Light Mode',
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                value: isDark,
                accent: AppColors.accent,
                onChanged: (_) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
              AppSpacing.gapVLg,
              TactileMenuButton(
                text: 'Done',
                icon: Icons.check_rounded,
                accentColor: AppColors.homeOnline,
                onTap: () => Navigator.of(context).pop(),
              ),
              AppSpacing.gapVSm,
            ],
          ),
        ),
      ),
    );
  }
}

class _TactileToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _TactileToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.embossWellLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? accent.withValues(alpha: 0.45)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        boxShadow: value
            ? AppColors.tactileGlow(brightness, accent)
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: HomeTextStyles.body(
                color: isDark
                    ? AppColors.textLightPrimary
                    : AppColors.textDarkPrimary,
              ),
            ),
          ),
          _TactileSwitch(
            value: value,
            accent: accent,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

/// 3D embossed toggle switch.
class _TactileSwitch extends StatelessWidget {
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _TactileSwitch({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value ? accent.withValues(alpha: 0.35) : AppColors.borderDark,
          border: Border.all(
            color: value ? accent : AppColors.borderDark,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: value
                  ? accent.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: value ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: value
                    ? [accent, Color.lerp(accent, Colors.black, 0.25)!]
                    : [const Color(0xFFE2E8F0), const Color(0xFF94A3B8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
