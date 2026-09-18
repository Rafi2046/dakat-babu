import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import 'role_preset_model.dart';

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

  /// Required number of players to start the game (4, 5, or 6).
  final int maxPlayers;

  /// Role naming and styling preset key (e.g. 'classic', 'chor_police_dakat_babu').
  final String rolePreset;

  /// Optional custom role label overrides stored as json.
  final Map<String, String>? roleLabels;

  /// Optional custom role point values stored as json.
  final Map<String, int>? rolePoints;

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
    this.maxPlayers = 4,
    this.rolePreset = 'classic',
    this.roleLabels,
    this.rolePoints,
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
    int? maxPlayers,
    String? rolePreset,
    Map<String, String>? roleLabels,
    Map<String, int>? rolePoints,
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
      maxPlayers: maxPlayers ?? this.maxPlayers,
      rolePreset: rolePreset ?? this.rolePreset,
      roleLabels: roleLabels ?? this.roleLabels,
      rolePoints: rolePoints ?? this.rolePoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Deserializes a [RoomModel] from a JSON map.
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    Map<String, String>? parsedLabels;
    if (json['role_labels'] != null && json['role_labels'] is Map) {
      parsedLabels = (json['role_labels'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }

    Map<String, int>? parsedPoints;
    if (json['role_points'] != null && json['role_points'] is Map) {
      parsedPoints = (json['role_points'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
    }

    return RoomModel(
      id: json['id'] as String,
      roomCode: json['room_code'] as String,
      hostId: json['host_id'] as String,
      status: RoomStatus.parse(json['status'] as String?),
      currentRound: (json['current_round'] as num?)?.toInt() ?? 0,
      maxRounds: (json['max_rounds'] as num?)?.toInt() ?? 5,
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 4,
      rolePreset: (json['role_preset'] as String?) ?? 'classic',
      roleLabels: parsedLabels,
      rolePoints: parsedPoints,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Serializes this [RoomModel] into a Supabase-compatible JSON map.
  Map<String, dynamic> toJson({bool includeCustomColumns = true}) {
    final map = <String, dynamic>{
      'id': id,
      'room_code': roomCode,
      'host_id': hostId,
      'status': status.toDbValue(),
      'current_round': currentRound,
      'max_rounds': maxRounds,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };

    if (includeCustomColumns) {
      map['max_players'] = maxPlayers;
      map['role_preset'] = rolePreset;
      if (roleLabels != null) map['role_labels'] = roleLabels;
      if (rolePoints != null) map['role_points'] = rolePoints;
    }

    return map;
  }

  /// Returns the configured [RolePresetModel] for this room with any overrides.
  RolePresetModel get presetModel {
    final base = RolePresetModel.fromId(rolePreset);
    if (roleLabels == null || roleLabels!.isEmpty) return base;
    final mergedLabels = Map<GameRole, String>.from(base.roleLabels);
    for (final entry in roleLabels!.entries) {
      final r = GameRole.tryParse(entry.key);
      if (r != null) mergedLabels[r] = entry.value;
    }
    return base.copyWith(roleLabels: mergedLabels);
  }

  /// Returns display label for [role] using room preset.
  String getLabelForRole(GameRole role) {
    if (roleLabels != null && roleLabels!.containsKey(role.name)) {
      return roleLabels![role.name]!;
    }
    return presetModel.getLabel(role);
  }

  /// Returns point value for [role] using room custom points or default.
  int getPointsForRole(GameRole role) {
    if (rolePoints != null && rolePoints!.containsKey(role.name)) {
      return rolePoints![role.name]!;
    }
    return role.points;
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
