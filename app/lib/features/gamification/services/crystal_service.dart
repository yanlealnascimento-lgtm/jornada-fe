import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'streak_service.dart';

/// Service for managing the Escudo de Devocao (Streak Shield).
/// The user can have at most 1 shield active at a time.
/// The shield protects the streak for exactly 1 missed day.
/// If more than 1 day is missed, the streak is broken.
class CrystalService {
  static const int maxShields = 1;

  static const _keyShieldCount = 'crystal_count';
  static const _keyLastProcessedDate = 'crystal_last_processed_date';

  CrystalService._();

  /// Returns today's date as "yyyy-MM-dd".
  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  /// Gets the current shield count (0 or 1).
  static Future<int> getCrystals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyShieldCount) ?? 0;
  }

  /// Adds a shield (e.g. purchased from shop). Clamped to [maxShields].
  static Future<int> addCrystals(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyShieldCount) ?? 0;
    final updated = (current + amount).clamp(0, maxShields);
    await prefs.setInt(_keyShieldCount, updated);
    return updated;
  }

  /// Consumes shields. Returns true if successful, false if not enough.
  static Future<bool> consumeCrystals(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyShieldCount) ?? 0;
    if (current < amount) return false;
    await prefs.setInt(_keyShieldCount, current - amount);
    return true;
  }

  /// Process midnight check — called on app resume or daily.
  ///
  /// Rules (from gamificacao-jornada-da-fe.md):
  /// - Shield protects exactly 1 missed day
  /// - If user missed 1 day and has 1 shield → shield consumed, streak preserved
  /// - If user missed 2+ days → even with shield, streak is broken (reset to 0)
  /// - If user missed 1 day and has no shield → streak broken (reset to 0)
  static Future<MidnightResult> processMidnight() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    final lastProcessed = prefs.getString(_keyLastProcessedDate) ?? '';

    // Already processed today
    if (lastProcessed == today) {
      final shields = prefs.getInt(_keyShieldCount) ?? 0;
      return MidnightResult(crystalsRemaining: shields, daysProtected: 0, streakBroken: false);
    }

    final missed = await StreakService.daysMissed();

    if (missed <= 0) {
      await prefs.setString(_keyLastProcessedDate, today);
      final shields = prefs.getInt(_keyShieldCount) ?? 0;
      return MidnightResult(crystalsRemaining: shields, daysProtected: 0, streakBroken: false);
    }

    int shields = prefs.getInt(_keyShieldCount) ?? 0;
    int daysProtected = 0;
    bool streakBroken = false;

    if (missed == 1 && shields >= 1) {
      // Shield covers exactly 1 missed day — consume it, preserve streak
      shields -= 1;
      daysProtected = 1;
    } else {
      // Missed 2+ days OR missed 1 day without shield → streak broken
      streakBroken = true;
      await StreakService.resetStreak();
    }

    await prefs.setInt(_keyShieldCount, shields);
    await prefs.setString(_keyLastProcessedDate, today);

    // If shield protected the missed day, update last completed date
    // to yesterday so onExerciseCompleted sees a consecutive chain.
    if (daysProtected > 0 && !streakBroken) {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      await prefs.setString('streak_last_completed_date', yesterday);
    }

    debugPrint('[CrystalService] processMidnight: missed=$missed, protected=$daysProtected, broken=$streakBroken, remaining=$shields');

    return MidnightResult(
      crystalsRemaining: shields,
      daysProtected: daysProtected,
      streakBroken: streakBroken,
    );
  }
}

/// Result of midnight processing.
class MidnightResult {
  final int crystalsRemaining;
  final int daysProtected;
  final bool streakBroken;

  const MidnightResult({
    required this.crystalsRemaining,
    required this.daysProtected,
    required this.streakBroken,
  });
}
