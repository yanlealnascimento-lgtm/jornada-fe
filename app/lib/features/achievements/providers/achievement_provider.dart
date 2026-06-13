import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/achievement_repository.dart';
import '../../../shared/models/achievement_model.dart';

final achievementsProvider = FutureProvider.autoDispose<List<AchievementModel>>(
  (_) => achievementRepository.fetchAll(),
);

final userAchievementsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (_, userId) => achievementRepository.fetchUserAchievements(userId),
);
