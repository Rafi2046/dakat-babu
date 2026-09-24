import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../widgets/animated_living_background.dart';

/// Personal career statistics.
class PersonalScoreScreen extends ConsumerWidget {
  const PersonalScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(playerProfileStoreProvider);
    final winRate = p.gamesPlayed == 0
        ? 0
        : ((p.wins / p.gamesPlayed) * 100).round();

    final cards = [
      ('Games Played', '${p.gamesPlayed}'),
      ('Correct Guess', '${p.correctGuesses}'),
      ('Police Tag', '${p.policeTags}'),
      ('Highest Score', '${p.highestScore}'),
      ('Win Rate', '$winRate%'),
      ('Best Streak', '${p.bestStreak}'),
    ];

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
                    Text('My Profile', style: AppTextStyles.heading2()),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: AppSpacing.screenPadding,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    for (final c in cards)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(c.$2, style: AppTextStyles.heading1()),
                            Text(c.$1, style: AppTextStyles.bodyMedium()),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
