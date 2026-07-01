import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _tokenKey = 'nbts.auth.token';
  static const _userIdKey = 'nbts.auth.user_id';

  String? _cachedToken;
  int? _cachedUserId;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> load() async {
    final prefs = await _ensurePrefs();
    _cachedToken = prefs.getString(_tokenKey);
    _cachedUserId = prefs.getInt(_userIdKey);
  }

  String? get token => _cachedToken;
  int? get userId => _cachedUserId;
  bool get isAuthenticated => _cachedToken != null && _cachedToken!.isNotEmpty;

  Future<void> save(String token, {int? userId}) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_tokenKey, token);
    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    } else {
      await prefs.remove(_userIdKey);
    }
    _cachedToken = token;
    _cachedUserId = userId;
  }

  Future<void> clear() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    _cachedToken = null;
    _cachedUserId = null;
  }
}
