import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/auth_service.dart';
import '../../features/gamification/services/lives_service.dart';

// Re-export for backward compatibility with existing screens.
export '../../features/onboarding/models/onboarding_data.dart';

// ── Estado global do usuário autenticado ─────────────────────────────────────

final currentUserProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  UserNotifier() : super(const AsyncValue.loading()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final hasSession = await AuthService.hasSession;
      if (hasSession) {
        await AuthService.restoreSession();
        try {
          final user = await AuthService.fetchMe();
          state = AsyncValue.data(user);
          // Sync backend data to SharedPreferences
          _syncUserToLocal(user);
        } catch (_) {
          // Offline mas tem token — cria usuário local a partir do storage
          state = const AsyncValue.data(null);
        }
      } else {
        // Sem sessão — usuário novo, estado nulo (redireciona para onboarding)
        state = const AsyncValue.data(null);
      }
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final result = await AuthService.login(email: email, password: password);
      state = AsyncValue.data(result.user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? denomination,
    int dailyGoalMinutes = 10,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await AuthService.register(
        name: name,
        email: email,
        password: password,
        denomination: denomination,
        dailyGoalMinutes: dailyGoalMinutes,
      );
      state = AsyncValue.data(result.user);
    } catch (e) {
      // Fallback offline — cria usuário local para não bloquear o fluxo
      state = AsyncValue.data(UserModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        streakCurrent: 0,
        streakBest: 0,
        pfTotal: 0,
        pfWeekly: 0,
        level: 1,
        energy: 20,
        manas: 10,
        denomination: denomination,
        dailyGoalMinutes: dailyGoalMinutes,
        leagueTier: 'bronze',
        leagueRank: 0,
      ));
    }
  }

  Future<void> logout() async {
    await AuthService.clearSession();
    state = const AsyncValue.data(null);
  }

  void updateLocally(UserModel updated) => state = AsyncValue.data(updated);

  Future<void> updateProfile({
    String? name,
    String? username,
    String? phone,
    String? avatarUrl,
    String? denomination,
    int? dailyGoalMinutes,
  }) async {
    final user = state.valueOrNull;
    if (user == null) return;

    try {
      final updated = await AuthService.updateProfile(
        userId: user.id,
        name: name,
        username: username,
        phone: phone,
        avatarUrl: avatarUrl,
        denomination: denomination,
        dailyGoalMinutes: dailyGoalMinutes,
      );
      state = AsyncValue.data(updated);
    } catch (_) {
      // Fallback: atualiza localmente se a API falhar
      state = AsyncValue.data(user.copyWith(
        name: name ?? user.name,
        username: username ?? user.username,
        phone: phone ?? user.phone,
        denomination: denomination ?? user.denomination,
        dailyGoalMinutes: dailyGoalMinutes ?? user.dailyGoalMinutes,
      ));
    }
  }

  Future<void> consumeEnergy() async {
    final u = state.valueOrNull;
    if (u != null && u.energy > 0) {
      state = AsyncValue.data(u.copyWith(energy: u.energy - 1));
      await LivesService.consumeLife();
    }
  }

  void gainPF(int amount) {
    final u = state.valueOrNull;
    if (u != null) {
      state = AsyncValue.data(u.copyWith(
        pfTotal: u.pfTotal + amount,
        pfWeekly: u.pfWeekly + amount,
      ));
    }
  }

  /// Sync backend user data to SharedPreferences so local providers stay in sync.
  Future<void> _syncUserToLocal(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    // Streak
    if (user.streakCurrent > 0) {
      final localStreak = prefs.getInt('streak_current') ?? 0;
      if (user.streakCurrent > localStreak) {
        await prefs.setInt('streak_current', user.streakCurrent);
      }
    }
    // Manas/Crystals — backend is source of truth
    await prefs.setInt('crystal_count', user.manas);
    // Energy — sync backend to local
    await prefs.setInt('lives_count', user.energy);
  }

  /// Refresh user data from the backend to get persisted pf_total, manas, etc.
  Future<void> refreshFromBackend() async {
    try {
      final user = await AuthService.fetchMe();
      state = AsyncValue.data(user);
      _syncUserToLocal(user);
    } catch (_) {
      // Keep local state if refresh fails
    }
  }

  void setUser(UserModel user) => state = AsyncValue.data(user);

  bool get isLoggedIn {
    final id = state.valueOrNull?.id ?? '';
    return id.isNotEmpty && !id.startsWith('mock') && !id.startsWith('offline');
  }
}

// ── Onboarding preferences ───────────────────────────────────────────────────
// Moved to: lib/features/onboarding/models/onboarding_data.dart
// Re-exported at the top of this file for backward compatibility.
