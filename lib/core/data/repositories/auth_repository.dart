import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/token_store.dart';
import 'package:nbts/core/data/models/json_utils.dart';
import 'package:nbts/core/data/models/user.dart';

class AuthRepository extends ChangeNotifier {
  AuthRepository({
    required ApiClient api,
    required TokenStore tokens,
    Future<void> Function()? onAuthenticated,
  })  : _api = api,
        _tokens = tokens,
        _onAuthenticated = onAuthenticated;

  final ApiClient _api;
  final TokenStore _tokens;
  final Future<void> Function()? _onAuthenticated;

  User? _user;
  User? get user => _user;
  bool get isAuthenticated => _tokens.isAuthenticated;

  Future<User> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/login',
      authenticated: false,
      body: {'identifier': identifier, 'password': password},
    );
    return _persistFromAuthResponse(response);
  }

  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String bloodGroup,
    required String gender,
    required String region,
    required String dateOfBirth,
  }) async {
    final response = await _api.post(
      '/auth/register',
      authenticated: false,
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'blood_group': bloodGroup,
        'gender': gender,
        'region': region,
        'date_of_birth': dateOfBirth,
      },
    );
    return _persistFromAuthResponse(response);
  }

  Future<User> fetchCurrentUser() async {
    final response = await _api.get('/user');
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected user payload');
    }
    final user = User.fromJson(payload);
    _user = user;
    notifyListeners();
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Best effort: clear the local session even if logout fails server-side.
    }
    await _tokens.clear();
    _user = null;
    notifyListeners();
  }

  Future<User> _persistFromAuthResponse(dynamic response) async {
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected auth response');
    }
    final token = readString(response, [
      'token',
      'access_token',
      'auth_token',
      'plain_text_token',
    ]);
    if (token == null) {
      throw const ApiException('Auth response did not include a token');
    }

    Map<String, dynamic>? userJson;
    final rawUser = response['user'] ?? response['data'] ?? response['profile'];
    if (rawUser is Map<String, dynamic>) {
      userJson = rawUser;
    } else if (rawUser is Map) {
      userJson = rawUser.cast<String, dynamic>();
    }

    final wrappedUser = userJson?['data'];
    if (wrappedUser is Map<String, dynamic>) {
      userJson = wrappedUser;
    } else if (wrappedUser is Map) {
      userJson = wrappedUser.cast<String, dynamic>();
    }

    final user = userJson != null ? User.fromJson(userJson) : null;

    await _tokens.save(token, userId: user?.id);
    _user = user;
    notifyListeners();
    final onAuthenticated = _onAuthenticated;
    if (onAuthenticated != null) {
      unawaited(onAuthenticated());
    }
    return user ?? await fetchCurrentUser();
  }
}


