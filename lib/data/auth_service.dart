import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_client.dart';

/// Authentication against FreightDesk (`/api/auth/*`). Persists the bearer
/// token so the session survives app restarts.
class AuthService extends ChangeNotifier {
  AuthService(this._api);

  final ApiClient _api;

  static const _kToken = 'tf_token';

  AppUser? _user;
  String? _token;
  bool _loading = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;
  bool get loading => _loading;

  /// Restore a persisted token and re-validate it via `/api/auth/me`.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token == null) return;
    _api.setToken(token);
    _token = token;
    try {
      final me = await _api.getJson('/api/auth/me');
      _user = AppUser.fromJson((me as Map)['user'] as Map<String, dynamic>);
    } catch (_) {
      // Token expired / server unreachable — clear it.
      await _clear();
    }
    notifyListeners();
  }

  Future<void> login({required String phone, required String password}) async {
    await _run(() => _api.postJson('/api/auth/login', {
          'phone': phone,
          'password': password,
        }));
  }

  Future<void> register({
    required String phone,
    required String password,
    String? displayName,
    String? email,
  }) async {
    await _run(() => _api.postJson('/api/auth/register', {
          'phone': phone,
          'password': password,
          if (displayName != null && displayName.isNotEmpty)
            'display_name': displayName,
          if (email != null && email.isNotEmpty) 'email': email,
        }));
  }

  /// The logged-in contributor's submissions + status summary.
  Future<Map<String, dynamic>> myReports() async {
    final data = await _api.getJson('/api/auth/me/reports', {'limit': 50});
    return (data as Map).cast<String, dynamic>();
  }

  Future<void> logout() async {
    try {
      await _api.postJson('/api/auth/logout', {});
    } catch (_) {
      // Best-effort; clear locally regardless.
    }
    await _clear();
    notifyListeners();
  }

  Future<void> _run(Future<dynamic> Function() call) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await call() as Map;
      _token = data['token'] as String;
      _api.setToken(_token);
      _user = AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, _token!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _clear() async {
    _token = null;
    _user = null;
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
  }
}
