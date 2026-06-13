import 'dart:ui';

// ── Tier das 12 tribos de Israel ────────────────────────────────────────────

enum LeagueTier {
  ruben,
  simeao,
  levi,
  juda,
  da,
  naftali,
  gad,
  aser,
  issacar,
  zebulom,
  efraim,
  manasses;

  String get displayName {
    switch (this) {
      case LeagueTier.ruben:    return 'Rúben';
      case LeagueTier.simeao:   return 'Simeão';
      case LeagueTier.levi:     return 'Levi';
      case LeagueTier.juda:     return 'Judá';
      case LeagueTier.da:       return 'Dã';
      case LeagueTier.naftali:  return 'Naftali';
      case LeagueTier.gad:      return 'Gad';
      case LeagueTier.aser:     return 'Aser';
      case LeagueTier.issacar:  return 'Issacar';
      case LeagueTier.zebulom:  return 'Zebulom';
      case LeagueTier.efraim:   return 'Efraim';
      case LeagueTier.manasses: return 'Manassés';
    }
  }

  String get emoji {
    switch (this) {
      case LeagueTier.ruben:    return '🟤';
      case LeagueTier.simeao:   return '⚪';
      case LeagueTier.levi:     return '🟡';
      case LeagueTier.juda:     return '🦁';
      case LeagueTier.da:       return '🌊';
      case LeagueTier.naftali:  return '🦌';
      case LeagueTier.gad:      return '⚔️';
      case LeagueTier.aser:     return '✨';
      case LeagueTier.issacar:  return '📖';
      case LeagueTier.zebulom:  return '🌟';
      case LeagueTier.efraim:   return '💎';
      case LeagueTier.manasses: return '👑';
    }
  }

  Color get color {
    switch (this) {
      case LeagueTier.ruben:    return const Color(0xFFCD7F32);
      case LeagueTier.simeao:   return const Color(0xFFA8A9AD);
      case LeagueTier.levi:     return const Color(0xFFBF953F);
      case LeagueTier.juda:     return const Color(0xFFF5A623);
      case LeagueTier.da:       return const Color(0xFF4ECDC4);
      case LeagueTier.naftali:  return const Color(0xFF45B7D1);
      case LeagueTier.gad:      return const Color(0xFF96E6A1);
      case LeagueTier.aser:     return const Color(0xFFDDA0DD);
      case LeagueTier.issacar:  return const Color(0xFF7986CB);
      case LeagueTier.zebulom:  return const Color(0xFF4DB6AC);
      case LeagueTier.efraim:   return const Color(0xFFE57373);
      case LeagueTier.manasses: return const Color(0xFFFFD700);
    }
  }

  /// Rúben é a liga inicial — sem rebaixamento.
  bool get noDemotion => this == LeagueTier.ruben;

  static LeagueTier fromString(String value) {
    return LeagueTier.values.firstWhere(
      (t) => t.name == value,
      orElse: () => LeagueTier.ruben,
    );
  }
}

// ── Zona do membro no leaderboard ───────────────────────────────────────────

enum MemberZone { promotion, safe, demotion }

// ── Membro do leaderboard ───────────────────────────────────────────────────

class LeaderboardMember {
  final int position;
  final String memberId;
  final String displayName;
  final String avatarSeed;
  final int faithPoints;
  final bool isRealUser;
  final bool isMock;
  final MemberZone zone;

  const LeaderboardMember({
    required this.position,
    required this.memberId,
    required this.displayName,
    required this.avatarSeed,
    required this.faithPoints,
    required this.isRealUser,
    required this.isMock,
    required this.zone,
  });

  factory LeaderboardMember.fromJson(Map<String, dynamic> json) {
    MemberZone zone;
    final zoneStr = (json['zone'] ?? 'safe') as String;
    switch (zoneStr) {
      case 'promotion':
        zone = MemberZone.promotion;
        break;
      case 'demotion':
        zone = MemberZone.demotion;
        break;
      default:
        zone = MemberZone.safe;
    }

    return LeaderboardMember(
      position: ((json['position'] ?? json['rank'] ?? 0) as num).toInt(),
      memberId: (json['member_id'] ?? json['user_id'] ?? '') as String,
      displayName: (json['display_name'] ?? json['name'] ?? '') as String,
      avatarSeed: (json['avatar_seed'] ?? json['display_name'] ?? '') as String,
      faithPoints: ((json['faith_points'] ?? json['pf_weekly'] ?? json['xp_weekly'] ?? json['xp'] ?? 0) as num).toInt(),
      isRealUser: (json['is_real_user'] ?? json['is_current_user'] ?? false) as bool,
      isMock: (json['is_mock'] ?? false) as bool,
      zone: zone,
    );
  }
}

// ── Leaderboard completo da liga ────────────────────────────────────────────

class LeagueLeaderboard {
  final LeagueTier tier;
  final String weekKey;
  final List<LeaderboardMember> members;
  final int totalMembers;
  final int? userPosition;
  final int userFaithPoints;
  final int promotionZoneBottom;
  final int? demotionZoneTop;

  const LeagueLeaderboard({
    required this.tier,
    required this.weekKey,
    required this.members,
    required this.totalMembers,
    this.userPosition,
    required this.userFaithPoints,
    this.promotionZoneBottom = 5,
    this.demotionZoneTop,
  });

  /// Próxima liga (promoção).
  LeagueTier? get nextTier {
    final idx = tier.index;
    if (idx >= LeagueTier.values.length - 1) return null;
    return LeagueTier.values[idx + 1];
  }

  /// Liga anterior (rebaixamento).
  LeagueTier? get previousTier {
    if (tier.noDemotion) return null;
    final idx = tier.index;
    if (idx <= 0) return null;
    return LeagueTier.values[idx - 1];
  }

  bool isInPromotionZone(int position) => position <= promotionZoneBottom;

  bool isInDemotionZone(int position) {
    if (tier.noDemotion || demotionZoneTop == null) return false;
    return position >= demotionZoneTop!;
  }

  factory LeagueLeaderboard.fromJson(Map<String, dynamic> json) {
    final tierStr = (json['tier'] ?? 'ruben') as String;
    final tier = LeagueTier.fromString(tierStr);

    final membersList = (json['members'] as List? ?? [])
        .map((m) => LeaderboardMember.fromJson(m as Map<String, dynamic>))
        .toList();

    final totalMembers = ((json['total_members'] ?? membersList.length) as num).toInt();

    // Calcular demotionZoneTop: null para ruben, senão totalMembers - 4
    int? demotionZoneTop;
    if (!tier.noDemotion && totalMembers > 5) {
      demotionZoneTop = totalMembers - 4; // bottom 5
    }

    return LeagueLeaderboard(
      tier: tier,
      weekKey: (json['week_key'] ?? '') as String,
      members: membersList,
      totalMembers: totalMembers,
      userPosition: ((json['user_position'] ?? json['current_user_rank']) as num?)?.toInt(),
      userFaithPoints: ((json['user_faith_points'] ?? json['user_pf'] ?? json['user_xp'] ?? 0) as num).toInt(),
      promotionZoneBottom: ((json['promotion_zone_bottom'] ?? json['promotion_zone'] ?? 5) as num).toInt(),
      demotionZoneTop: demotionZoneTop,
    );
  }
}
