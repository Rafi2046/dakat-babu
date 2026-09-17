import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/game_round/game_round_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/lobby/lobby_screen.dart';
import '../../presentation/screens/results/results_screen.dart';
import '../constants/app_text_styles.dart';
import 'app_routes.dart';

/// Provider exposing configured [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.lobby,
        name: AppRoutes.lobbyName,
        builder: (context, state) {
          final roomCode = state.pathParameters[AppRoutes.paramRoomCode] ?? '';
          return LobbyScreen(roomCode: roomCode);
        },
      ),
      GoRoute(
        path: AppRoutes.gameRound,
        name: AppRoutes.gameRoundName,
        builder: (context, state) {
          final roomCode = state.pathParameters[AppRoutes.paramRoomCode] ?? '';
          return GameRoundScreen(roomCode: roomCode);
        },
      ),
      GoRoute(
        path: AppRoutes.results,
        name: AppRoutes.resultsName,
        builder: (context, state) {
          final roomCode = state.pathParameters[AppRoutes.paramRoomCode] ?? '';
          return ResultsScreen(roomCode: roomCode);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Page not found', style: AppTextStyles.heading2()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
