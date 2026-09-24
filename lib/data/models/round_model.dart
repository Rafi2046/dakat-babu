/// State machine stages of a single game round.
enum RoundStatus {
  /// Players are viewing their secret role cards.
  roleReveal,

  /// Police is selecting a suspect.
  policeGuessing,

  /// Guess resolved; scores updated.
  completed;

  static RoundStatus parse(String? value) {
    if (value == null) return RoundStatus.roleReveal;
    switch (value.toLowerCase()) {
      case 'police_guessing':
      case 'policeguessing':
        return RoundStatus.policeGuessing;
      case 'completed':
        return RoundStatus.completed;
      case 'role_reveal':
      case 'rolereveal':
      default:
        return RoundStatus.roleReveal;
    }
  }

  String toDbValue() {
    switch (this) {
      case RoundStatus.roleReveal:
        return 'role_reveal';
      case RoundStatus.policeGuessing:
        return 'police_guessing';
      case RoundStatus.completed:
        return 'completed';
    }
  }
}

/// Data model representing an individual round in a match.
class RoundModel {
  final String id;
  final String roomCode;
  final int roundNumber;
  final String policePlayerId;
  final String babuPlayerId;
  final String chorPlayerId;
  final String dakatPlayerId;
  final String? policeGuessPlayerId;
  final bool? isGuessCorrect;
  final RoundStatus status;
  final DateTime createdAt;

  const RoundModel({
    required this.id,
    required this.roomCode,
    required this.roundNumber,
    required this.policePlayerId,
    required this.babuPlayerId,
    required this.chorPlayerId,
    required this.dakatPlayerId,
    this.policeGuessPlayerId,
    this.isGuessCorrect,
    this.status = RoundStatus.roleReveal,
    required this.createdAt,
  });

  RoundModel copyWith({
    String? id,
    String? roomCode,
    int? roundNumber,
    String? policePlayerId,
    String? babuPlayerId,
    String? chorPlayerId,
    String? dakatPlayerId,
    String? policeGuessPlayerId,
    bool? isGuessCorrect,
    RoundStatus? status,
    DateTime? createdAt,
  }) {
    return RoundModel(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      roundNumber: roundNumber ?? this.roundNumber,
      policePlayerId: policePlayerId ?? this.policePlayerId,
      babuPlayerId: babuPlayerId ?? this.babuPlayerId,
      chorPlayerId: chorPlayerId ?? this.chorPlayerId,
      dakatPlayerId: dakatPlayerId ?? this.dakatPlayerId,
      policeGuessPlayerId: policeGuessPlayerId ?? this.policeGuessPlayerId,
      isGuessCorrect: isGuessCorrect ?? this.isGuessCorrect,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RoundModel.fromJson(Map<String, dynamic> json) {
    // Support legacy raja/mantri columns during migration.
    final babuId = (json['babu_player_id'] ?? json['raja_player_id']) as String;
    final dakatId =
        (json['dakat_player_id'] ?? json['mantri_player_id']) as String?;
    return RoundModel(
      id: json['id'] as String,
      roomCode: json['room_code'] as String,
      roundNumber: (json['round_number'] as num?)?.toInt() ?? 1,
      policePlayerId: json['police_player_id'] as String,
      babuPlayerId: babuId,
      chorPlayerId: json['chor_player_id'] as String,
      dakatPlayerId: dakatId ?? (json['dakat_player_id'] as String? ?? ''),
      policeGuessPlayerId: json['police_guess_player_id'] as String?,
      isGuessCorrect: json['is_guess_correct'] as bool?,
      status: RoundStatus.parse(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_code': roomCode,
      'round_number': roundNumber,
      'police_player_id': policePlayerId,
      'babu_player_id': babuPlayerId,
      'chor_player_id': chorPlayerId,
      'dakat_player_id': dakatPlayerId,
      if (policeGuessPlayerId != null)
        'police_guess_player_id': policeGuessPlayerId,
      if (isGuessCorrect != null) 'is_guess_correct': isGuessCorrect,
      'status': status.toDbValue(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoundModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          roomCode == other.roomCode &&
          roundNumber == other.roundNumber &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ roomCode.hashCode ^ roundNumber.hashCode;
}
