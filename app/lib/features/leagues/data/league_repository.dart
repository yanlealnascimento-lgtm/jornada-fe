import 'package:flutter/foundation.dart';
import '../../../shared/models/league_model.dart';
import '../../../shared/services/http_client.dart';

class LeagueRepository {
  Future<LeagueLeaderboard> fetchLeaderboard(String userId) async {
    try {
      final response = await HttpClient.instance.get(
        '/leagues/me',
        queryParams: {'user_id': userId},
      );
      final data = (response.data is Map && response.data['data'] != null)
          ? response.data['data']
          : response.data;
      return LeagueLeaderboard.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[LeagueRepository] Error fetching leaderboard: $e');
      rethrow;
    }
  }
}

final leagueRepository = LeagueRepository();
