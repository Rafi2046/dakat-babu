import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_card.dart';
import '../../widgets/role_badge.dart';

/// The primary landing screen of DakatBabu.
///
/// Features inline "Create Room" and "Join Room" forms with direct inputs
/// and real-time room navigation.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTabIndex = 0; // 0 = Create Room, 1 = Join Room

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
    ref.listen<HomeState>(homeViewModelProvider, (prev, current) {
      if (current.errorMessage != null &&
          current.errorMessage != prev?.errorMessage) {
        context.showErrorSnackBar(current.errorMessage!);
      }
    });

    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppSpacing.gapVLg,

                // --- Game Brand Hero ---
                Container(
                  padding: AppSpacing.paddingAllMd,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.military_tech_rounded,
                    size: 60,
                    color: AppColors.raja,
                  ),
                ),
                AppSpacing.gapVSm,

                Text(
                  AppConstants.appName,
                  style: AppTextStyles.heading1(color: AppColors.raja),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapVXs,
                Text(
                  AppConstants.appTagline,
                  style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
                  textAlign: TextAlign.center,
                ),

                AppSpacing.gapVLg,

                // --- Mode Selector Tabs ---
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: AppRadius.buttonRadius,
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'CREATE ROOM',
                          icon: Icons.add_circle_outline,
                          isSelected: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'JOIN ROOM',
                          icon: Icons.meeting_room_outlined,
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapVMd,

                // --- Active Form Card with Inputs ---
                GameCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _selectedTabIndex == 0
                        ? _buildCreateRoomForm(state)
                        : _buildJoinRoomForm(state),
                  ),
                ),

                AppSpacing.gapVXl,

                // --- Traditional Roles Showcase ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ROLES & RULES',
                    style: AppTextStyles.heading3(color: AppColors.textLightSecondary),
                  ),
                ),
                AppSpacing.gapVSm,

                const GameCard(
                  child: Column(
                    children: [
                      RoleBadge(role: GameRole.raja, isCompact: false),
                      AppSpacing.gapVSm,
                      RoleBadge(role: GameRole.mantri, isCompact: false),
                      AppSpacing.gapVSm,
                      RoleBadge(role: GameRole.police, isCompact: false),
                      AppSpacing.gapVSm,
                      RoleBadge(role: GameRole.chor, isCompact: false),
                    ],
                  ),
                ),
                AppSpacing.gapVLg,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateRoomForm(HomeState state) {
    return Form(
      key: _createFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Host a New Match',
            style: AppTextStyles.heading3(),
          ),
          AppSpacing.gapVXs,
          Text(
            'Create a 4-player room and invite your friends.',
            style: AppTextStyles.caption(color: AppColors.textLightSecondary),
          ),
          AppSpacing.gapVMd,
          TextFormField(
            controller: _createNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your Name (Host)',
              hintText: 'e.g. Akbar, Birbal, Feluda',
              prefixIcon: Icon(Icons.person, color: AppColors.raja),
            ),
            validator: Validators.validatePlayerName,
          ),
          AppSpacing.gapVLg,
          CustomButton(
            label: 'CREATE ROOM',
            icon: Icons.add_circle,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Join an Existing Room',
            style: AppTextStyles.heading3(),
          ),
          AppSpacing.gapVXs,
          Text(
            'Enter the 6-character room code from your host.',
            style: AppTextStyles.caption(color: AppColors.textLightSecondary),
          ),
          AppSpacing.gapVMd,
          TextFormField(
            controller: _joinCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Room Code (6 characters)',
              hintText: 'e.g. ABCD12',
              prefixIcon: Icon(Icons.tag, color: AppColors.secondary),
            ),
            validator: Validators.validateRoomCode,
          ),
          AppSpacing.gapVMd,
          TextFormField(
            controller: _joinNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              hintText: 'e.g. Topshe, Lalmohan, Maganlal',
              prefixIcon: Icon(Icons.person_outline, color: AppColors.secondary),
            ),
            validator: Validators.validatePlayerName,
          ),
          AppSpacing.gapVLg,
          CustomButton(
            label: 'JOIN ROOM',
            variant: ButtonVariant.secondary,
            icon: Icons.login,
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
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: AppRadius.buttonRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textLightSecondary,
              ),
              AppSpacing.gapHSm,
              Text(
                label,
                style: AppTextStyles.button(
                  color: isSelected ? Colors.white : AppColors.textLightSecondary,
                ).copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
