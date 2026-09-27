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

/// Home hub — dark Bangla lobby composed from section widgets.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Always lobby while this screen is visible (deterministic).
  static const HomeNavTab _selectedTab = HomeNavTab.lobby;

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

  @override
  void dispose() {
    // Fire-and-forget stop; provider may outlive this screen.
    ref.read(audioManagerProvider).stopMusic();
    super.dispose();
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
    final gift = ref.read(homeDailyGiftStoreProvider);
    await gift.claimToday();
    if (!mounted) return;
    setState(() => _giftClaimed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStringsBn.collected)),
    );
  }

  void _onNav(HomeNavTab tab) {
    switch (tab) {
      case HomeNavTab.lobby:
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStringsBn.comingSoon)),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(playerProfileStoreProvider);
    final level = (profile.gamesPlayed ~/ 3) + 1;
    final coins = profile.highestScore * 10;

    return AppShell(
      padding: EdgeInsets.zero,
      bottomNavigation: HomeBottomNav(
        selected: _selectedTab,
        onSelect: _onNav,
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          HomeProfileHeader(
            playerName: profile.playerName,
            level: level,
            coins: coins,
            soundEnabled: profile.soundEnabled,
            onToggleSound: () async {
              await profile.setSoundEnabled(!profile.soundEnabled);
              if (mounted) setState(() {});
            },
            onSettings: () => context.push(AppRoutes.settings),
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
            onTap: () => context.push(AppRoutes.createJoin),
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
            onTap: () => context.push(AppRoutes.modeSelect),
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
                  onTap: () => context.push(AppRoutes.robot),
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
                  onTap: () => context.push(AppRoutes.passAndPlaySetup),
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
