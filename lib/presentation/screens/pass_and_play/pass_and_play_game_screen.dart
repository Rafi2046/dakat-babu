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
import '../../../core/utils/extensions.dart';
import '../../viewmodels/pass_and_play_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/flip_role_card.dart';
import '../../widgets/game_card.dart';
import '../../widgets/role_badge.dart';

/// Interactive Game Screen coordinating all Pass & Play stages:
/// passing phone, confidential peeking, police siren reveal,
/// interrogation/accusation, round outcomes, and final winner podium.
class PassAndPlayGameScreen extends ConsumerStatefulWidget {
  const PassAndPlayGameScreen({super.key});

  @override
  ConsumerState<PassAndPlayGameScreen> createState() =>
      _PassAndPlayGameScreenState();
}

class _PassAndPlayGameScreenState
    extends ConsumerState<PassAndPlayGameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sirenController;

  @override
  void initState() {
    super.initState();
    _sirenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sirenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passAndPlayViewModelProvider);
    final notifier = ref.read(passAndPlayViewModelProvider.notifier);

    // If navigated without players, redirect home
    if (state.players.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.home);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showQuitDialog(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            state.stage == PassAndPlayStage.matchOver
                ? 'Match Winner'
                : 'Round ${state.currentRound} of ${state.totalRounds}',
            style: AppTextStyles.heading2(),
          ),
          leading: IconButton(
            icon: Icon(PhosphorIcons.door(PhosphorIconsStyle.bold)),
            tooltip: 'Quit Match',
            onPressed: () => _showQuitDialog(context),
          ),
        ),
        body: AnimatedLivingBackground(
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStageContent(state, notifier),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageContent(
    PassAndPlayState state,
    PassAndPlayViewModel notifier,
  ) {
    switch (state.stage) {
      case PassAndPlayStage.passToPlayer:
        return _buildPassToPlayerView(state, notifier);
      case PassAndPlayStage.peekRole:
        return _buildPeekRoleView(state, notifier);
      case PassAndPlayStage.handToPolice:
        return _buildHandToPoliceView(state, notifier);
      case PassAndPlayStage.policeAccusing:
        return _buildPoliceAccusingView(state, notifier);
      case PassAndPlayStage.roundResults:
        return _buildRoundResultsView(state, notifier);
      case PassAndPlayStage.matchOver:
        return _buildMatchOverView(state, notifier);
    }
  }

  // ===========================================================================
  // STAGE 1: PASS PHONE TO CURRENT PLAYER
  // ===========================================================================
  Widget _buildPassToPlayerView(
    PassAndPlayState state,
    PassAndPlayViewModel notifier,
  ) {
    final currentPlayer = state.currentPeekingPlayer;
    final playerIndex = state.currentPeekIndex + 1;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: AppRadius.pillRadius,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Player $playerIndex of ${state.players.length}',
                style: AppTextStyles.caption(color: AppColors.primaryLight)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Pulsing Phone Graphic
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                PhosphorIcons.deviceMobileSpeaker(PhosphorIconsStyle.fill),
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'ফোনটি হাতে দিন',
              style: AppTextStyles.heading3(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              currentPlayer?.name ?? 'Player',
              style: AppTextStyles.heading1(color: AppColors.primaryLight)
                  .copyWith(fontSize: 32, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x18FFFFFF),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'অন্য কেউ যেন স্ক্রিন দেখতে না পারে!',
                      style: AppTextStyles.caption(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            CustomButton(
              label: 'I am ${currentPlayer?.name} — View Card',
              leading: Icon(
                PhosphorIcons.cards(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 20,
              ),
              onPressed: notifier.readyToPeek,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STAGE 2: PEEK SECRET ROLE CARD (WITH POLICE SIREN)
  // ===========================================================================
  Widget _buildPeekRoleView(
    PassAndPlayState state,
    PassAndPlayViewModel notifier,
  ) {
    final currentPlayer = state.currentPeekingPlayer;
    final isPolice = currentPlayer?.role == GameRole.police;
    final isRaja = currentPlayer?.role == GameRole.raja;
    final isRevealed = state.isCardRevealed;
    final isLastPlayer = state.currentPeekIndex == state.players.length - 1;
    final nextIndex = state.currentPeekIndex + 1;
    final nextPlayer = nextIndex < state.players.length ? state.players[nextIndex] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Player identity badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x25FFFFFF),
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.user(PhosphorIconsStyle.bold),
                    size: 16,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Viewing: ${currentPlayer?.name}',
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3D Flip Role Card
          FlipRoleCard(
            key: ValueKey('flip_card_${currentPlayer?.id}_round_${state.currentRound}'),
            role: currentPlayer?.role,
            isRevealed: isRevealed,
            onToggle: notifier.toggleCardReveal,
          ),
          const SizedBox(height: 16),

          // --- POLICE SIREN ALERT BANNER (If Police is unmasked) ---
          if (isRevealed && isPolice)
            AnimatedBuilder(
              animation: _sirenController,
              builder: (context, child) {
                final glow = _sirenController.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFF1E3A8A),
                      const Color(0xFF991B1B),
                      glow,
                    )!.withValues(alpha: 0.55),
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: Color.lerp(
                        const Color(0xFF60A5FA),
                        const Color(0xFFF87171),
                        glow,
                      )!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(
                          Colors.blueAccent,
                          Colors.redAccent,
                          glow,
                        )!.withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIcons.siren(PhosphorIconsStyle.fill),
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '🚨 আপনি পুলিশ (POLICE)!',
                            style: AppTextStyles.heading2(color: Colors.white)
                                .copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'সবাইকে বলুন: "আমি পুলিশ!" টেবিলে থাকা সবাই এখন জানবে আপনি পুলিশ।',
                        style: AppTextStyles.bodyMedium(color: Colors.white)
                            .copyWith(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            )
          else if (isRevealed && isRaja)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.raja.withValues(alpha: 0.2),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.raja, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.rajaGlow,
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.crown(PhosphorIconsStyle.fill),
                        color: AppColors.raja,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '👑 আপনি রাজা (RAJA)!',
                        style: AppTextStyles.heading2(color: AppColors.raja)
                            .copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'সবাইকে ঘোষণা দিন: "আমি রাজা!" আপনার ১০০০ পয়েন্ট নিশ্চিত।',
                    style: AppTextStyles.bodyMedium(color: Colors.white70)
                        .copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Dynamic Action Button (Never disabled)
          if (!isRevealed)
            CustomButton(
              label: 'ট্যাপ করে রোল দেখুন (Reveal Role)',
              variant: ButtonVariant.primary,
              leading: Icon(
                PhosphorIcons.eye(PhosphorIconsStyle.bold),
                color: Colors.white,
                size: 20,
              ),
              onPressed: notifier.toggleCardReveal,
            )
          else ...[
            CustomButton(
              label: isLastPlayer
                  ? 'দেখা শেষ, ফোন পুলিশের হাতে দিন 🚨'
                  : 'হাইড করে ${nextPlayer?.name ?? "পরের জনকে"}-কে দিন ➔',
              variant: ButtonVariant.primary,
              leading: Icon(
                isLastPlayer
                    ? PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill)
                    : PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                color: Colors.white,
                size: 20,
              ),
              onPressed: notifier.finishPeekingCurrentPlayer,
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'রোল মনে রাখুন এবং হাইড করে পরের জনকে দিন',
                style: AppTextStyles.caption(color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // STAGE 3: HAND PHONE TO POLICE
  // ===========================================================================
  Widget _buildHandToPoliceView(
    PassAndPlayState state,
    PassAndPlayViewModel notifier,
  ) {
    final police = state.policePlayer;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flashing Police Badge
            AnimatedBuilder(
              animation: _sirenController,
              builder: (context, child) {
                return Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF38BDF8),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(
                          alpha: 0.3 + (_sirenController.value * 0.3),
                        ),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    PhosphorIcons.policeCar(PhosphorIconsStyle.fill),
                    size: 56,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            Text(
              'সবাই কার্ড দেখে ফেলেছে!',
              style: AppTextStyles.heading3(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '🚨 ফোনটি পুলিশের হাতে দিন',
              style: AppTextStyles.heading2(color: AppColors.police)
                  .copyWith(fontSize: 22, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              police?.name ?? 'Police',
              style: AppTextStyles.heading1(color: Colors.white)
                  .copyWith(fontSize: 34, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x20FFFFFF),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text(
                'শুধুমাত্র পুলিশ ফোন হাতে নিয়ে বন্ধুদের দিকে তাকাবেন এবং জেরা করবেন!',
                style: AppTextStyles.bodyMedium(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(
              label: 'I am Inspector ${police?.name} — Begin',
              leading: Icon(
                PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                color: Colors.white,
                size: 20,
              ),
              onPressed: notifier.beginPoliceInterrogation,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STAGE 4: POLICE ACCUSATION / INTERROGATION PHASE
  // ===========================================================================
  Widget _buildPoliceAccusingView(
    PassAndPlayState state,
    PassAndPlayViewModel notifier,
  ) {
    final police = state.policePlayer;
    final raja = state.rajaPlayer;
    final suspects = state.suspects;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inspector Header Card
          GameCard(
            isGlass: true,
            borderColor: AppColors.police.withValues(alpha: 0.4),
            glowColor: AppColors.policeGlow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.police.withValues(alpha: 0.25),
                  child: Icon(
                    PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                    color: AppColors.police,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ইন্সপেক্টর: ${police?.name}',
                        style: AppTextStyles.heading3().copyWith(fontSize: 16),
                      ),
                      Text(
                        'সন্দেহভাজনদের জেরা করুন এবং ডাকাত চিহ্নিত করুন',
                        style: AppTextStyles.caption(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Raja Immune Notice
          if (raja != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.raja.withValues(alpha: 0.12),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: AppColors.raja.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.crown(PhosphorIconsStyle.fill),
                    color: AppColors.raja,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '👑 ${raja.name} রাজা (ইনি নিরাপদ, কাউকে গ্রেপ্তার করতে পারবেন না)',
                      style: AppTextStyles.caption(color: AppColors.raja),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),

          Text(
            'সন্দেহভাজন ২ জনের মধ্যে ডাকাত কে?',
            style: AppTextStyles.heading2().copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'সন্দেহভাজনের নামের কার্ডে ট্যাপ করে গ্রেপ্তার করুন:',
            style: AppTextStyles.caption(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Suspects Choice Cards
          ...suspects.map((suspect) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () => _confirmAccusationDialog(context, suspect, notifier),
                borderRadius: AppRadius.cardRadius,
                child: GameCard(
                  isGlass: true,
                  borderColor: AppColors.chor.withValues(alpha: 0.35),
                  glowColor: AppColors.chorGlow,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.chor.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppColors.chor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          PhosphorIcons.user(PhosphorIconsStyle.fill),
                          color: AppColors.chor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suspect.name,
                              style: AppTextStyles.heading2().copyWith(fontSize: 18),
                            ),
                            Text(
                              'সন্দেহভাজন (মন্ত্রী অথবা ডাকাত)',
                              style: AppTextStyles.caption(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'গ্রেপ্তার 🎯',
                          style: AppTextStyles.caption(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _confirmAccusationDialog(
    BuildContext context,
    PassAndPlayPlayer suspect,
    PassAndPlayViewModel notifier,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: const BorderSide(color: AppColors.police, width: 1.5),
        ),
        title: Text('নিশ্চিত করুন', style: AppTextStyles.heading2()),
        content: Text(
          'আপনি কি নিশ্চিত যে "${suspect.name}"-ই আসল ডাকাত?',
          style: AppTextStyles.bodyMedium(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('না, বাতিল', style: AppTextStyles.bodyMedium(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.police,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              notifier.makeAccusation(suspect.id);
            },
            child: const Text('হ্যাঁ, গ্রেপ্তার করুন!'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STAGE 5: ROUND OUTCOME & CUMULATIVE LEADERBOARD
  // ===========================================================================
  Widget _buildRoundResultsView(
    PassAndPlayState state,
    PassAndPlayViewModel notifier,
  ) {
    final isCorrect = state.isGuessCorrect ?? false;
    final police = state.policePlayer;
    final accused = state.accusedPlayer;
    final chor = state.chorPlayer;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Outcome Banner Card
          GameCard(
            isGlass: true,
            glowColor: isCorrect ? AppColors.policeGlow : AppColors.chorGlow,
            borderColor: isCorrect ? AppColors.police : AppColors.chor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Icon(
                  isCorrect
                      ? PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill)
                      : PhosphorIcons.maskHappy(PhosphorIconsStyle.fill),
                  size: 48,
                  color: isCorrect ? AppColors.police : AppColors.chor,
                ),
                const SizedBox(height: 10),
                Text(
                  isCorrect
                      ? 'POLICE CAUGHT THE CHOR!'
                      : 'THE CHOR ESCAPED!',
                  style: AppTextStyles.heading2(
                    color: isCorrect ? const Color(0xFF48CAE4) : AppColors.chor,
                  ).copyWith(fontWeight: FontWeight.w900, fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isCorrect
                      ? '👮 ${police?.name} accused ${chor?.name} correctly!'
                      : '👮 ${police?.name} accused ${accused?.name} mistakenly! 🎭 ${chor?.name} stole the 500 points.',
                  style: AppTextStyles.bodyMedium(color: Colors.white70).copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Unmasked 4 Roles Grid
          Text(
            'এই রাউন্ডের ভূমিকা ও পয়েন্ট',
            style: AppTextStyles.heading3().copyWith(fontSize: 16),
          ),
          const SizedBox(height: 10),

          ...state.players.map((player) {
            final role = player.role;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x18FFFFFF),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: role == null
                      ? Colors.white10
                      : role.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  if (role != null)
                    RoleBadge(role: role, isCompact: true)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player.name,
                      style: AppTextStyles.bodyLarge().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '+${player.roundScore} pts',
                    style: AppTextStyles.bodyMedium(
                      color: player.roundScore > 0 ? AppColors.success : Colors.white54,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 18),

          // Cumulative Leaderboard
          Text(
            'মোট স্কোরবোর্ড (Leaderboard)',
            style: AppTextStyles.heading3().copyWith(fontSize: 16),
          ),
          const SizedBox(height: 10),

          ...state.leaderboard.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final player = entry.value;
            final isFirst = rank == 1;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isFirst
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : const Color(0x12FFFFFF),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: isFirst
                      ? AppColors.primaryLight.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFirst ? AppColors.primary : Colors.white12,
                    ),
                    child: Text(
                      '#$rank',
                      style: AppTextStyles.caption(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player.name,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: isFirst ? FontWeight.w900 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${player.totalScore} pts',
                    style: AppTextStyles.heading3(
                      color: isFirst ? AppColors.primaryLight : Colors.white,
                    ).copyWith(fontSize: 16),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Next Round Button
          CustomButton(
            label: state.isLastRound
                ? 'See Match Winner Podium 🏆'
                : 'Start Round ${state.currentRound + 1} (${state.currentRound + 1}/${state.totalRounds})',
            leading: Icon(
              state.isLastRound
                  ? PhosphorIcons.trophy(PhosphorIconsStyle.fill)
                  : PhosphorIcons.fastForward(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: 20,
            ),
            onPressed: notifier.nextRound,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // STAGE 6: MATCH OVER / WINNER PODIUM
  // ===========================================================================
  Widget _buildMatchOverView(
    PassAndPlayState state,
    PassAndPlayViewModel notifier,
  ) {
    final winner = state.leaderboard.first;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Winner Crown Graphic
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    blurRadius: 36,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'CHAMPION OF THE MATCH',
              style: AppTextStyles.caption(color: AppColors.raja)
                  .copyWith(letterSpacing: 2, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              winner.name,
              style: AppTextStyles.heading1(color: Colors.white)
                  .copyWith(fontSize: 34, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${winner.totalScore} Total Points',
              style: AppTextStyles.heading2(color: AppColors.primaryLight),
            ),
            const SizedBox(height: 24),

            // Final standings
            GameCard(
              isGlass: true,
              borderColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: state.leaderboard.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final player = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          '#$rank',
                          style: AppTextStyles.bodyLarge(color: Colors.white70)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            player.name,
                            style: AppTextStyles.bodyMedium().copyWith(
                              fontWeight: rank == 1 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          '${player.totalScore} pts',
                          style: AppTextStyles.bodyLarge(
                            color: rank == 1 ? AppColors.primaryLight : Colors.white,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            CustomButton(
              label: 'Play Again (Same Players)',
              leading: Icon(
                PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
                color: Colors.white,
                size: 20,
              ),
              onPressed: notifier.restartMatch,
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Return to Home',
              variant: ButtonVariant.secondary,
              leading: Icon(
                PhosphorIcons.house(PhosphorIconsStyle.bold),
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        title: Text('Quit Pass & Play?', style: AppTextStyles.heading2()),
        content: Text(
          'Are you sure you want to end this match? Current scores will be lost.',
          style: AppTextStyles.bodyMedium(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: AppTextStyles.bodyMedium(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.go(AppRoutes.home);
            },
            child: const Text('Quit to Home', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
