import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/game_repository_impl.dart';
import '../../data/repositories/room_repository_impl.dart';
import '../../data/services/supabase_service.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/usecases/assign_roles_usecase.dart';
import '../../domain/usecases/create_room_usecase.dart';
import '../../domain/usecases/join_room_usecase.dart';
import '../../domain/usecases/submit_guess_usecase.dart';

// --- Services ---
/// Singleton provider for the Supabase backend service.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// --- Repositories ---
/// Provider for the [RoomRepository] interface.
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return RoomRepositoryImpl(supabaseService: service);
});

/// Provider for the [GameRepository] interface.
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return GameRepositoryImpl(supabaseService: service);
});

// --- Use Cases ---
/// Provider for [CreateRoomUseCase].
final createRoomUseCaseProvider = Provider<CreateRoomUseCase>((ref) {
  final repo = ref.watch(roomRepositoryProvider);
  return CreateRoomUseCase(repo);
});

/// Provider for [JoinRoomUseCase].
final joinRoomUseCaseProvider = Provider<JoinRoomUseCase>((ref) {
  final repo = ref.watch(roomRepositoryProvider);
  return JoinRoomUseCase(repo);
});

/// Provider for [AssignRolesUseCase].
final assignRolesUseCaseProvider = Provider<AssignRolesUseCase>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return AssignRolesUseCase(repo);
});

/// Provider for [SubmitGuessUseCase].
final submitGuessUseCaseProvider = Provider<SubmitGuessUseCase>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return SubmitGuessUseCase(repo);
});

// --- Session State (Current User & Room) ---
/// Current active player's unique ID for the local device.
final currentPlayerIdProvider = StateProvider<String?>((ref) => null);

/// Current active room code for the local device.
final currentRoomCodeProvider = StateProvider<String?>((ref) => null);
