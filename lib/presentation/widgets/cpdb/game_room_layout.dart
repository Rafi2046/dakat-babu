import 'package:flutter/material.dart';

/// Standard game room layout: top ~60% gameplay, bottom ~40% scoreboard.
class GameRoomLayout extends StatelessWidget {
  final Widget gameplay;
  final Widget scoreboard;
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
    return Column(
      children: [
        Expanded(flex: gameplayFlex.round(), child: gameplay),
        Expanded(flex: scoreboardFlex.round(), child: scoreboard),
      ],
    );
  }
}
