import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../core/errors/failures.dart';
import '../../data/models/player_model.dart';
import '../../data/models/room_model.dart';
import '../../data/models/round_model.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/usecases/submit_guess_usecase.dart';

/// State representation for an active game round.
class GameRoundState {
  final RoundModel? round;
  final RoomModel? room;
  final List<PlayerModel> players;
  final bool isCardRevealed;
  final String? selectedSuspectId;
  final int remainingSeconds;
  final bool isSubmittingGuess;
  final String? errorMessage;
  final bool isCancelled;

  const GameRoundState({
    this.round,
    this.room,
    this.players = const [],
    this.isCardRevealed = false,
    this.selectedSuspectId,
    this.remainingSeconds = AppConstants.roundTimeoutSeconds,
    this.isSubmittingGuess = false,
    this.errorMessage,
    this.isCancelled = false,
  });

  /// The local user's player record.
  PlayerModel? myPlayer(String? myId) =>
      players.cast<PlayerModel?>().firstWhere(
            (p) => p?.id == myId,
            orElse: () => null,
          );

  /// Whether current local user is the room host.
  bool isHost(String? myId) =>
      players.any((p) => p.id == myId && p.isHost) || (room?.hostId == myId);

  /// Whether a player has dropped or left the active match.
  bool get isPlayerLeft =>
      (players.length < (room?.maxPlayers ?? AppConstants.defaultPlayers) && players.isNotEmpty) ||
      (room?.status == RoomStatus.playerLeft);

  /// The player assigned to the Raja role.
  PlayerModel? get rajaPlayer =>
      players.cast<PlayerModel?>().firstWhere(
            (p) => p?.id == round?.rajaPlayerId,
            orElse: () => null,
          );

  /// The player assigned to the Police role.
  PlayerModel? get policePlayer =>
      players.cast<PlayerModel?>().firstWhere(
            (p) => p?.id == round?.policePlayerId,
            orElse: () => null,
          );

  /// Suspects the Police can accuse (everyone except Raja and Police).
  List<PlayerModel> get suspects => players
      .where((p) => p.id != round?.rajaPlayerId && p.id != round?.policePlayerId)
      .toList();

  /// Whether current local user is the Police.
  bool isPolice(String? myId) => round?.policePlayerId == myId;

  GameRoundState copyWith({
    RoundModel? round,
    RoomModel? room,
    List<PlayerModel>? players,
    bool? isCardRevealed,
    String? selectedSuspectId,
    int? remainingSeconds,
    bool? isSubmittingGuess,
    String? errorMessage,
    bool clearError = false,
    bool? isCancelled,
  }) {
    return GameRoundState(
      round: round ?? this.round,
      room: room ?? this.room,
      players: players ?? this.players,
      isCardRevealed: isCardRevealed ?? this.isCardRevealed,
      selectedSuspectId: selectedSuspectId ?? this.selectedSuspectId,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isSubmittingGuess: isSubmittingGuess ?? this.isSubmittingGuess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}

/// ViewModel coordinating role reveal, countdown timers, and Police guess submission.
class GameRoundViewModel extends StateNotifier<GameRoundState> {
  final String _roomCode;
  final GameRepository _gameRepository;
  final RoomRepository _roomRepository;
  final SubmitGuessUseCase _submitGuessUseCase;

  StreamSubscription<RoundModel?>? _roundSub;
  StreamSubscription<RoomModel?>? _roomSub;
  StreamSubscription<List<PlayerModel>>? _playersSub;
  Timer? _timer;

  GameRoundViewModel({
    required String roomCode,
    required GameRepository gameRepository,
    required RoomRepository roomRepository,
    required SubmitGuessUseCase submitGuessUseCase,
  })  : _roomCode = roomCode,
        _gameRepository = gameRepository,
        _roomRepository = roomRepository,
        _submitGuessUseCase = submitGuessUseCase,
        super(const GameRoundState()) {
    _initSubscriptions();
    _startTimer();
  }

  void _initSubscriptions() {
    _roundSub?.cancel();
    _roundSub = _gameRepository.watchCurrentRound(_roomCode).listen(
      (round) {
        if (mounted) state = state.copyWith(round: round);
      },
      onError: (err) {
        if (mounted) state = state.copyWith(errorMessage: err.toString());
      },
    );

    _roomSub?.cancel();
    _roomSub = _roomRepository.watchRoom(_roomCode).listen(
      (room) {
        if (!mounted) return;
        if (room == null || room.status == RoomStatus.cancelled) {
          state = state.copyWith(room: room, isCancelled: true);
        } else {
          state = state.copyWith(room: room);
        }
      },
      onError: (err) {
        if (mounted) state = state.copyWith(errorMessage: err.toString());
      },
    );

    _playersSub?.cancel();
    _playersSub = _roomRepository.watchPlayers(_roomCode).listen(
      (players) {
        if (mounted) state = state.copyWith(players: players);
      },
      onError: (err) {
        if (mounted) state = state.copyWith(errorMessage: err.toString());
      },
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        timer.cancel();
      }
    });
  }

  /// Toggles whether player has unmasked their secret card.
  void toggleCardReveal() {
    state = state.copyWith(isCardRevealed: !state.isCardRevealed);
  }

  /// Police selects a suspect tile.
  void selectSuspect(String playerId) {
    state = state.copyWith(selectedSuspectId: playerId);
  }

  /// Submits the Police's accusation.
  Future<bool> submitGuess() async {
    final round = state.round;
    final suspectId = state.selectedSuspectId;

    if (round == null || suspectId == null) {
      state = state.copyWith(errorMessage: 'Please select a suspect first!');
      return false;
    }

    state = state.copyWith(isSubmittingGuess: true, clearError: true);
    try {
      await _submitGuessUseCase(
        roundId: round.id,
        roomCode: _roomCode,
        suspectPlayerId: suspectId,
      );
      state = state.copyWith(isSubmittingGuess: false);
      return true;
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      if (mounted) state = state.copyWith(isSubmittingGuess: false, errorMessage: message);
      return false;
    }
  }

  /// Host resets room back to lobby waiting room so a 4th player can be invited/joined.
  Future<bool> returnToLobby() async {
    try {
      await _roomRepository.returnToLobby(_roomCode);
      return true;
    } catch (e) {
      if (mounted) {
        final message = e is Failure ? e.message : e.toString();
        state = state.copyWith(errorMessage: message);
      }
      return false;
    }
  }

  /// Player leaves mid-game.
  Future<bool> leaveGame(String playerId) async {
    try {
      await _roomRepository.leaveRoom(playerId: playerId, roomCode: _roomCode);
      return true;
    } catch (e) {
      if (mounted) {
        final message = e is Failure ? e.message : e.toString();
        state = state.copyWith(errorMessage: message);
      }
      return false;
    }
  }

  /// Host cancels/disbands the game mid-round.
  Future<bool> cancelGame() async {
    try {
      await _roomRepository.cancelRoom(_roomCode);
      if (mounted) state = state.copyWith(isCancelled: true);
      return true;
    } catch (e) {
      if (mounted) {
        final message = e is Failure ? e.message : e.toString();
        state = state.copyWith(errorMessage: message);
      }
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _roundSub?.cancel();
    _roomSub?.cancel();
    _playersSub?.cancel();
    super.dispose();
  }
}

/// Riverpod family provider for [GameRoundViewModel] keyed by roomCode.
final gameRoundViewModelProvider =
    StateNotifierProvider.family.autoDispose<GameRoundViewModel, GameRoundState, String>(
  (ref, roomCode) {
    return GameRoundViewModel(
      roomCode: roomCode,
      gameRepository: ref.watch(gameRepositoryProvider),
      roomRepository: ref.watch(roomRepositoryProvider),
      submitGuessUseCase: ref.watch(submitGuessUseCaseProvider),
    );
  },
);
