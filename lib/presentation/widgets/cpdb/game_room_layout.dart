import 'package:flutter/material.dart';

/// Game room: cards on top, scoreboard docked below (capped so cards keep room).
class GameRoomLayout extends StatelessWidget {
  final Widget gameplay;
  final Widget scoreboard;

  /// Kept for API compatibility.
  final double gameplayFlex;
  final double scoreboardFlex;

  const GameRoomLayout({
    super.key,
    required this.gameplay,
    required this.scoreboard,
    this.gameplayFlex = 6,
    this.scoreboardFlex = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 600.0;
        // Never let the board eat more than ~34% — stops zero-height gameplay.
        final boardMax = (h * 0.34).clamp(100.0, 240.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: gameplay),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: boardMax),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: scoreboard,
              ),
            ),
          ],
        );
      },
    );
  }
}
