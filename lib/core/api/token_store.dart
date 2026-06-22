import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _tokenKey = 'nbts.auth.token';
  static const _userIdKey = 'nbts.auth.user_id';

  String? _cachedToken;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> load() async {
    final prefs = await _ensure();
    _cachedToken = prefs.getString(_tokenKey);
  }

  String? get token => _cachedToken;
  bool get isAuthenticated => _cachedToken != null && _cachedToken!.isNotEmpty;

  Future<void> save(String token, {int? userId}) async {
    final prefs = await _ensure();
    await prefs.setString(_tokenKey, token);
    if (userId != null) await prefs.setInt(_userIdKey, userId);
    _cachedToken = token;
  }

  Future<void> clear() async {
    final prefs = await _ensure();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    _cachedToken = null;
  }
}
