import 'package:flutter/material.dart';

class UserMissionModel {
  final String id;
  final String key;
  final String title;
  final String description;
  final String iconEmoji;
  final String cycle;
  final String triggerType;
  final int triggerValue;
  final String difficulty;
  final String rarity;
  final int pfReward;
  final int manaReward;
  final String? verseReference;
  final String? verseText;

  const UserMissionModel({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.cycle,
    required this.triggerType,
    required this.triggerValue,
    required this.difficulty,
    required this.rarity,
    required this.pfReward,
    required this.manaReward,
    this.verseReference,
    this.verseText,
  });

  factory UserMissionModel.fromJson(Map<String, dynamic> json) {
    final trigger = json['trigger'];
    String triggerType = '';
    int triggerValue = 1;
    if (trigger is Map) {
      triggerType = trigger['type']?.toString() ?? '';
      triggerValue = (trigger['value'] as num?)?.toInt() ?? 1;
    }

    return UserMissionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      key: json['key'] ?? '',
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      iconEmoji: json['icon_emoji'] ?? '🎯',
      cycle: json['cycle'] ?? 'one_time',
      triggerType: triggerType,
      triggerValue: triggerValue,
      difficulty: json['difficulty'] ?? '',
      rarity: json['rarity'] ?? 'common',
      pfReward: (json['pf_reward'] as num?)?.toInt() ?? (json['xp_reward'] as num?)?.toInt() ?? 0,
      manaReward: (json['mana_reward'] as num?)?.toInt() ?? 0,
      verseReference: json['verse_reference'],
      verseText: json['verse_text'],
    );
  }

  bool get isCompleted => false; // Will be tracked via user achievements later

  Color get difficultyColor {
    switch (difficulty) {
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF22C55E);
    }
  }

  Color get difficultyBgColor {
    switch (difficulty) {
      case 'medium':
        return const Color(0xFFFEF3C7);
      case 'hard':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'medium':
        return 'Médio';
      case 'hard':
        return 'Difícil';
      default:
        return 'Fácil';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case 'rare':
        return const Color(0xFF3B82F6);
      case 'epic':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case 'rare':
        return 'Raro';
      case 'epic':
        return 'Épico';
      default:
        return 'Comum';
    }
  }

  String get triggerLabel {
    switch (triggerType) {
      case 'lesson_count':
        return 'Lições';
      case 'streak_days':
      case 'streak_maintain':
        return 'Streak';
      case 'xp_earn':
        return 'PF Ganhos';
      case 'perfect_lesson':
        return 'Perfeitas';
      case 'trail_progress':
        return 'Trilha';
      case 'study_complete':
        return 'Estudos';
      case 'invite_count':
        return 'Convites';
      default:
        return 'Meta';
    }
  }
}
