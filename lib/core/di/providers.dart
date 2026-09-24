import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/player_profile_store.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../data/repositories/room_repository_impl.dart';
import '../../data/services/supabase_service.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/usecases/assign_roles_usecase.dart';
import '../../domain/usecases/create_room_usecase.dart';
import '../../domain/usecases/join_room_usecase.dart';
import '../../domain/usecases/submit_guess_usecase.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Local profile / stats / settings store. Overridden in main().
final playerProfileStoreProvider = Provider<PlayerProfileStore>((ref) {
  throw UnimplementedError('Override playerProfileStoreProvider in main()');
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return RoomRepositoryImpl(supabaseService: service);
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return GameRepositoryImpl(supabaseService: service);
});

final createRoomUseCaseProvider = Provider<CreateRoomUseCase>((ref) {
  final repo = ref.watch(roomRepositoryProvider);
  return CreateRoomUseCase(repo);
});

final joinRoomUseCaseProvider = Provider<JoinRoomUseCase>((ref) {
  final repo = ref.watch(roomRepositoryProvider);
  return JoinRoomUseCase(repo);
});

final assignRolesUseCaseProvider = Provider<AssignRolesUseCase>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return AssignRolesUseCase(repo);
});

final submitGuessUseCaseProvider = Provider<SubmitGuessUseCase>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return SubmitGuessUseCase(repo);
});

final currentPlayerIdProvider = StateProvider<String?>((ref) => null);
final currentRoomCodeProvider = StateProvider<String?>((ref) => null);
