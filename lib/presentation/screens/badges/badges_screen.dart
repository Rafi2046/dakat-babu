import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../domain/game/badge_catalog.dart';
import '../../widgets/cpdb/cpdb.dart';

/// Badge collection using [BadgeCard].
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(playerProfileStoreProvider);
    final unlocked = store.unlockedBadgeIds;
    final progress = BadgeProgress(
      correctGuesses: store.correctGuesses,
      policeTags: store.policeTags,
      gamesPlayed: store.gamesPlayed,
      wins: store.wins,
      bestStreak: store.bestStreak,
      highestScore: store.highestScore,
    );

    final newly = BadgeCatalog.evaluateNewUnlocks(
      progress: progress,
      alreadyUnlocked: unlocked,
    );
    for (final id in newly) {
      store.unlockBadge(id);
    }
    final allUnlocked = {...unlocked, ...newly};

    return AppShell(
      padding: EdgeInsets.zero,
      topBar: TopBar(
        title: 'Badges',
        onBack: () => context.pop(),
        showProfile: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: BadgeCatalog.all.length,
        itemBuilder: (context, index) {
          final badge = BadgeCatalog.all[index];
          final isOn =
              allUnlocked.contains(badge.id) || badge.isUnlocked(progress);
          return BadgeCard(
            name: badge.name,
            description: badge.description,
            iconAsset: badge.iconAsset,
            unlocked: isOn,
          );
        },
      ),
    );
  }
}
