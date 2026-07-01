import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nbts/core/api/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.body, this.errors});

  final String message;
  final int? statusCode;
  final Object? body;
  final Map<String, List<String>>? errors;

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;
  bool get isNetwork => statusCode == null;

  String firstError([String? field]) {
    if (errors == null || errors!.isEmpty) return message;
    if (field != null && errors!.containsKey(field)) {
      final list = errors![field]!;
      if (list.isNotEmpty) return list.first;
    }
    return errors!.values.first.first;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

typedef TokenProvider = String? Function();

class ApiClient {
  ApiClient({http.Client? httpClient, this.tokenProvider})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  TokenProvider? tokenProvider;

  static const Duration _timeout = Duration(seconds: 20);

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    return _send(
      () => _httpClient.get(
        ApiConfig.endpoint(path, queryParameters),
        headers: _headers(headers, authenticated),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _send(
      () => _httpClient.post(
        ApiConfig.endpoint(path),
        headers: _headers(headers, authenticated),
        body: jsonEncode(body ?? const {}),
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _send(
      () => _httpClient.put(
        ApiConfig.endpoint(path),
        headers: _headers(headers, authenticated),
        body: jsonEncode(body ?? const {}),
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    return _send(
      () => _httpClient.delete(
        ApiConfig.endpoint(path),
        headers: _headers(headers, authenticated),
      ),
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() send) async {
    try {
      final response = await send().timeout(_timeout);
      return _decode(response);
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    } on SocketException catch (e) {
      throw ApiException('Cannot reach server. ${e.message}');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  void close() => _httpClient.close();

  Map<String, String> _headers(Map<String, String>? headers, bool auth) {
    final base = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        base['Authorization'] = 'Bearer $token';
      }
    }
    if (headers != null) base.addAll(headers);
    return base;
  }

  dynamic _decode(http.Response response) {
    final body = response.body;
    Object? decoded;

    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        final preview = body.replaceAll(RegExp(r'\s+'), ' ').trim();
        final looksLikeHtml =
            preview.startsWith('<!DOCTYPE') ||
            preview.startsWith('<html') ||
            preview.contains('<body');
        final message = looksLikeHtml
            ? 'API route not found. Check the Laravel API URL and port.'
            : preview.isEmpty
            ? 'Server returned ${response.statusCode} with an invalid response.'
            : 'Server returned ${response.statusCode}: ${preview.length > 160 ? preview.substring(0, 160) : preview}';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          body: body,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'Request failed';
    Map<String, List<String>>? errors;
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] is String) {
        message = decoded['message'] as String;
      }
      final rawErrors = decoded['errors'];
      if (rawErrors is Map<String, dynamic>) {
        errors = rawErrors.map(
          (k, v) => MapEntry(
            k,
            v is List ? v.map((e) => '$e').toList() : <String>['$v'],
          ),
        );
      }
    }

    throw ApiException(
      message,
      statusCode: response.statusCode,
      body: decoded,
      errors: errors,
    );
  }
}
