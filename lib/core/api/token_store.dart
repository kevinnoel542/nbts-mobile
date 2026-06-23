class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  String? _cachedToken;
  int? _cachedUserId;

  Future<void> load() async {}

  String? get token => _cachedToken;
  int? get userId => _cachedUserId;
  bool get isAuthenticated => _cachedToken != null && _cachedToken!.isNotEmpty;

  Future<void> save(String token, {int? userId}) async {
    _cachedToken = token;
    _cachedUserId = userId;
  }

  Future<void> clear() async {
    _cachedToken = null;
    _cachedUserId = null;
  }
}
