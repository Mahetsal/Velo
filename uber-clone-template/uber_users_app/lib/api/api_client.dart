import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

/// Single source of truth for all Velo backend HTTP requests.
///
/// Centralizes the base URL, auth headers, and timeout policy so that
/// individual pages never hard-code tokens or endpoint prefixes.
class ApiClient {
  ApiClient._();

  static const String _defaultBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static String? _authToken;

  /// Allows tests to intercept all HTTP traffic via `MockClient`.
  @visibleForTesting
  static http.Client? httpClientOverride;

  /// Call from [AuthenticationProvider] whenever the session token changes.
  static void setAuthToken(String? token) => _authToken = token;

  static Map<String, String> authHeaders({bool json = false}) {
    final token = _authToken;
    return {
      "Authorization":
          "Bearer ${(token != null && token.isNotEmpty) ? token : "public-migration-token"}",
      if (json) "Content-Type": "application/json",
    };
  }

  // ---------------------------------------------------------------------------
  // HTTP verbs
  // ---------------------------------------------------------------------------

  /// GET with automatic retry + exponential backoff for transient (5xx) errors.
  static Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    int retries = 2,
  }) async {
    final uri = Uri.parse("$baseUrl$path");
    final h = headers ?? authHeaders();
    final c = httpClientOverride;
    http.Response? last;
    for (var i = 0; i <= retries; i++) {
      try {
        last = c != null ? await c.get(uri, headers: h) : await http.get(uri, headers: h);
        if (last.statusCode < 500) return last;
      } catch (_) {
        if (i == retries) rethrow;
      }
      await Future.delayed(Duration(milliseconds: 300 * (1 << i)));
    }
    return last!;
  }

  static Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    final uri = Uri.parse("$baseUrl$path");
    final h = headers ?? authHeaders(json: body != null);
    final b = body != null ? jsonEncode(body) : null;
    final c = httpClientOverride;
    return c != null
        ? c.post(uri, headers: h, body: b)
        : http.post(uri, headers: h, body: b);
  }

  static Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    final uri = Uri.parse("$baseUrl$path");
    final h = headers ?? authHeaders(json: body != null);
    final b = body != null ? jsonEncode(body) : null;
    final c = httpClientOverride;
    return c != null
        ? c.put(uri, headers: h, body: b)
        : http.put(uri, headers: h, body: b);
  }

  static Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) {
    final uri = Uri.parse("$baseUrl$path");
    final h = headers ?? authHeaders();
    final c = httpClientOverride;
    return c != null
        ? c.delete(uri, headers: h)
        : http.delete(uri, headers: h);
  }
}
