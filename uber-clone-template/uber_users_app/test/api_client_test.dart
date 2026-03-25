import 'package:flutter_test/flutter_test.dart';
import 'package:uber_users_app/api/api_client.dart';

void main() {
  group('ApiClient.authHeaders', () {
    setUp(() => ApiClient.setAuthToken(null));

    test('uses public-migration-token when no auth token is set', () {
      ApiClient.setAuthToken(null);
      final h = ApiClient.authHeaders();
      expect(h['Authorization'], 'Bearer public-migration-token');
    });

    test('uses real token when set', () {
      ApiClient.setAuthToken('my-jwt-123');
      final h = ApiClient.authHeaders();
      expect(h['Authorization'], 'Bearer my-jwt-123');
    });

    test('falls back to public token for empty string', () {
      ApiClient.setAuthToken('');
      final h = ApiClient.authHeaders();
      expect(h['Authorization'], 'Bearer public-migration-token');
    });

    test('adds Content-Type when json=true', () {
      final h = ApiClient.authHeaders(json: true);
      expect(h['Content-Type'], 'application/json');
    });

    test('no Content-Type when json=false', () {
      final h = ApiClient.authHeaders(json: false);
      expect(h.containsKey('Content-Type'), isFalse);
    });
  });

  group('ApiClient.baseUrl', () {
    test('has a non-empty default', () {
      expect(ApiClient.baseUrl, isNotEmpty);
      expect(ApiClient.baseUrl, startsWith('https://'));
    });
  });
}
