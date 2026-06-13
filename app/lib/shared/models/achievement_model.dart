import 'dart:ui';

class AchievementModel {
  final String id;
  final String key;
  final String name;
  final String description;
  final String? verseReference;
  final String? verseText;
  final String iconEmoji;
  final String rarity;
  final int pfReward;
  final int manaReward;
  final bool isActive;

  const AchievementModel({
    required this.id, required this.key, required this.name,
    required this.description, this.verseReference, this.verseText,
    required this.iconEmoji, required this.rarity,
    required this.pfReward, required this.manaReward, required this.isActive,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) => AchievementModel(
    id: (json['_id'] ?? json['id'] ?? '') as String,
    key: (json['key'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    description: (json['description'] ?? '') as String,
    verseReference: json['verse_reference'] as String?,
    verseText: json['verse_text'] as String?,
    iconEmoji: (json['icon_emoji'] ?? '🏆') as String,
    rarity: (json['rarity'] ?? 'common') as String,
    pfReward: ((json['pf_reward'] ?? json['xp_reward'] ?? 0) as num).toInt(),
    manaReward: ((json['mana_reward'] ?? 0) as num).toInt(),
    isActive: (json['is_active'] ?? true) as bool,
  );

  Color get rarityColor {
    switch (rarity) {
      case 'rare': return const Color(0xFF1D4ED8);
      case 'epic': return const Color(0xFF7C3AED);
      default: return const Color(0xFF6B7280);
    }
  }
}

class UserAchievementModel {
  final String id;
  final AchievementModel achievement;
  final DateTime unlockedAt;

  const UserAchievementModel({
    required this.id, required this.achievement, required this.unlockedAt,
  });

  factory UserAchievementModel.fromJson(Map<String, dynamic> json) =>
    UserAchievementModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      achievement: AchievementModel.fromJson(json['achievement_id'] as Map<String, dynamic>),
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
}
