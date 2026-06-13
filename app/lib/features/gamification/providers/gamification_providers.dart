import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';
import '../services/crystal_service.dart';
import '../services/lives_service.dart';

/// Provides the current streak count.
final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  return StreakService.getCurrentStreak();
});

/// Whether the user completed an exercise today.
final completedTodayProvider = FutureProvider.autoDispose<bool>((ref) async {
  return StreakService.isCompletedToday();
});

/// Provides the current crystal count.
final crystalProvider = FutureProvider.autoDispose<int>((ref) async {
  return CrystalService.getCrystals();
});

/// Provides the current lives state.
final livesProvider = FutureProvider.autoDispose<LivesState>((ref) async {
  // TODO: pass isPremium from user model when premium is implemented
  return LivesService.getLivesState(isPremium: false);
});

/// Helper to invalidate all gamification providers at once.
/// Call this after any action that may change gamification state
/// (e.g. completing an exercise, consuming a life, etc.).
void invalidateGamificationProviders(dynamic ref) {
  // ref can be WidgetRef or Ref — both support invalidate
  ref.invalidate(streakProvider);
  ref.invalidate(completedTodayProvider);
  ref.invalidate(crystalProvider);
  ref.invalidate(livesProvider);
}
