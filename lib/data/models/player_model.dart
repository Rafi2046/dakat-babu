import '../../core/constants/app_constants.dart';

/// Data model representing a player in a DakatBabu room.
class PlayerModel {
  /// Unique identifier for the player (UUID or device ID).
  final String id;

  /// Room code this player belongs to.
  final String roomCode;

  /// Display name chosen by the player.
  final String name;

  /// Optional avatar URL or preset identifier.
  final String? avatarUrl;

  /// Whether this player is the room creator and game host.
  final bool isHost;

  /// Secret role assigned during an active round (null in lobby).
  final GameRole? role;

  /// Cumulative score across rounds in the current session.
  final int score;

  /// Whether the player has marked themselves ready in the lobby.
  final bool isReady;

  /// Timestamp when the player joined the room.
  final DateTime createdAt;

  const PlayerModel({
    required this.id,
    required this.roomCode,
    required this.name,
    this.avatarUrl,
    this.isHost = false,
    this.role,
    this.score = 0,
    this.isReady = false,
    required this.createdAt,
  });

  /// Creates a copy of this player with updated fields.
  PlayerModel copyWith({
    String? id,
    String? roomCode,
    String? name,
    String? avatarUrl,
    bool? isHost,
    GameRole? role,
    int? score,
    bool? isReady,
    DateTime? createdAt,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isHost: isHost ?? this.isHost,
      role: role ?? this.role,
      score: score ?? this.score,
      isReady: isReady ?? this.isReady,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Deserializes a [PlayerModel] from a JSON map (e.g. Supabase response).
  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      roomCode: json['room_code'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isHost: (json['is_host'] as bool?) ?? false,
      role: GameRole.tryParse(json['role'] as String?),
      score: (json['score'] as num?)?.toInt() ?? 0,
      isReady: (json['is_ready'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Serializes this [PlayerModel] into a Supabase-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_code': roomCode,
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'is_host': isHost,
      if (role != null) 'role': role!.name,
      'score': score,
      'is_ready': isReady,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          roomCode == other.roomCode &&
          role == other.role &&
          score == other.score &&
          isReady == other.isReady;

  @override
  int get hashCode => id.hashCode ^ roomCode.hashCode ^ score.hashCode;
}
