import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_card.dart';
import '../../widgets/role_art.dart';
import '../../widgets/role_showcase_card.dart';

/// Redesigned Home Screen with a clean, modern party-game visual identity.
/// Features a refined floating hero emblem, sleek segmented tab switcher,
/// lightweight frosted glass card, and a compact 2x2 role grid.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 0: Create Room, 1: Join Room
  int _selectedTabIndex = 0;

  // Text Editing Controllers
  final _createNameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _joinNameController = TextEditingController();

  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _createNameController.dispose();
    _joinCodeController.dispose();
    _joinNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);

    // Listen to ViewModel errors
    ref.listen<HomeState>(homeViewModelProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        AppFeedback.showSnackBar(
          context,
          message: next.errorMessage!,
          isError: true,
        );
      }
    });

    return Scaffold(
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),

                // --- 1. Refined Hero Header ---
                _buildHeroHeader(),

                const SizedBox(height: 18),

                // --- 1.5 Pass & Play Single Phone Banner ---
                _buildPassAndPlayBanner(),

                const SizedBox(height: 18),

                // Online Multiplayer divider title
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'অথবা অনলাইন রুম (MULTI-DEVICE)',
                        style: AppTextStyles.caption(color: Colors.white54)
                            .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white12)),
                  ],
                ),

                const SizedBox(height: 12),

                // --- 2. Sleek Segmented Tab Switcher ---
                _buildSlidingTabSwitcher(),

                const SizedBox(height: 14),

                // --- 3. Clean Frosted Glass Form Card ---
                GameCard(
                  isGlass: true,
                  borderColor: Colors.white.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(AppSpacing.md + 2),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _selectedTabIndex == 0
                        ? _buildCreateRoomForm(homeState)
                        : _buildJoinRoomForm(homeState),
                  ),
                ),

                const SizedBox(height: 20),

                // --- 4. Role Showcase Header ---
                _buildRoleShowcaseHeader(),

                const SizedBox(height: 10),

                // --- 5. Compact 2x2 Role Grid ---
                _buildStaggeredRoleCards(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Refined Hero Header with subtle animated crown emblem and crisp typography.
  Widget _buildHeroHeader() {
    return Column(
      children: [
        // Floating crown emblem
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -3.0 * (1 - (value * 2 - 1).abs())),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.raja.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.raja.withValues(alpha: 0.35),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.raja.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const RoleVectorIcon(
              role: GameRole.raja,
              size: 36,
              hasGlow: false,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Brand Title
        Text(
          AppConstants.appName,
          style: AppTextStyles.heroTitle(color: AppColors.raja),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Clean Tagline
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              size: 12,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              'CHOR • POLICE • RAJA • MANTRI',
              style: AppTextStyles.caption(
                color: AppColors.textLightSecondary,
              ).copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              size: 12,
              color: AppColors.secondary,
            ),
          ],
        ),
      ],
    );
  }

  /// Dedicated Pass & Play Quick Match Banner for single-phone party play.
  Widget _buildPassAndPlayBanner() {
    return InkWell(
      onTap: () => context.go(AppRoutes.passAndPlaySetup),
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.38),
              AppColors.secondary.withValues(alpha: 0.22),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
              ),
              child: Icon(
                PhosphorIcons.deviceMobileSpeaker(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pass & Play (১ ফোনে ৪ জন)',
                        style: AppTextStyles.heading3().copyWith(fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(color: AppColors.accent, width: 0.8),
                        ),
                        child: Text(
                          'OFFLINE',
                          style: AppTextStyles.caption(color: AppColors.accent)
                              .copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'কোনো ইন্টারনেট দরকার নেই! এক ফোন হাতবদল করে ৪ বন্ধু একসাথে খেলুন।',
                    style: AppTextStyles.caption(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
              color: AppColors.primaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Sleek segmented pill tab switcher.
  Widget _buildSlidingTabSwitcher() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x35000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth) / 2;

          return Stack(
            children: [
              // Sliding Highlight Pill
              AnimatedAlign(
                alignment: _selectedTabIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: _selectedTabIndex == 0
                        ? AppColors.primaryGradient
                        : const LinearGradient(
                            colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                          ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: (_selectedTabIndex == 0
                                ? AppColors.primary
                                : AppColors.secondary)
                            .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Buttons Layer
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.plusCircle(PhosphorIconsStyle.bold),
                              size: 16,
                              color: _selectedTabIndex == 0
                                  ? Colors.white
                                  : AppColors.textLightSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'CREATE ROOM',
                              style: AppTextStyles.button(
                                color: _selectedTabIndex == 0
                                    ? Colors.white
                                    : AppColors.textLightSecondary,
                              ).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.doorOpen(PhosphorIconsStyle.bold),
                              size: 16,
                              color: _selectedTabIndex == 1
                                  ? Colors.white
                                  : AppColors.textLightSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'JOIN ROOM',
                              style: AppTextStyles.button(
                                color: _selectedTabIndex == 1
                                    ? Colors.white
                                    : AppColors.textLightSecondary,
                              ).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreateRoomForm(HomeState state) {
    return Form(
      key: _createFormKey,
      child: Column(
        key: const ValueKey('create_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.crown(PhosphorIconsStyle.fill),
                color: AppColors.raja,
                size: 18,
              ),
              AppSpacing.gapHSm,
              Text(
                'Host a Match',
                style: AppTextStyles.heading3().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Enter your name to start a new 4-player room.',
            style: AppTextStyles.caption(color: AppColors.textLightSecondary),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _createNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Your Name (Host)',
              hintText: 'e.g. Akbar, Birbal, Feluda',
              prefixIcon: Icon(
                PhosphorIcons.user(PhosphorIconsStyle.bold),
                color: AppColors.raja,
                size: 18,
              ),
            ),
            validator: Validators.validatePlayerName,
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Create Room',
            leading: Icon(
              PhosphorIcons.crown(PhosphorIconsStyle.bold),
              color: Colors.white,
              size: 18,
            ),
            isLoading: state.isLoading,
            onPressed: () async {
              if (!_createFormKey.currentState!.validate()) return;
              final room = await ref
                  .read(homeViewModelProvider.notifier)
                  .createRoom(_createNameController.text);
              if (room != null && mounted) {
                context.push(AppRoutes.lobbyPath(room.roomCode));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRoomForm(HomeState state) {
    return Form(
      key: _joinFormKey,
      child: Column(
        key: const ValueKey('join_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.shieldStar(PhosphorIconsStyle.fill),
                color: AppColors.secondary,
                size: 18,
              ),
              AppSpacing.gapHSm,
              Text(
                'Join a Match',
                style: AppTextStyles.heading3().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Enter the 6-character room code from your host.',
            style: AppTextStyles.caption(color: AppColors.textLightSecondary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _joinCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Room Code (6 characters)',
              hintText: 'e.g. ABCD12',
              prefixIcon: Icon(
                PhosphorIcons.hash(PhosphorIconsStyle.bold),
                color: AppColors.secondary,
                size: 18,
              ),
            ),
            validator: Validators.validateRoomCode,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _joinNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Your Name',
              hintText: 'e.g. Topshe, Lalmohan, Maganlal',
              prefixIcon: Icon(
                PhosphorIcons.user(PhosphorIconsStyle.bold),
                color: AppColors.secondary,
                size: 18,
              ),
            ),
            validator: Validators.validatePlayerName,
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Join Room',
            variant: ButtonVariant.secondary,
            leading: Icon(
              PhosphorIcons.doorOpen(PhosphorIconsStyle.bold),
              color: AppColors.backgroundDark,
              size: 18,
            ),
            isLoading: state.isLoading,
            onPressed: () async {
              if (!_joinFormKey.currentState!.validate()) return;
              final player = await ref
                  .read(homeViewModelProvider.notifier)
                  .joinRoom(
                    roomCode: _joinCodeController.text,
                    playerName: _joinNameController.text,
                  );
              if (player != null && mounted) {
                context.push(AppRoutes.lobbyPath(player.roomCode));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleShowcaseHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIcons.cards(PhosphorIconsStyle.bold),
              color: AppColors.raja,
              size: 16,
            ),
            AppSpacing.gapHXs,
            Text(
              'ROYAL ROLES & SCORING',
              style: AppTextStyles.caption(
                color: AppColors.textLightSecondary,
              ).copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        Text(
          '4 PLAYERS',
          style: AppTextStyles.caption(
            color: AppColors.textLightMuted,
          ).copyWith(
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  /// Compact 2x2 grid layout for royal roles.
  Widget _buildStaggeredRoleCards() {
    const roles = [
      GameRole.raja,
      GameRole.mantri,
      GameRole.police,
      GameRole.chor,
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.62,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: roles.map((role) => RoleShowcaseCard(role: role)).toList(),
    );
  }
}
