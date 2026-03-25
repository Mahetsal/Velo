import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uber_users_app/api/api_client.dart';
import 'package:uber_users_app/firebase_options.dart';
import 'package:uber_users_app/global/global_var.dart';

/// Background / terminated entry point (separate isolate).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushNotificationService._ensureLocalNotificationsReady();
  await PushNotificationService._showLocalFromRemote(message);
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'velo_rider_push',
    'Velo trip updates',
    description: 'Ride status and trip notifications',
    importance: Importance.high,
  );

  static bool _firebaseReady = false;
  static bool _localNotificationsReady = false;

  /// Call after [Firebase.initializeApp] and registering [firebaseMessagingBackgroundHandler].
  static Future<void> setupAfterFirebaseInit() async {
    if (kIsWeb) return;
    try {
      await _ensureLocalNotificationsReady();

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.notification.request();
      }

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((_) {});

      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        unawaited(registerDeviceTokenWithBackendRaw(t));
      });

      _firebaseReady = true;
    } catch (e) {
      debugPrint('PushNotificationService.setupAfterFirebaseInit: $e');
    }
  }

  static Future<void> _ensureLocalNotificationsReady() async {
    if (_localNotificationsReady) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );
    _localNotificationsReady = true;
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _showLocalFromRemote(message);
  }

  static Future<void> _showLocalFromRemote(RemoteMessage message) async {
    await _ensureLocalNotificationsReady();
    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString() ?? 'Velo';
    final body = n?.body ?? message.data['body']?.toString() ?? '';
    final id = message.messageId?.hashCode ?? message.hashCode;
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'velo_rider_push',
          'Velo trip updates',
          channelDescription: 'Ride status and trip notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Registers the current FCM token with the Velo API (merge PUT on user record).
  static Future<void> registerDeviceTokenWithBackend() async {
    if (!_firebaseReady) return;
    final uid = userID;
    if (uid.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await registerDeviceTokenWithBackendRaw(token);
    } catch (e) {
      debugPrint('registerDeviceTokenWithBackend: $e');
    }
  }

  static Future<void> registerDeviceTokenWithBackendRaw(String token) async {
    final uid = userID;
    if (uid.isEmpty) return;
    try {
      final response = await ApiClient.put(
        '/users/$uid',
        body: {'deviceToken': token},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('deviceToken PUT failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('registerDeviceTokenWithBackendRaw: $e');
    }
  }

  /// Sends a trip request notification to a driver device via the AWS notification API.
  static Future<void> sendNotificationToSelectedDriver(
    String deviceToken,
    String tripID,
    String pickUpAddress,
    String dropOffDestinationAddress,
  ) async {
    final Map<String, dynamic> payload = {
      "token": deviceToken,
      "tripID": tripID,
      "title": "New Trip Request From $userName",
      "body":
          "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDestinationAddress",
    };
    try {
      final response = await ApiClient.post(
        "/notifications/driver-trip-request",
        body: payload,
      );
      if (response.statusCode != 200) {
        debugPrint('driver-trip-request API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("sendNotificationToSelectedDriver: $e");
    }
  }
}
