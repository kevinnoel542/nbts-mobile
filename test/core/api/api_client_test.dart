import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nbts/core/api/api_client.dart';

void main() {
  test('authenticated 401 invokes the unauthorized handler', () async {
    var unauthorizedCalls = 0;
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response('{"message":"Unauthenticated."}', 401),
      ),
      tokenProvider: () => 'expired-token',
      onUnauthorized: () async => unauthorizedCalls++,
    );

    await expectLater(client.get('/profile'), throwsA(isA<ApiException>()));

    expect(unauthorizedCalls, 1);
  });

  test('public 401 does not invoke the unauthorized handler', () async {
    var unauthorizedCalls = 0;
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response('{"message":"Invalid credentials."}', 401),
      ),
      onUnauthorized: () async => unauthorizedCalls++,
    );

    await expectLater(
      client.post('/auth/login', authenticated: false),
      throwsA(isA<ApiException>()),
    );

    expect(unauthorizedCalls, 0);
  });
}
