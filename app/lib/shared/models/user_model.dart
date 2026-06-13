class UserModel {
  final String id;
  final String name;
  final String? username;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int streakCurrent;
  final int streakBest;
  final int pfTotal;
  final int pfToNextLevel;
  final int pfWeekly;
  final int level;
  final int energy;
  final int manas;
  final String? denomination;
  final int dailyGoalMinutes;
  final String? fcmToken;
  final String? leagueTier;
  final int? leagueRank;

  const UserModel({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.streakCurrent,
    required this.streakBest,
    required this.pfTotal,
    this.pfToNextLevel = 1000,
    required this.pfWeekly,
    required this.level,
    this.energy = 20,
    required this.manas,
    this.denomination,
    required this.dailyGoalMinutes,
    this.fcmToken,
    this.leagueTier,
    this.leagueRank,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final pfTotal = (json['pf_total'] ?? json['xp_total'] ?? 0) as int;
    // Compute level from pfTotal (1000 PF per level) — override stale DB value
    final computedLevel = pfTotal ~/ 1000 + 1;
    final storedLevel = (json['level'] ?? 1) as int;

    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'],
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      streakCurrent: json['streak_current'] ?? 0,
      streakBest: json['streak_best'] ?? json['streak_longest'] ?? 0,
      pfTotal: pfTotal,
      pfToNextLevel: 1000,
      pfWeekly: json['pf_weekly'] ?? json['xp_weekly'] ?? 0,
      level: computedLevel > storedLevel ? computedLevel : storedLevel,
      energy: json['energy'] ?? json['hearts'] ?? 20,
      manas: json['manas'] ?? 0,
      denomination: json['denomination'],
      dailyGoalMinutes: json['daily_goal_minutes'] ?? 10,
      fcmToken: json['fcm_token'],
      leagueTier: json['league_tier'],
      leagueRank: json['league_rank'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'streak_current': streakCurrent,
      'streak_best': streakBest,
      'pf_total': pfTotal,
      'pf_to_next_level': pfToNextLevel,
      'pf_weekly': pfWeekly,
      'level': level,
      'energy': energy,
      'manas': manas,
      'denomination': denomination,
      'daily_goal_minutes': dailyGoalMinutes,
      'fcm_token': fcmToken,
      'league_tier': leagueTier,
      'league_rank': leagueRank,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? avatarUrl,
    int? streakCurrent,
    int? streakBest,
    int? pfTotal,
    int? pfToNextLevel,
    int? pfWeekly,
    int? level,
    int? energy,
    int? manas,
    String? denomination,
    int? dailyGoalMinutes,
    String? fcmToken,
    String? leagueTier,
    int? leagueRank,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      streakCurrent: streakCurrent ?? this.streakCurrent,
      streakBest: streakBest ?? this.streakBest,
      pfTotal: pfTotal ?? this.pfTotal,
      pfToNextLevel: pfToNextLevel ?? this.pfToNextLevel,
      pfWeekly: pfWeekly ?? this.pfWeekly,
      level: level ?? this.level,
      energy: energy ?? this.energy,
      manas: manas ?? this.manas,
      denomination: denomination ?? this.denomination,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      fcmToken: fcmToken ?? this.fcmToken,
      leagueTier: leagueTier ?? this.leagueTier,
      leagueRank: leagueRank ?? this.leagueRank,
    );
  }
}
