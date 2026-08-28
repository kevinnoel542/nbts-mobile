import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _tokenKey = 'nbts.auth.token';
  static const _userIdKey = 'nbts.auth.user_id';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _cachedToken;
  int? _cachedUserId;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> load() async {
    final prefs = await _ensurePrefs();
    final secureToken = await _secureStorage.read(key: _tokenKey);
    final legacyToken = prefs.getString(_tokenKey);
    final secureUserId = await _secureStorage.read(key: _userIdKey);
    final legacyUserId = prefs.getInt(_userIdKey);

    _cachedToken = _cleanToken(secureToken) ?? _cleanToken(legacyToken);
    _cachedUserId = int.tryParse(secureUserId ?? '') ?? legacyUserId;

    if (_cachedToken != null && secureToken == null) {
      await _secureStorage.write(key: _tokenKey, value: _cachedToken);
    }
    if (_cachedUserId != null && secureUserId == null) {
      await _secureStorage.write(key: _userIdKey, value: '$_cachedUserId');
    }

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  String? get token => _cachedToken;
  int? get userId => _cachedUserId;
  bool get isAuthenticated => _cachedToken != null && _cachedToken!.isNotEmpty;

  Future<void> save(String token, {int? userId}) async {
    final prefs = await _ensurePrefs();
    await _secureStorage.write(key: _tokenKey, value: token);
    if (userId != null) {
      await _secureStorage.write(key: _userIdKey, value: '$userId');
    } else {
      await _secureStorage.delete(key: _userIdKey);
    }
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    _cachedToken = token;
    _cachedUserId = userId;
  }

  Future<void> clear() async {
    final prefs = await _ensurePrefs();
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    _cachedToken = null;
    _cachedUserId = null;
  }

  String? _cleanToken(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    return cleaned;
  }
}
