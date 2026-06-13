import 'package:flutter/foundation.dart';
import '../../../shared/models/achievement_model.dart';
import '../../../shared/services/http_client.dart';

class AchievementRepository {
  Future<List<AchievementModel>> fetchAll() async {
    try {
      final response = await HttpClient.instance.get('/achievements');
      final data = response.data;
      final List list = (data is Map)
          ? (data['data']?['achievements'] ?? data['achievements'] ?? []) as List
          : [];
      return list.map((j) => AchievementModel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[AchievementRepository] Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchUserAchievements(String userId) async {
    final response = await HttpClient.instance.get('/achievements/user/$userId');
    final data = (response.data is Map && response.data['data'] != null) ? response.data['data'] : response.data;
    return {
      'unlocked': ((data['unlocked'] ?? []) as List)
          .map((j) => UserAchievementModel.fromJson(j as Map<String, dynamic>))
          .toList(),
      'locked': ((data['locked'] ?? []) as List)
          .map((j) => AchievementModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    };
  }
}

final achievementRepository = AchievementRepository();
