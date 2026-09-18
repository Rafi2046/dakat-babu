import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';

/// Represents a configurable naming and styling preset for game roles.
class RolePresetModel {
  /// Unique identifier for the preset (e.g., 'classic', 'chor_police_dakat_babu', 'custom').
  final String id;

  /// Display name of the preset.
  final String name;

  /// Descriptive subtitle for the preset.
  final String description;

  /// Mapping from [GameRole] to custom role display name.
  final Map<GameRole, String> roleLabels;

  const RolePresetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.roleLabels,
  });

  /// Classic Raja-Mantri-Police-Chor preset.
  static const RolePresetModel classic = RolePresetModel(
    id: 'classic',
    name: 'Classic (Raja-Mantri)',
    description: 'Traditional Royal Court: Raja, Mantri, Police, Chor',
    roleLabels: {
      GameRole.raja: 'Raja',
      GameRole.mantri: 'Mantri',
      GameRole.police: 'Police',
      GameRole.chor: 'Chor',
      GameRole.chintaykari: 'Chintaykari',
      GameRole.batpar: 'Batpar',
    },
  );

  /// Chor, Police, Dakat, Babu preset.
  static const RolePresetModel chorPoliceDakatBabu = RolePresetModel(
    id: 'chor_police_dakat_babu',
    name: 'Chor-Police-Dakat-Babu',
    description: 'Babu (King), Dewan (Mantri), Police, Dakat (Thief)',
    roleLabels: {
      GameRole.raja: 'Babu',
      GameRole.mantri: 'Dewan',
      GameRole.police: 'Police',
      GameRole.chor: 'Dakat',
      GameRole.chintaykari: 'Chintaykari',
      GameRole.batpar: 'Batpar',
    },
  );

  /// All available built-in presets.
  static const List<RolePresetModel> builtInPresets = [
    classic,
    chorPoliceDakatBabu,
  ];

  /// Finds preset by ID, falling back to [classic].
  static RolePresetModel fromId(String? id) {
    if (id == null) return classic;
    return builtInPresets.firstWhere(
      (p) => p.id == id,
      orElse: () => classic,
    );
  }

  /// Gets the custom label for [role], or standard role shortName as fallback.
  String getLabel(GameRole role) {
    return roleLabels[role] ?? role.shortName;
  }

  /// Converts roleLabels to a JSON-serializable `Map<String, String>`.
  Map<String, String> toLabelsJson() {
    return roleLabels.map((key, value) => MapEntry(key.name, value));
  }

  /// Recreates [RolePresetModel] from stored JSON.
  factory RolePresetModel.fromJson({
    required String id,
    required String name,
    required String description,
    required Map<String, dynamic> labelsJson,
  }) {
    final labels = <GameRole, String>{};
    for (final entry in labelsJson.entries) {
      final role = GameRole.tryParse(entry.key);
      if (role != null) {
        labels[role] = entry.value.toString();
      }
    }
    // Fill in defaults if any role is missing
    for (final role in GameRole.values) {
      labels.putIfAbsent(role, () => role.shortName);
    }
    return RolePresetModel(
      id: id,
      name: name,
      description: description,
      roleLabels: labels,
    );
  }

  /// Creates a copy with optionally modified role labels.
  RolePresetModel copyWith({
    String? id,
    String? name,
    String? description,
    Map<GameRole, String>? roleLabels,
  }) {
    return RolePresetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      roleLabels: roleLabels ?? Map.from(this.roleLabels),
    );
  }
}
