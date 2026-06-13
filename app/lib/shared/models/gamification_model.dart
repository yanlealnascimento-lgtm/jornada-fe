// CharacterModel e CharacterDialogue estão em character_model.dart
export 'character_model.dart';

enum LeagueTier { bronze, silver, gold, sapphire, onyx, diamond }

class LeagueData {
  final String id;
  final LeagueTier tier;
  final int userRank;
  final int userPfWeekly;
  final List<LeagueParticipant> participants;
  final DateTime endsAt;

  const LeagueData({
    required this.id,
    required this.tier,
    required this.userRank,
    required this.userPfWeekly,
    required this.participants,
    required this.endsAt,
  });

  factory LeagueData.fromJson(Map<String, dynamic> json) {
    LeagueTier tier;
    switch ((json['tier'] ?? '').toString().toLowerCase()) {
      case 'silver': tier = LeagueTier.silver; break;
      case 'gold': tier = LeagueTier.gold; break;
      case 'sapphire': tier = LeagueTier.sapphire; break;
      case 'onyx': tier = LeagueTier.onyx; break;
      case 'diamond': tier = LeagueTier.diamond; break;
      default: tier = LeagueTier.bronze;
    }

    return LeagueData(
      id: json['_id'] ?? json['id'] ?? '',
      tier: tier,
      userRank: json['user_rank'] ?? 0,
      userPfWeekly: json['user_pf_weekly'] ?? json['user_xp_weekly'] ?? 0,
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => LeagueParticipant.fromJson(p))
          .toList(),
      endsAt: DateTime.tryParse(json['ends_at'] ?? '') ?? DateTime.now().add(const Duration(days: 7)),
    );
  }
}

class LeagueParticipant {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int rank;
  final int pfWeekly;
  final int streakCurrent;
  final bool isCurrentUser;

  const LeagueParticipant({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.rank,
    required this.pfWeekly,
    required this.streakCurrent,
    required this.isCurrentUser,
  });

  factory LeagueParticipant.fromJson(Map<String, dynamic> json) {
    return LeagueParticipant(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'],
      rank: json['rank'] ?? 0,
      pfWeekly: json['pf_weekly'] ?? json['xp_weekly'] ?? 0,
      streakCurrent: json['streak_current'] ?? 0,
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }
}

class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String? verseReference;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String? unlockCondition;
  final int pfReward;
  final String rarity;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.verseReference,
    required this.isUnlocked,
    this.unlockedAt,
    this.unlockCondition,
    required this.pfReward,
    required this.rarity,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['icon_url'],
      verseReference: json['verse_reference'],
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null ? DateTime.tryParse(json['unlocked_at']) : null,
      unlockCondition: json['unlock_condition'],
      pfReward: json['pf_reward'] ?? json['xp_reward'] ?? 10,
      rarity: json['rarity'] ?? 'common',
    );
  }
}
