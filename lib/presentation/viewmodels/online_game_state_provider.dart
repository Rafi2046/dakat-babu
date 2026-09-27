import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/models/room_model.dart';
import '../../data/services/supabase_service.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/usecases/assign_roles_usecase.dart';

/// Live online room snapshot for lobby → game navigation.
class OnlineGameState {
  final RoomModel? room;
  final bool isStarting;
  final String? errorMessage;

  const OnlineGameState({
    this.room,
    this.isStarting = false,
    this.errorMessage,
  });

  /// True when room left waiting and entered active play (`in_progress` / playing).
  bool get isPlaying =>
      room?.status == RoomStatus.inProgress ||
      room?.status == RoomStatus.roundEnded;

  bool get isWaiting => room == null || room!.status == RoomStatus.waiting;

  OnlineGameState copyWith({
    RoomModel? room,
    bool? isStarting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnlineGameState(
      room: room ?? this.room,
      isStarting: isStarting ?? this.isStarting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Listens to Supabase `rooms` realtime stream for a given room code.
class OnlineGameStateNotifier
    extends AutoDisposeFamilyNotifier<OnlineGameState, String> {
  @override
  OnlineGameState build(String roomCode) {
    ref.listen<AsyncValue<RoomModel?>>(
      onlineRoomStreamProvider(roomCode),
      (prev, next) {
        next.when(
          data: (room) {
            state = state.copyWith(room: room, clearError: true);
          },
          error: (e, _) {
            state = state.copyWith(errorMessage: e.toString());
          },
          loading: () {},
        );
      },
      fireImmediately: true,
    );
    return const OnlineGameState();
  }

  String get roomCode => arg;

  /// Host starts the round via Edge Function `start-round` (falls back offline).
  Future<bool> startRound({int roundNumber = 1}) async {
    if (state.isStarting) return false;
    state = state.copyWith(isStarting: true, clearError: true);

    try {
      await ref.read(startOnlineRoundProvider).call(
            roomCode: roomCode,
            roundNumber: roundNumber,
          );
      state = state.copyWith(isStarting: false);
      return true;
    } catch (e, st) {
      debugPrint('[OnlineGameState] startRound failed: $e\n$st');
      state = state.copyWith(
        isStarting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

/// Realtime room row stream (Supabase `.stream()` via [RoomRepository.watchRoom]).
final onlineRoomStreamProvider =
    StreamProvider.autoDispose.family<RoomModel?, String>((ref, roomCode) {
  return ref.watch(roomRepositoryProvider).watchRoom(roomCode);
});

final onlineGameStateProvider = NotifierProvider.autoDispose
    .family<OnlineGameStateNotifier, OnlineGameState, String>(
  OnlineGameStateNotifier.new,
);

/// Invokes Supabase Edge Function `start-round`, or local assign-roles fallback.
final startOnlineRoundProvider = Provider<StartOnlineRound>((ref) {
  return StartOnlineRound(
    supabase: ref.watch(supabaseServiceProvider),
    assignRoles: ref.watch(assignRolesUseCaseProvider),
    roomRepository: ref.watch(roomRepositoryProvider),
  );
});

class StartOnlineRound {
  StartOnlineRound({
    required SupabaseService supabase,
    required AssignRolesUseCase assignRoles,
    required RoomRepository roomRepository,
  })  : _supabase = supabase,
        _assignRoles = assignRoles,
        _roomRepository = roomRepository;

  final SupabaseService _supabase;
  final AssignRolesUseCase _assignRoles;
  final RoomRepository _roomRepository;

  Future<void> call({
    required String roomCode,
    int roundNumber = 1,
  }) async {
    if (_supabase.isConfigured) {
      await _supabase.invokeStartRound(
        roomCode: roomCode,
        roundNumber: roundNumber,
      );
      return;
    }
    final players = await _roomRepository.getPlayers(roomCode);
    await _assignRoles(
      roomCode: roomCode,
      players: players,
      roundNumber: roundNumber,
    );
  }
}
