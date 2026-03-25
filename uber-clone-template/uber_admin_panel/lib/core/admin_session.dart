import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminSession {
  static const String sessionKey = "admin_logged_in";
  static const String accessTokenKey = "admin_access_token";
  static const String refreshTokenKey = "admin_refresh_token";

  static const String awsApiBaseUrl =
      "https://xhmks5miz3rrn35sxdboeddoqa0jcajs.lambda-url.us-east-1.on.aws";

  static const Duration _httpTimeout = Duration(seconds: 30);

  static Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(accessTokenKey);
    if (token == null || token.isEmpty) {
      return const {"Authorization": "Bearer public-migration-token"};
    }
    return {"Authorization": "Bearer $token"};
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
  }

  static Future<String?> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final signInResponse = await _postJson(
        "/auth/sign-in",
        {"username": username, "password": password},
      );

      if (signInResponse.statusCode != 200) {
        final signInError = _extractError(signInResponse.body);
        return signInError.isEmpty ? "Invalid admin credentials." : signInError;
      }

      return await _completeAdminSignIn(signInResponse.body);
    } on TimeoutException {
      return "Connection timed out. Check your network and try again.";
    } catch (e) {
      return "Sign-in failed: $e";
    }
  }

  static Future<String?> _completeAdminSignIn(String responseBody) async {
    late final Map<String, dynamic> signInPayload;
    try {
      signInPayload = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      return "Invalid response from server.";
    }
    final auth = (signInPayload["auth"] ?? {}) as Map;
    final accessToken = (auth["AccessToken"] ?? "").toString();
    final refreshToken = (auth["RefreshToken"] ?? "").toString();

    if (accessToken.isEmpty) {
      return "Missing access token from AWS.";
    }

    late final http.Response meResponse;
    try {
      meResponse = await http
          .get(
            Uri.parse("$awsApiBaseUrl/auth/me"),
            headers: {"Authorization": "Bearer $accessToken"},
          )
          .timeout(_httpTimeout);
    } on TimeoutException {
      return "Connection timed out while verifying your account.";
    } catch (e) {
      return "Could not verify admin role: $e";
    }
    if (meResponse.statusCode != 200) {
      return "Unable to verify admin role.";
    }
    late final Map<String, dynamic> mePayload;
    try {
      mePayload = jsonDecode(meResponse.body) as Map<String, dynamic>;
    } catch (_) {
      return "Invalid response while verifying admin role.";
    }
    final user = (mePayload["user"] ?? {}) as Map;
    final groups = List<String>.from((user["groups"] ?? []) as List);
    if (!groups.contains("admin")) {
      return "Your account is not in admin group.";
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sessionKey, true);
    await prefs.setString(accessTokenKey, accessToken);
    if (refreshToken.isNotEmpty) {
      await prefs.setString(refreshTokenKey, refreshToken);
    }
    return null;
  }

  static Future<http.Response> _postJson(
    String path,
    Map<String, dynamic> body,
  ) {
    return http
        .post(
          Uri.parse("$awsApiBaseUrl$path"),
          headers: const {"Content-Type": "application/json"},
          body: jsonEncode(body),
        )
        .timeout(_httpTimeout);
  }

  static String _extractError(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return (payload["error"] ?? "").toString();
    } catch (_) {
      return "";
    }
  }
}
