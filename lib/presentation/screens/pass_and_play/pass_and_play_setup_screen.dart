import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../viewmodels/pass_and_play_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_card.dart';

/// Screen where 4 local players configure their names and round count
/// before beginning a Pass & Play match on a single device.
class PassAndPlaySetupScreen extends ConsumerStatefulWidget {
  const PassAndPlaySetupScreen({super.key});

  @override
  ConsumerState<PassAndPlaySetupScreen> createState() =>
      _PassAndPlaySetupScreenState();
}

class _PassAndPlaySetupScreenState
    extends ConsumerState<PassAndPlaySetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late final List<TextEditingController> _nameControllers;
  int _selectedRounds = 5;
  int _playerCount = 4;

  @override
  void initState() {
    super.initState();
    _nameControllers = List.generate(
      6,
      (i) => TextEditingController(text: 'Player ${i + 1}'),
    );
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onStartMatch() {
    if (!_formKey.currentState!.validate()) return;

    final names = _nameControllers
        .take(_playerCount)
        .map((c) => c.text.trim())
        .toList();

    ref.read(passAndPlayViewModelProvider.notifier).initMatch(
          playerNames: names,
          totalRounds: _selectedRounds,
        );

    context.go(AppRoutes.passAndPlayGame);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Pass & Play Setup', style: AppTextStyles.heading2()),
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.sm,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Header Badge Banner
                  GameCard(
                    isGlass: true,
                    borderColor: AppColors.primary.withValues(alpha: 0.3),
                    glowColor: AppColors.primaryGlow,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.deviceMobileCamera(PhosphorIconsStyle.fill),
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '১ ফোনে ৪ বন্ধু (Offline)',
                                style: AppTextStyles.heading3().copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'No internet required. Pass phone between players to check secret roles!',
                                style: AppTextStyles.caption(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Player Count Selector
                  GameCard(
                    isGlass: true,
                    borderColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.users(PhosphorIconsStyle.fill),
                              color: AppColors.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'খেলোয়াড়ের সংখ্যা (Player Count)',
                              style: AppTextStyles.heading3().copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [4, 5, 6].map((count) {
                            final isSelected = _playerCount == count;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => setState(() => _playerCount = count),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.25)
                                          : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.white.withValues(alpha: 0.1),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$count Players',
                                          style: AppTextStyles.bodyMedium(
                                            color: isSelected
                                                ? AppColors.primaryLight
                                                : AppColors.textLightSecondary,
                                          ).copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          count == 4
                                              ? 'Classic 4'
                                              : (count == 5 ? '+ Chintaykari' : '+ Batpar'),
                                          style: AppTextStyles.caption(
                                            color: isSelected
                                                ? AppColors.primaryLight.withValues(alpha: 0.8)
                                                : AppColors.textLightSecondary.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Player Names Card
                  GameCard(
                    isGlass: true,
                    borderColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(AppSpacing.md + 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.usersFour(PhosphorIconsStyle.fill),
                              color: AppColors.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_playerCount জন খেলোয়াড়ের নাম',
                              style: AppTextStyles.heading3().copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        ...List.generate(_playerCount, (index) {
                          final playerNumber = index + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _nameControllers[index],
                              style: AppTextStyles.bodyLarge(),
                              decoration: InputDecoration(
                                prefixIcon: Container(
                                  width: 36,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      '$playerNumber',
                                      style: AppTextStyles.caption(
                                        color: AppColors.primaryLight,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                hintText: 'Player $playerNumber Name',
                                filled: true,
                                fillColor: const Color(0x18FFFFFF),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.buttonRadius,
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.buttonRadius,
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.buttonRadius,
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryLight,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter a name for Player $playerNumber';
                                }
                                return null;
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rounds Selection Card
                  GameCard(
                    isGlass: true,
                    borderColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.arrowsCounterClockwise(PhosphorIconsStyle.bold),
                              color: AppColors.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'মোট রাউন্ড সংখ্যা',
                              style: AppTextStyles.heading3().copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [3, 5, 10].map((rounds) {
                            final isSelected = _selectedRounds == rounds;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedRounds = rounds),
                                  borderRadius: AppRadius.cardRadius,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.35)
                                          : const Color(0x15FFFFFF),
                                      borderRadius: AppRadius.cardRadius,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryLight
                                            : Colors.white.withValues(alpha: 0.1),
                                        width: isSelected ? 1.8 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$rounds',
                                          style: AppTextStyles.heading2(
                                            color: isSelected
                                                ? AppColors.primaryLight
                                                : Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          'Rounds',
                                          style: AppTextStyles.caption(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Start Match Button
                  CustomButton(
                    label: 'Start Pass & Play Match',
                    leading: Icon(
                      PhosphorIcons.play(PhosphorIconsStyle.fill),
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _onStartMatch,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
