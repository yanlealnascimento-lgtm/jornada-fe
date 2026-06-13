import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/league_model.dart';
import '../data/league_repository.dart';

final leagueLeaderboardProvider = FutureProvider.autoDispose<LeagueLeaderboard>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

  if (user == null || user.id.isEmpty) {
    throw Exception('Usuário não autenticado');
  }

  return leagueRepository.fetchLeaderboard(user.id);
});
