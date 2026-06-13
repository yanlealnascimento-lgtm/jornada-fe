/// Model de trilha retornado pela API (metadados do catálogo).
/// Diferente do TrailModel de lesson_model.dart que contém units/lessons embarcados.
class ApiTrailModel {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? thumbnailUrl;
  final CharacterRef? character;
  final int order;
  final bool isCore;
  final String? denomination;
  final int unlockLevel;
  final double estimatedHours;
  final bool isPremium;
  final bool isPublished;
  final int totalUnits;
  final int totalLessons;

  const ApiTrailModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.thumbnailUrl,
    this.character,
    required this.order,
    required this.isCore,
    this.denomination,
    required this.unlockLevel,
    required this.estimatedHours,
    required this.isPremium,
    required this.isPublished,
    required this.totalUnits,
    required this.totalLessons,
  });

  factory ApiTrailModel.fromJson(Map<String, dynamic> json) => ApiTrailModel(
    id:             (json['_id'] ?? json['id'] ?? '') as String,
    title:          (json['title'] ?? '') as String,
    slug:           (json['slug'] ?? '') as String,
    description:    (json['description'] ?? '') as String,
    thumbnailUrl:   json['thumbnail_url'] as String?,
    character:      json['character_id'] != null && json['character_id'] is Map
                      ? CharacterRef.fromJson(json['character_id'] as Map<String, dynamic>)
                      : null,
    order:          ((json['order'] ?? 0) as num).toInt(),
    isCore:         (json['is_core'] ?? true) as bool,
    denomination:   json['denomination'] as String?,
    unlockLevel:    ((json['unlock_level'] ?? 1) as num).toInt(),
    estimatedHours: ((json['estimated_hours'] ?? 1) as num).toDouble(),
    isPremium:      (json['is_premium'] ?? false) as bool,
    isPublished:    (json['is_published'] ?? false) as bool,
    totalUnits:     ((json['total_units'] ?? 0) as num).toInt(),
    totalLessons:   ((json['total_lessons'] ?? 0) as num).toInt(),
  );
}

class CharacterRef {
  final String id;
  final String name;
  final String? spriteUrl;
  final String? colorHex;

  const CharacterRef({
    required this.id,
    required this.name,
    this.spriteUrl,
    this.colorHex,
  });

  factory CharacterRef.fromJson(Map<String, dynamic> json) => CharacterRef(
    id:        (json['_id'] ?? json['id'] ?? '') as String,
    name:      (json['name'] ?? '') as String,
    spriteUrl: json['sprite_url'] as String?,
    colorHex:  json['color_hex'] as String?,
  );
}
