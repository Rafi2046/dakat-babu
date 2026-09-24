import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../domain/game/badge_catalog.dart';
import '../../widgets/animated_living_background.dart';

/// Badge collection grid.
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

    // Auto-evaluate unlocks when opening.
    final newly = BadgeCatalog.evaluateNewUnlocks(
      progress: progress,
      alreadyUnlocked: unlocked,
    );
    for (final id in newly) {
      store.unlockBadge(id);
    }
    final allUnlocked = {...unlocked, ...newly};

    return Scaffold(
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: AppSpacing.screenPadding,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text('Badges', style: AppTextStyles.heading2()),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: AppSpacing.screenPadding,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: BadgeCatalog.all.length,
                  itemBuilder: (context, index) {
                    final badge = BadgeCatalog.all[index];
                    final isOn = allUnlocked.contains(badge.id) ||
                        badge.isUnlocked(progress);
                    return Opacity(
                      opacity: isOn ? 1 : 0.35,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOn ? Colors.amber : Colors.white24,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.asset(
                                badge.iconAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  isOn ? Icons.emoji_events : Icons.lock,
                                  size: 48,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            Text(
                              badge.name,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium(),
                            ),
                            Text(
                              badge.description,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
