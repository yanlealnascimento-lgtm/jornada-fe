import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/http_client.dart';

/// Service for managing lives (hearts) using SharedPreferences.
/// Lives recharge over time. Premium users recharge faster.
class LivesService {
  static const int maxLives = 20;
  static const int rechargeIntervalMinutes = 30;
  static const int premiumRechargeIntervalMinutes = 15;

  static const _keyLives = 'lives_count';
  static const _keyLastLostTimestamp = 'lives_last_lost_timestamp';

  LivesService._();

  /// Returns the current lives state, accounting for time-based recharge.
  static Future<LivesState> getLivesState({bool isPremium = false}) async {
    final prefs = await SharedPreferences.getInstance();
    int lives = prefs.getInt(_keyLives) ?? maxLives;
    final lastLostMs = prefs.getInt(_keyLastLostTimestamp) ?? 0;

    if (lives < maxLives && lastLostMs > 0) {
      final interval = isPremium
          ? premiumRechargeIntervalMinutes
          : rechargeIntervalMinutes;
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastLostMs;
      final recharged = elapsed ~/ (interval * 60 * 1000);

      if (recharged > 0) {
        lives = (lives + recharged).clamp(0, maxLives);
        await prefs.setInt(_keyLives, lives);
        if (lives >= maxLives) {
          await prefs.remove(_keyLastLostTimestamp);
        } else {
          // Advance the timestamp by the recharged intervals
          final advancedMs = lastLostMs + recharged * interval * 60 * 1000;
          await prefs.setInt(_keyLastLostTimestamp, advancedMs);
        }
      }
    }

    // Calculate time until next recharge
    Duration? nextRechargeIn;
    if (lives < maxLives) {
      final interval = isPremium
          ? premiumRechargeIntervalMinutes
          : rechargeIntervalMinutes;
      final currentLastLost = prefs.getInt(_keyLastLostTimestamp) ?? 0;
      if (currentLastLost > 0) {
        final nextRechargeMs = currentLastLost + interval * 60 * 1000;
        final remaining = nextRechargeMs - DateTime.now().millisecondsSinceEpoch;
        if (remaining > 0) {
          nextRechargeIn = Duration(milliseconds: remaining);
        }
      }
    }

    return LivesState(
      current: lives,
      max: maxLives,
      nextRechargeIn: nextRechargeIn,
    );
  }

  /// Consumes one life. Returns the updated count, or -1 if no lives available.
  static Future<int> consumeLife() async {
    final prefs = await SharedPreferences.getInstance();
    int lives = prefs.getInt(_keyLives) ?? maxLives;

    if (lives <= 0) return -1;

    lives -= 1;
    await prefs.setInt(_keyLives, lives);
    await prefs.setInt(_keyLastLostTimestamp, DateTime.now().millisecondsSinceEpoch);

    // Sync to backend (fire-and-forget)
    _syncEnergyToBackend(lives);

    return lives;
  }

  /// Grants [amount] lives (capped at max). Used for bonus rewards.
  static Future<int> grantLives(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int lives = prefs.getInt(_keyLives) ?? maxLives;
    lives = (lives + amount).clamp(0, maxLives);
    await prefs.setInt(_keyLives, lives);
    if (lives >= maxLives) {
      await prefs.remove(_keyLastLostTimestamp);
    }
    _syncEnergyToBackend(lives);
    return lives;
  }

  /// Recharges all lives to max (e.g. via reward or purchase).
  static Future<void> rechargeAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLives, maxLives);
    await prefs.remove(_keyLastLostTimestamp);

    // Sync to backend
    _syncEnergyToBackend(maxLives);
  }

  /// Fire-and-forget sync to backend.
  static Future<void> _syncEnergyToBackend(int energy) async {
    try {
      await HttpClient.instance.patch('/users/me/energy', data: {
        'energy': energy,
      });
    } catch (_) {
      debugPrint('[LivesService] Energy sync failed (silent)');
    }
  }
}

/// Immutable snapshot of the lives state.
class LivesState {
  final int current;
  final int max;
  final Duration? nextRechargeIn;

  const LivesState({
    required this.current,
    required this.max,
    this.nextRechargeIn,
  });
}
