import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Structured logging with Crashlytics integration.
///
/// * [debug] / [warning] — print in debug/profile only, never in release.
/// * [error] — additionally records a **non-fatal** error in Crashlytics so
///   the team sees API failures, parse errors, etc. in the dashboard without
///   the user ever crashing.
/// * [setUser] / [clearUser] — propagate the user identifier to Crashlytics
///   so crash reports can be correlated with accounts.
class AppLogger {
  AppLogger._();

  // ---------------------------------------------------------------------------
  // User identity (Crashlytics)
  // ---------------------------------------------------------------------------

  static Future<void> setUser(String userId) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (_) {}
  }

  static Future<void> clearUser() async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseCrashlytics.instance.setUserIdentifier('');
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Log levels
  // ---------------------------------------------------------------------------

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kReleaseMode) return;
    _print('DEBUG', message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (kReleaseMode) return;
    _print('WARN', message, error, stackTrace);
  }

  /// Logs an error message **and** records a non-fatal in Crashlytics.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      _print('ERROR', message, error, stackTrace);
    }
    _recordNonFatal(message, error, stackTrace);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static void _print(
    String level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final sanitized = _stripSensitive(message);
    debugPrint('[Velo/$level] $sanitized');
    if (error != null) debugPrint('$error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }

  static void _recordNonFatal(
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    try {
      if (Firebase.apps.isEmpty) return;
      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.log(_stripSensitive(message));
      if (error != null) {
        crashlytics.recordError(
          error,
          stackTrace,
          reason: _stripSensitive(message),
          fatal: false,
        );
      }
    } catch (_) {}
  }

  static String _stripSensitive(String s) {
    return s
        .replaceAll(
          RegExp(r'Bearer\s+\S+', caseSensitive: false),
          'Bearer <redacted>',
        )
        .replaceAll(RegExp(r'\b\d{12,}\b'), '<digits>');
  }
}
