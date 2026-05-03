import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      // TODO: Send token to backend POST /users/me/fcm-token
    }

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
    });

    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  static void _handleMessage(RemoteMessage message) {
    debugPrint('FCM message received: ${message.notification?.title}');
  }
}
