import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Firebase Cloud Messaging service.
/// On web, FCM requires a service worker and VAPID key that may not be
/// configured — so we skip token retrieval to avoid hanging.
class FCMService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Firebase Messaging is not reliably supported on web without a
    // service worker + VAPID key.  Skip to avoid hangs on Chrome.
    if (kIsWeb) {
      debugPrint('[FCM] Running on web — skipping token retrieval');
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      // Send token to backend POST /users/me/fcm-token
    }

    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    debugPrint('[FCM] Service initialized correctly');
  }

  static void _handleMessage(RemoteMessage message) {
    debugPrint('FCM message received: ${message.notification?.title}');
  }
}
