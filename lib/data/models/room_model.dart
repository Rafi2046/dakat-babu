/// Lifecycle states of a multiplayer room.
enum RoomStatus {
  /// Players are joining and waiting in the lobby.
  waiting,

  /// An active round is in progress.
  inProgress,

  /// A round has completed and results are displayed.
  roundEnded,

  /// All match rounds are concluded.
  completed,

  /// A player dropped out or disconnected mid-game.
  playerLeft,

  /// The room was disbanded or cancelled by the host.
  cancelled;

  /// Parses a status string into a [RoomStatus].
  static RoomStatus parse(String? value) {
    if (value == null) return RoomStatus.waiting;
    switch (value.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return RoomStatus.inProgress;
      case 'round_ended':
      case 'roundended':
        return RoomStatus.roundEnded;
      case 'completed':
        return RoomStatus.completed;
      case 'player_left':
      case 'playerleft':
      case 'abandoned':
        return RoomStatus.playerLeft;
      case 'cancelled':
      case 'canceled':
        return RoomStatus.cancelled;
      case 'waiting':
      default:
        return RoomStatus.waiting;
    }
  }

  /// Serializes enum to snake_case for Supabase storage.
  String toDbValue() {
    switch (this) {
      case RoomStatus.waiting:
        return 'waiting';
      case RoomStatus.inProgress:
        return 'in_progress';
      case RoomStatus.roundEnded:
        return 'round_ended';
      case RoomStatus.completed:
        return 'completed';
      case RoomStatus.playerLeft:
        return 'player_left';
      case RoomStatus.cancelled:
        return 'cancelled';
    }
  }
}

/// Data model representing a DakatBabu multiplayer room.
class RoomModel {
  /// Database primary key UUID.
  final String id;

  /// 6-character room join code.
  final String roomCode;

  /// Player ID of the room creator/host.
  final String hostId;

  /// Current game lifecycle status.
  final RoomStatus status;

  /// Current round number (1 to maxRounds).
  final int currentRound;

  /// Total number of rounds configured for this match.
  final int maxRounds;

  /// Room creation timestamp.
  final DateTime createdAt;

  /// Last updated timestamp.
  final DateTime? updatedAt;

  const RoomModel({
    required this.id,
    required this.roomCode,
    required this.hostId,
    this.status = RoomStatus.waiting,
    this.currentRound = 0,
    this.maxRounds = 5,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a copy of this room with updated fields.
  RoomModel copyWith({
    String? id,
    String? roomCode,
    String? hostId,
    RoomStatus? status,
    int? currentRound,
    int? maxRounds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      maxRounds: maxRounds ?? this.maxRounds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Deserializes a [RoomModel] from a JSON map.
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      roomCode: json['room_code'] as String,
      hostId: json['host_id'] as String,
      status: RoomStatus.parse(json['status'] as String?),
      currentRound: (json['current_round'] as num?)?.toInt() ?? 0,
      maxRounds: (json['max_rounds'] as num?)?.toInt() ?? 5,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Serializes this [RoomModel] into a Supabase-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_code': roomCode,
      'host_id': hostId,
      'status': status.toDbValue(),
      'current_round': currentRound,
      'max_rounds': maxRounds,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          roomCode == other.roomCode &&
          status == other.status &&
          currentRound == other.currentRound;

  @override
  int get hashCode => id.hashCode ^ roomCode.hashCode ^ status.hashCode;
}
