import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'http_client.dart';
import '../models/user_model.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'jf_access_token';
  static const _userIdKey = 'jf_user_id';

  // ── Token ────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    HttpClient.instance.setAuthToken(token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
    HttpClient.instance.clearAuthToken();
  }

  static Future<bool> get hasSession async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await HttpClient.instance.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data['data'];
    final token = data['token'] as String;
    await saveToken(token);
    await _storage.write(key: _userIdKey, value: data['user']['id'].toString());
    return AuthResult(
      token: token,
      user: _mapUser(data['user']),
    );
  }

  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? denomination,
    int dailyGoalMinutes = 10,
  }) async {
    final response = await HttpClient.instance.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'denomination': denomination,
      'daily_goal_minutes': dailyGoalMinutes,
    });
    final data = response.data['data'];
    final token = data['token'] as String;
    await saveToken(token);
    await _storage.write(key: _userIdKey, value: data['user']['id'].toString());
    return AuthResult(
      token: token,
      user: _mapUser(data['user']),
    );
  }

  static Future<UserModel> fetchMe() async {
    final response = await HttpClient.instance.get('/auth/me');
    return UserModel.fromJson(response.data['data']);
  }

  static Future<void> restoreSession() async {
    final token = await getToken();
    if (token != null) {
      HttpClient.instance.setAuthToken(token);
    }
  }

  /// Atualiza o perfil do usuário no backend (PUT /users/:id)
  static Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? username,
    String? phone,
    String? avatarUrl,
    String? denomination,
    int? dailyGoalMinutes,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (username != null) data['username'] = username;
    if (phone != null) data['phone'] = phone;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (denomination != null) data['denomination'] = denomination;
    if (dailyGoalMinutes != null) data['daily_goal_minutes'] = dailyGoalMinutes;

    final response = await HttpClient.instance.put('/users/$userId', data: data);
    final raw = response.data['data'];
    return UserModel.fromJson(raw is Map<String, dynamic> ? raw : {});
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  static UserModel _mapUser(Map<String, dynamic> raw) {
    return UserModel(
      id: raw['id']?.toString() ?? '',
      name: raw['name'] ?? '',
      username: raw['username'],
      email: raw['email'] ?? '',
      phone: raw['phone'],
      avatarUrl: raw['avatar_url'],
      streakCurrent: raw['streak_current'] ?? 0,
      streakBest: raw['streak_best'] ?? 0,
      pfTotal: raw['pf_total'] ?? raw['xp_total'] ?? 0,
      pfToNextLevel: raw['pf_to_next_level'] ?? raw['xp_to_next_level'] ?? 100,
      pfWeekly: raw['pf_weekly'] ?? raw['xp_weekly'] ?? 0,
      level: raw['level'] ?? 1,
      energy: raw['energy'] ?? raw['hearts'] ?? 20,
      manas: raw['manas'] ?? 200,
      denomination: raw['denomination'],
      dailyGoalMinutes: raw['daily_goal_minutes'] ?? 10,
      leagueTier: raw['league_tier'] ?? 'bronze',
      leagueRank: raw['league_rank'] ?? 0,
    );
  }
}

class AuthResult {
  final String token;
  final UserModel user;
  const AuthResult({required this.token, required this.user});
}
