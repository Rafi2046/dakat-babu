/// State machine stages of a single game round.
enum RoundStatus {
  /// Players are viewing their secret role cards; Raja declares himself.
  roleReveal,

  /// Police is interrogating players and making a deduction.
  policeGuessing,

  /// Police submitted guess; scores calculated and revealed.
  completed;

  /// Parses a status string into [RoundStatus].
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

  /// Serializes enum to snake_case for Supabase.
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
  /// Round record UUID.
  final String id;

  /// Associated room code.
  final String roomCode;

  /// Round sequence number (1, 2, 3...).
  final int roundNumber;

  /// Player ID assigned to the Raja role.
  final String rajaPlayerId;

  /// Player ID assigned to the Mantri role.
  final String mantriPlayerId;

  /// Player ID assigned to the Police role.
  final String policePlayerId;

  /// Player ID assigned to the Chor role.
  final String chorPlayerId;

  /// Suspect player ID chosen by the Police (null until submitted).
  final String? policeGuessPlayerId;

  /// Whether the Police accurately picked the Chor.
  final bool? isGuessCorrect;

  /// Current status phase of this round.
  final RoundStatus status;

  /// Round start timestamp.
  final DateTime createdAt;

  const RoundModel({
    required this.id,
    required this.roomCode,
    required this.roundNumber,
    required this.rajaPlayerId,
    required this.mantriPlayerId,
    required this.policePlayerId,
    required this.chorPlayerId,
    this.policeGuessPlayerId,
    this.isGuessCorrect,
    this.status = RoundStatus.roleReveal,
    required this.createdAt,
  });

  /// Creates a copy of this round model with updated fields.
  RoundModel copyWith({
    String? id,
    String? roomCode,
    int? roundNumber,
    String? rajaPlayerId,
    String? mantriPlayerId,
    String? policePlayerId,
    String? chorPlayerId,
    String? policeGuessPlayerId,
    bool? isGuessCorrect,
    RoundStatus? status,
    DateTime? createdAt,
  }) {
    return RoundModel(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      roundNumber: roundNumber ?? this.roundNumber,
      rajaPlayerId: rajaPlayerId ?? this.rajaPlayerId,
      mantriPlayerId: mantriPlayerId ?? this.mantriPlayerId,
      policePlayerId: policePlayerId ?? this.policePlayerId,
      chorPlayerId: chorPlayerId ?? this.chorPlayerId,
      policeGuessPlayerId: policeGuessPlayerId ?? this.policeGuessPlayerId,
      isGuessCorrect: isGuessCorrect ?? this.isGuessCorrect,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Deserializes a [RoundModel] from a JSON map.
  factory RoundModel.fromJson(Map<String, dynamic> json) {
    return RoundModel(
      id: json['id'] as String,
      roomCode: json['room_code'] as String,
      roundNumber: (json['round_number'] as num?)?.toInt() ?? 1,
      rajaPlayerId: json['raja_player_id'] as String,
      mantriPlayerId: json['mantri_player_id'] as String,
      policePlayerId: json['police_player_id'] as String,
      chorPlayerId: json['chor_player_id'] as String,
      policeGuessPlayerId: json['police_guess_player_id'] as String?,
      isGuessCorrect: json['is_guess_correct'] as bool?,
      status: RoundStatus.parse(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Serializes this [RoundModel] into a Supabase-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_code': roomCode,
      'round_number': roundNumber,
      'raja_player_id': rajaPlayerId,
      'mantri_player_id': mantriPlayerId,
      'police_player_id': policePlayerId,
      'chor_player_id': chorPlayerId,
      if (policeGuessPlayerId != null) 'police_guess_player_id': policeGuessPlayerId,
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
