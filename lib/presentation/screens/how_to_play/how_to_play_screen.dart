import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/animated_living_background.dart';

/// Six-step how-to-play tutorial.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _steps = [
    ('1. Roll', 'Game Lead (then Police) starts the round.'),
    ('2. Roles', 'Police, Babu, Chor, Dakat are dealt privately.'),
    ('3. Reveal', 'Pass the phone — each player peeks their role.'),
    ('4. Identify', 'Everyone sees Police & Babu. Chor/Dakat stay hidden.'),
    ('5. Guess', 'Police picks a suspect — only Chor is correct.'),
    ('6. Score', 'Correct: Police +1. Wrong: suspect +1. Next round!'),
  ];

  @override
  Widget build(BuildContext context) {
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
                  Text('How to Play', style: AppTextStyles.heading2()),
                ],
              ),
              AppSpacing.gapVLg,
              for (final step in _steps)
                Card(
                  color: Colors.white10,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(step.$1, style: AppTextStyles.heading3()),
                    subtitle: Text(step.$2, style: AppTextStyles.bodyMedium()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
