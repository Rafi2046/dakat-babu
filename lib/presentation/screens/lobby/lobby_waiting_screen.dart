import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/home_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/online_game_state_provider.dart';
import '../../widgets/parallax_lobby_background.dart';
import '../../widgets/tactile_menu_button.dart';

/// Mock lobby player for UI preview (replace with Supabase later).
class LobbySlotPlayer {
  final String id;
  final String name;
  final bool isHost;
  final bool isReady;

  const LobbySlotPlayer({
    required this.id,
    required this.name,
    this.isHost = false,
    this.isReady = false,
  });

  LobbySlotPlayer copyWith({bool? isReady}) => LobbySlotPlayer(
        id: id,
        name: name,
        isHost: isHost,
        isReady: isReady ?? this.isReady,
      );
}

/// Mock waiting-room state — 2 joined, 2 empty.
class LobbyWaitingState {
  final String roomCode;
  final List<LobbySlotPlayer?> slots;
  final String localPlayerId;
  final bool localReady;

  const LobbyWaitingState({
    required this.roomCode,
    required this.slots,
    required this.localPlayerId,
    this.localReady = false,
  });

  int get occupiedCount => slots.where((s) => s != null).length;

  bool get isFull => occupiedCount >= 4;

  bool get isHost {
    final me = slots.cast<LobbySlotPlayer?>().firstWhere(
          (s) => s?.id == localPlayerId,
          orElse: () => null,
        );
    return me?.isHost ?? false;
  }

  LobbyWaitingState copyWith({
    List<LobbySlotPlayer?>? slots,
    bool? localReady,
  }) =>
      LobbyWaitingState(
        roomCode: roomCode,
        slots: slots ?? this.slots,
        localPlayerId: localPlayerId,
        localReady: localReady ?? this.localReady,
      );
}

class LobbyWaitingNotifier extends Notifier<LobbyWaitingState> {
  @override
  LobbyWaitingState build() => const LobbyWaitingState(
        roomCode: 'CPDB',
        localPlayerId: 'p1',
        slots: [
          LobbySlotPlayer(
            id: 'p1',
            name: 'রাফি',
            isHost: true,
            isReady: true,
          ),
          LobbySlotPlayer(
            id: 'p2',
            name: 'সারা',
            isReady: false,
          ),
          null,
          null,
        ],
      );

  void toggleReady() {
    final ready = !state.localReady;
    final nextSlots = [
      for (final slot in state.slots)
        if (slot?.id == state.localPlayerId)
          slot!.copyWith(isReady: ready)
        else
          slot,
    ];
    state = state.copyWith(slots: nextSlots, localReady: ready);
  }

  void startGame() {
    // Prefer [OnlineGameStateNotifier.startRound] via LobbyWaitingScreen when
    // a live [roomCode] is provided.
  }
}

final lobbyWaitingProvider =
    NotifierProvider<LobbyWaitingNotifier, LobbyWaitingState>(
  LobbyWaitingNotifier.new,
);

/// Premium Online Waiting Room UI.
///
/// Pass [roomCode] to enable Supabase `start-round` + realtime navigation.
/// Omit for mock preview (2/4 players).
class LobbyWaitingScreen extends ConsumerStatefulWidget {
  final String? roomCode;

  const LobbyWaitingScreen({super.key, this.roomCode});

  static const Color _neon = AppColors.secondary;

  @override
  ConsumerState<LobbyWaitingScreen> createState() => _LobbyWaitingScreenState();
}

class _LobbyWaitingScreenState extends ConsumerState<LobbyWaitingScreen> {
  bool get _live =>
      widget.roomCode != null && widget.roomCode!.trim().isNotEmpty;

  String get _code =>
      _live ? widget.roomCode!.trim().toUpperCase() : 'CPDB';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mock = ref.watch(lobbyWaitingProvider);
    final mockNotifier = ref.read(lobbyWaitingProvider.notifier);

    // Live Supabase room stream → auto-navigate when status becomes playing.
    if (_live) {
      ref.listen<OnlineGameState>(onlineGameStateProvider(_code), (prev, next) {
        if (next.isPlaying && !(prev?.isPlaying ?? false)) {
          context.go(AppRoutes.gameRoundPath(_code));
        }
        if (next.errorMessage != null &&
            next.errorMessage != prev?.errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
        }
      });
    }

    final online =
        _live ? ref.watch(onlineGameStateProvider(_code)) : null;
    final canStart = _live
        ? true // Host gate enforced server-side; CTA always "Start" when live+full mock slots
        : (mock.isHost && mock.isFull);
    // For live rooms, Start when host taps; for mock keep Ready Up until full.
    final showStart = _live || canStart;
    final ctaLabel = showStart ? l10n.startGame : l10n.readyUp;
    final starting = online?.isStarting ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: ParallaxLobbyBackground(
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LobbyHeader(
                  roomCode: _live ? _code : mock.roomCode,
                  waitingLabel: l10n.waitingForPlayers,
                  roomCodeLabel: l10n.roomCode,
                  tapToCopyLabel: l10n.tapToCopy,
                ),
                AppSpacing.gapVLg,
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final player = mock.slots[index];
                      if (player == null) {
                        return _EmptySlot(label: l10n.openSlot);
                      }
                      return _OccupiedSlot(
                        player: player,
                        isYou: player.id == mock.localPlayerId,
                      );
                    },
                  ),
                ),
                AppSpacing.gapVMd,
                TactileMenuButton(
                  text: starting ? '...' : ctaLabel,
                  icon: showStart
                      ? Icons.play_arrow_rounded
                      : Icons.check_circle_outline_rounded,
                  accentColor:
                      showStart ? AppColors.homeOnline : LobbyWaitingScreen._neon,
                  enabled: !starting,
                  onTap: () async {
                    if (showStart && _live) {
                      await ref
                          .read(onlineGameStateProvider(_code).notifier)
                          .startRound();
                      // Navigation happens via realtime listener when status flips.
                      return;
                    }
                    if (showStart && !_live) {
                      // Mock preview — jump to game route for UI smoke test.
                      context.go(AppRoutes.gameRoundPath(mock.roomCode));
                      return;
                    }
                    mockNotifier.toggleReady();
                  },
                ),
                AppSpacing.gapVSm,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyHeader extends StatelessWidget {
  final String roomCode;
  final String waitingLabel;
  final String roomCodeLabel;
  final String tapToCopyLabel;

  const _LobbyHeader({
    required this.roomCode,
    required this.waitingLabel,
    required this.roomCodeLabel,
    required this.tapToCopyLabel,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: roomCode));
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$roomCode — $tapToCopyLabel'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          roomCodeLabel,
          style: HomeTextStyles.caption(color: AppColors.textLightSecondary),
        ),
        AppSpacing.gapVXs,
        Text(
          roomCode,
          style: HomeTextStyles.hero(color: AppColors.textLightPrimary).copyWith(
            fontSize: 42,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: LobbyWaitingScreen._neon.withValues(alpha: 0.55),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        AppSpacing.gapVSm,
        _TapToCopyChip(
          label: tapToCopyLabel,
          onTap: () => _copy(context),
        ),
        AppSpacing.gapVMd,
        Text(
          waitingLabel,
          style: HomeTextStyles.title(color: LobbyWaitingScreen._neon).copyWith(
            shadows: [
              Shadow(
                color: LobbyWaitingScreen._neon.withValues(alpha: 0.7),
                blurRadius: 14,
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(
              duration: 1800.ms,
              color: Colors.white.withValues(alpha: 0.55),
            )
            .fade(begin: 0.65, end: 1, duration: 1400.ms),
      ],
    );
  }
}

class _TapToCopyChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _TapToCopyChip({required this.label, required this.onTap});

  @override
  State<_TapToCopyChip> createState() => _TapToCopyChipState();
}

class _TapToCopyChipState extends State<_TapToCopyChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: LobbyWaitingScreen._neon.withValues(alpha: 0.35),
            ),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: LobbyWaitingScreen._neon.withValues(alpha: 0.12),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.copy_rounded,
                size: 16,
                color: LobbyWaitingScreen._neon,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: HomeTextStyles.caption(
                  color: AppColors.textLightPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OccupiedSlot extends StatelessWidget {
  final LobbySlotPlayer player;
  final bool isYou;

  const _OccupiedSlot({required this.player, required this.isYou});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LobbyWaitingScreen._neon,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: LobbyWaitingScreen._neon.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceElevatedDark,
            child: Text(
              player.name.isNotEmpty
                  ? String.fromCharCodes(player.name.runes.take(1))
                  : '?',
              style: HomeTextStyles.title(color: LobbyWaitingScreen._neon),
            ),
          ),
          AppSpacing.gapVSm,
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeTextStyles.body(color: AppColors.textLightPrimary),
          ),
          if (player.isHost || isYou || player.isReady) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (player.isHost) 'HOST',
                if (isYou) 'YOU',
                if (player.isReady) 'READY',
              ].join(' · '),
              style: HomeTextStyles.caption(
                color: AppColors.textLightSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String label;

  const _EmptySlot({required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: Duration.zero,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: LobbyWaitingScreen._neon.withValues(alpha: 0.45),
          radius: 18,
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                color: LobbyWaitingScreen._neon.withValues(alpha: 0.55),
                size: 36,
              ),
              AppSpacing.gapVSm,
              Text(
                label,
                style: HomeTextStyles.caption(
                  color: AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.4, end: 0.95, duration: 1400.ms);
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double _strokeWidth = 2;
  static const double _dashLength = 7;
  static const double _gapLength = 5;

  _DashedBorderPainter({
    required this.color,
    this.radius = 18,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
