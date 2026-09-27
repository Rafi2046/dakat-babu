import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings_bn.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/game/badge_catalog.dart';
import '../../widgets/cpdb/app_shell.dart';
import '../../widgets/home/home_bottom_nav.dart';
import '../../widgets/home/home_career_stats.dart';
import '../../widgets/home/home_daily_gift_banner.dart';
import '../../widgets/home/home_featured_game_card.dart';
import '../../widgets/home/home_mode_card.dart';
import '../../widgets/home/home_profile_header.dart';
import '../../widgets/settings/settings_bottom_sheet.dart';
import '../../widgets/shop/shop_coming_soon_view.dart';

/// Home hub — dark Bangla lobby composed from section widgets.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HomeNavTab _selectedTab = HomeNavTab.lobby;

  bool _giftClaimed = false;

  @override
  void initState() {
    super.initState();
    _giftClaimed = ref.read(homeDailyGiftStoreProvider).isClaimedToday();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(audioManagerProvider).play(AudioEvent.homeTheme);
    });
  }

  int _badgeCount() {
    final store = ref.read(playerProfileStoreProvider);
    final progress = BadgeProgress(
      correctGuesses: store.correctGuesses,
      policeTags: store.policeTags,
      gamesPlayed: store.gamesPlayed,
      wins: store.wins,
      bestStreak: store.bestStreak,
      highestScore: store.highestScore,
    );
    final unlocked = store.unlockedBadgeIds;
    return BadgeCatalog.all
        .where((b) => unlocked.contains(b.id) || b.isUnlocked(progress))
        .length;
  }

  int _policeWinPercent() {
    final store = ref.read(playerProfileStoreProvider);
    if (store.gamesPlayed <= 0) return 0;
    return ((store.wins / store.gamesPlayed) * 100).round();
  }

  Future<void> _onCollectGift() async {
    final audio = ref.read(audioManagerProvider);
    await audio.play(AudioEvent.coinSoft);
    final gift = ref.read(homeDailyGiftStoreProvider);
    await gift.claimToday();
    if (!mounted) return;
    setState(() => _giftClaimed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStringsBn.collected)),
    );
  }

  void _onNav(HomeNavTab tab) {
    final audio = ref.read(audioManagerProvider);
    audio.play(AudioEvent.navigationWhoosh);
    switch (tab) {
      case HomeNavTab.lobby:
        setState(() => _selectedTab = HomeNavTab.lobby);
        return;
      case HomeNavTab.rank:
        context.push(AppRoutes.personalScore);
        return;
      case HomeNavTab.role:
        context.push(AppRoutes.howToPlay);
        return;
      case HomeNavTab.badge:
        context.push(AppRoutes.badges);
        return;
      case HomeNavTab.shop:
        setState(() => _selectedTab = HomeNavTab.shop);
        return;
    }
  }

  void _openMode(String route) {
    ref.read(audioManagerProvider).play(AudioEvent.cardTap);
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(playerProfileStoreProvider);
    final audioSettings = ref.watch(audioSettingsProvider);
    final level = (profile.gamesPlayed ~/ 3) + 1;
    final coins = profile.highestScore * 10;
    final audio = ref.read(audioManagerProvider);

    return AppShell(
      padding: EdgeInsets.zero,
      bottomNavigation: HomeBottomNav(
        selected: _selectedTab,
        onSelect: _onNav,
      ),
      body: _selectedTab == HomeNavTab.shop
          ? const Padding(
              padding: AppSpacing.screenPadding,
              child: ShopComingSoonView(),
            )
          : ListView(
              padding: AppSpacing.screenPadding,
              children: [
                HomeProfileHeader(
                  playerName: profile.playerName,
                  level: level,
                  coins: coins,
                  soundEnabled: audioSettings.isSfxOn,
                  onToggleSound: () async {
                    final next = !audioSettings.isSfxOn;
                    await ref
                        .read(audioSettingsProvider.notifier)
                        .setSfxOn(next);
                    if (next) {
                      await audio.play(AudioEvent.toggleClick);
                    } else {
                      await audio.stopSfx();
                    }
                  },
                  onSettings: () {
                    audio.play(AudioEvent.buttonTap);
                    SettingsBottomSheet.show(context);
                  },
                ),
                AppSpacing.gapVMd,
                const HomeFeaturedGameCard(),
                AppSpacing.gapVMd,
                HomeCareerStats(
                  highestScore: profile.highestScore,
                  policeWinPercent: _policeWinPercent(),
                  badgeCount: _badgeCount(),
                ),
                AppSpacing.gapVMd,
                HomeModeCard(
                  title: AppStringsBn.playOnline,
                  tag: AppStringsBn.rankedTag,
                  subtitle: AppStringsBn.playOnlineSub,
                  meta: AppStringsBn.searchingStub,
                  icon: Icons.public_rounded,
                  color: AppColors.homeOnline,
                  deepColor: AppColors.homeOnlineDeep,
                  onTap: () => _openMode(AppRoutes.createJoin),
                ),
                AppSpacing.gapVSm,
                HomeModeCard(
                  title: AppStringsBn.playMultiplayer,
                  tag: AppStringsBn.roomTag,
                  subtitle: AppStringsBn.playMultiplayerSub,
                  meta: AppStringsBn.playMultiplayerMeta,
                  icon: Icons.groups_rounded,
                  color: AppColors.homeMultiplayer,
                  deepColor: AppColors.homeMultiplayerDeep,
                  onTap: () => _openMode(AppRoutes.modeSelect),
                ),
                AppSpacing.gapVSm,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: HomeModeCard.half(
                        title: AppStringsBn.withComputer,
                        subtitle: AppStringsBn.withComputerSub,
                        meta: AppStringsBn.noInternet,
                        icon: Icons.smart_toy_rounded,
                        color: AppColors.homeRobot,
                        deepColor: AppColors.homeRobotDeep,
                        onTap: () => _openMode(AppRoutes.robot),
                      ),
                    ),
                    AppSpacing.gapHSm,
                    Expanded(
                      child: HomeModeCard.half(
                        title: AppStringsBn.passAndPlay,
                        subtitle: AppStringsBn.passAndPlaySub,
                        meta: AppStringsBn.secretChits,
                        icon: Icons.phone_android_rounded,
                        color: AppColors.homePassPlay,
                        deepColor: AppColors.homePassPlayDeep,
                        onTap: () => _openMode(AppRoutes.passAndPlaySetup),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapVMd,
                HomeDailyGiftBanner(
                  claimed: _giftClaimed,
                  onCollect: _onCollectGift,
                ),
                AppSpacing.gapVLg,
              ],
            ),
    );
  }
}
