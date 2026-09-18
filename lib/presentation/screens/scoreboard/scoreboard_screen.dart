import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/player_model.dart';
import '../../viewmodels/scoreboard_viewmodel.dart';
import '../../widgets/animated_living_background.dart';

/// Dedicated, polished live scoreboard screen showing cumulative player standings,
/// leader spotlight with gold glow, and per-round role & score breakdown.
class ScoreboardScreen extends ConsumerWidget {
  final String roomCode;

  const ScoreboardScreen({
    super.key,
    required this.roomCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoreboardViewModelProvider(roomCode));
    final room = state.room;
    final rankedPlayers = state.rankedPlayers;
    final leader = state.leader;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, room?.currentRound ?? 1, room?.maxRounds ?? 5),
              if (state.isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (rankedPlayers.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No players found in room $roomCode',
                      style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    children: [
                      if (leader != null) ...[
                        _buildLeaderSpotlight(leader, state.rounds.length),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _buildStandingsHeader(rankedPlayers.length),
                      const SizedBox(height: AppSpacing.xs),
                      ...List.generate(rankedPlayers.length, (index) {
                        final player = rankedPlayers[index];
                        final isFirst = index == 0;
                        final history = state.getPlayerHistory(player.id);
                        return _buildPlayerScoreCard(
                          player: player,
                          rank: index + 1,
                          isFirst: isFirst,
                          history: history,
                        );
                      }),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int currentRound, int maxRounds) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
              color: AppColors.textLightPrimary,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceElevatedDark.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                side: BorderSide(
                  color: AppColors.borderDark.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                      color: AppColors.raja,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Scoreboard',
                      style: AppTextStyles.heading3(),
                    ),
                  ],
                ),
                Text(
                  'Room $roomCode  •  Round $currentRound of $maxRounds',
                  style: AppTextStyles.caption(color: AppColors.textLightSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderSpotlight(PlayerModel leader, int roundsPlayed) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.raja.withValues(alpha: 0.20),
            AppColors.raja.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.raja.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.raja.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Crown avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.raja, Color(0xFFD4AC0D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                ),
                child: Center(
                  child: Text(
                    leader.name.initials,
                    style: AppTextStyles.heading3(color: Colors.black),
                  ),
                ),
              ),
              Positioned(
                top: -12,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.raja,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.crown(PhosphorIconsStyle.fill),
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.raja.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'CURRENT MATCH LEADER',
                    style: AppTextStyles.caption(
                      color: AppColors.raja,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  leader.name,
                  style: AppTextStyles.heading3(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  roundsPlayed == 0
                      ? 'First round in progress'
                      : 'Leading across $roundsPlayed round${roundsPlayed == 1 ? '' : 's'}',
                  style: AppTextStyles.caption(color: AppColors.textLightSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${leader.score}',
                style: AppTextStyles.heading1(color: AppColors.raja),
              ),
              Text(
                'PTS',
                style: AppTextStyles.caption(
                  color: AppColors.raja.withValues(alpha: 0.8),
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MATCH STANDINGS',
            style: AppTextStyles.caption(
              color: AppColors.textLightSecondary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '$count Players',
            style: AppTextStyles.caption(color: AppColors.textLightSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScoreCard({
    required PlayerModel player,
    required int rank,
    required bool isFirst,
    required List<ScoreboardRoundEntry> history,
  }) {
    Color rankBadgeColor;
    Color rankTextColor;
    if (rank == 1) {
      rankBadgeColor = AppColors.raja;
      rankTextColor = Colors.black;
    } else if (rank == 2) {
      rankBadgeColor = const Color(0xFFC0C0C0);
      rankTextColor = Colors.black;
    } else if (rank == 3) {
      rankBadgeColor = const Color(0xFFCD7F32);
      rankTextColor = Colors.white;
    } else {
      rankBadgeColor = AppColors.surfaceElevatedDark;
      rankTextColor = AppColors.textLightSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isFirst
            ? AppColors.surfaceElevatedDark.withValues(alpha: 0.8)
            : AppColors.surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isFirst
              ? AppColors.raja.withValues(alpha: 0.4)
              : AppColors.borderDark.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: rankBadgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: AppTextStyles.caption(
                        color: rankTextColor,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Player initials avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryDark,
                  child: Text(
                    player.name.initials,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.textLightPrimary,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              player.name,
                              style: AppTextStyles.bodyMedium(
                                color: AppColors.textLightPrimary,
                              ).copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (player.isHost) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                'HOST',
                                style: AppTextStyles.caption(
                                  color: AppColors.primaryLight,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${history.length} round${history.length == 1 ? '' : 's'} recorded',
                        style: AppTextStyles.caption(color: AppColors.textLightSecondary),
                      ),
                    ],
                  ),
                ),
                // Points
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${player.score}',
                      style: AppTextStyles.heading3(
                        color: isFirst ? AppColors.raja : AppColors.textLightPrimary,
                      ),
                    ),
                    Text(
                      'PTS',
                      style: AppTextStyles.caption(
                        color: isFirst
                            ? AppColors.raja.withValues(alpha: 0.8)
                            : AppColors.textLightSecondary,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              const Divider(color: AppColors.borderDark, height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: history.map((entry) {
                  return _buildRoundChip(entry);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoundChip(ScoreboardRoundEntry entry) {
    final roleColor = entry.role.color;
    final emoji = _getRoleEmoji(entry.role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'R${entry.roundNumber}: $emoji ${entry.roleLabel}',
            style: AppTextStyles.caption(
              color: roleColor,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Text(
            '+${entry.pointsEarned}',
            style: AppTextStyles.caption(
              color: entry.pointsEarned > 0 ? AppColors.success : AppColors.error,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getRoleEmoji(GameRole role) {
    switch (role) {
      case GameRole.raja:
        return '👑';
      case GameRole.mantri:
        return '📜';
      case GameRole.police:
        return '👮';
      case GameRole.chor:
        return '🦹';
      case GameRole.chintaykari:
        return '🗡️';
      case GameRole.batpar:
        return '🎭';
    }
  }
}
