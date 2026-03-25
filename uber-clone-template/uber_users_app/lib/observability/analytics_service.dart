import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around Firebase Analytics for funnel and product events.
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? get _maybe {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logEvent(String name,
      [Map<String, Object>? parameters]) async {
    final a = _maybe;
    if (a == null) return;
    try {
      await a.logEvent(name: name, parameters: parameters);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Analytics.logEvent failed: $name $e\n$st');
      }
    }
  }

  static Future<void> logDestinationSelected() =>
      logEvent('funnel_destination_selected');

  static Future<void> logConfirmBooking({required String vehicleTier}) =>
      logEvent('funnel_confirm_booking', {'vehicle_tier': vehicleTier});

  static Future<void> logRequestDriver() =>
      logEvent('funnel_request_driver');

  static Future<void> logTripActive() => logEvent('funnel_trip_active');

  static Future<void> logPaymentCompleted({required String method}) =>
      logEvent('funnel_payment_complete', {'method': method});

  static Future<void> logFeedbackSubmitted({
    required int stars,
    bool hasComment = false,
    double tipAmount = 0,
  }) =>
      logEvent('feedback_submitted', {
        'stars': stars,
        'has_comment': hasComment,
        'tip_amount': tipAmount,
      });

  static Future<void> logTripShared() => logEvent('trip_shared');

  static Future<void> logEmergencyTapped() => logEvent('emergency_tapped');

  static Future<void> logSafetySheetOpened() =>
      logEvent('safety_sheet_opened');

  static Future<void> logTipAdded({required double amount}) =>
      logEvent('tip_added', {'amount': amount});
}
