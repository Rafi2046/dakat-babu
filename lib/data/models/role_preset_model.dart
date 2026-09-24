import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';

/// Role naming preset — CPDB is the only production preset.
class RolePresetModel {
  final String id;
  final String name;
  final String description;
  final Map<GameRole, String> roleLabels;

  const RolePresetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.roleLabels,
  });

  static const RolePresetModel chorPoliceDakatBabu = RolePresetModel(
    id: 'chor_police_dakat_babu',
    name: 'Chor-Police-Dakat-Babu',
    description: 'Police, Babu, Chor, Dakat — classic Bangladeshi party game',
    roleLabels: {
      GameRole.police: 'Police',
      GameRole.babu: 'Babu',
      GameRole.chor: 'Chor',
      GameRole.dakat: 'Dakat',
    },
  );

  /// Alias kept for older call sites.
  static const RolePresetModel classic = chorPoliceDakatBabu;

  static const List<RolePresetModel> builtInPresets = [
    chorPoliceDakatBabu,
  ];

  static RolePresetModel fromId(String? id) {
    if (id == null) return chorPoliceDakatBabu;
    return builtInPresets.firstWhere(
      (p) => p.id == id,
      orElse: () => chorPoliceDakatBabu,
    );
  }

  String getLabel(GameRole role) => roleLabels[role] ?? role.shortName;

  Map<String, String> toLabelsJson() =>
      roleLabels.map((key, value) => MapEntry(key.name, value));

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
