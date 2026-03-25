import 'package:flutter/material.dart';

class PushNotificationSystem {
  // Push transport has been migrated away from Firebase.
  // Keep these methods as no-op hooks so the app remains stable
  // until AWS-native push delivery is connected.
  Future<String?> generateDeviceRegistrationToken() async {
    return null;
  }

  startListeningForNewNotification(BuildContext context) async {
    // Intentionally no-op in AWS-only mode.
  }
}
