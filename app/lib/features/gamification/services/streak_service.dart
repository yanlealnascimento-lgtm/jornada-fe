import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/http_client.dart';
import 'crystal_service.dart';

/// Service for managing daily streak using SharedPreferences.
/// All methods are static — no instance needed.
class StreakService {
  static const _keyCurrentStreak = 'streak_current';
  static const _keyLastCompletedDate = 'streak_last_completed_date';
  static const _keyBestStreak = 'streak_best';

  StreakService._();

  /// Returns today's date as "yyyy-MM-dd".
  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  /// Returns yesterday's date as "yyyy-MM-dd".
  static String _yesterday() =>
      DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

  /// Gets the current streak count.
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentStreak) ?? 0;
  }

  /// Gets the best streak ever achieved.
  static Future<int> getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBestStreak) ?? 0;
  }

  /// Whether the user already completed an exercise today.
  static Future<bool> isCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastCompletedDate) ?? '';
    return lastDate == _today();
  }

  /// Called when the user completes an exercise.
  /// Increments streak once per day. If called multiple times on the same day,
  /// it's a no-op. Pass [userId] for backend sync.
  static Future<int> onExerciseCompleted({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    final lastDate = prefs.getString(_keyLastCompletedDate) ?? '';

    // Already counted today — no-op
    if (lastDate == today) {
      return prefs.getInt(_keyCurrentStreak) ?? 0;
    }

    int current = prefs.getInt(_keyCurrentStreak) ?? 0;

    if (lastDate == _yesterday()) {
      // Consecutive day — increment
      current += 1;
    } else if (lastDate.isNotEmpty) {
      // Missed days — check shield protection
      final missed = await daysMissed();
      if (missed == 1) {
        // Exactly 1 missed day — shield can protect
        final shields = await CrystalService.getCrystals();
        if (shields >= 1) {
          // Shield covers the gap — consume it, increment for today
          await CrystalService.consumeCrystals(1);
          current += 1;
        } else {
          // No shield — streak broken (reset to 0), today starts at 1
          current = 1;
        }
      } else if (missed > 1) {
        // Missed 2+ days — shield only covers 1 day, streak broken
        current = 1;
      } else {
        // No missed days (processMidnight already handled it)
        current += 1;
      }
    } else {
      // First time ever
      current = 1;
    }

    await prefs.setInt(_keyCurrentStreak, current);
    await prefs.setString(_keyLastCompletedDate, today);

    // Track best streak
    final best = prefs.getInt(_keyBestStreak) ?? 0;
    if (current > best) {
      await prefs.setInt(_keyBestStreak, current);
    }

    // Sync with backend
    _syncWithBackend(current, userId: userId);

    return current;
  }

  /// Gets the last completed date string (yyyy-MM-dd) or empty.
  static Future<String> getLastCompletedDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastCompletedDate) ?? '';
  }

  /// Resets the streak (e.g. when crystals run out).
  static Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentStreak, 0);
    await prefs.remove(_keyLastCompletedDate);
  }

  /// Days missed since last completed date (0 if completed today or yesterday).
  static Future<int> daysMissed() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastCompletedDate);
    if (lastDate == null || lastDate.isEmpty) return 0;

    try {
      final last = DateTime.parse(lastDate);
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = todayDate.difference(lastDay).inDays;
      // 0 = today, 1 = yesterday (still ok), 2+ = missed days
      return diff <= 1 ? 0 : diff - 1;
    } catch (_) {
      return 0;
    }
  }

  /// Syncs current streak to the backend. Fire-and-forget.
  static Future<void> _syncWithBackend(int streak, {String? userId}) async {
    try {
      await HttpClient.instance.patch(
        '/users/me/streak',
        data: {
          'streak_current': streak,
          if (userId != null) 'user_id': userId,
        },
      );
    } catch (e) {
      debugPrint('[StreakService] Sync failed (silent): $e');
    }
  }
}
