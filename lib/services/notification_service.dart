// ----------------------
// Background Handler must be top-level
// ----------------------
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(message.toMap());
  await Firebase.initializeApp();
  _showLocalNotification(message);
}

// ----------------------
// Firebase Notification Service
// ----------------------

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await Firebase.initializeApp();
    await NotificationService().init();
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log("✅ Notification permission granted");
    } else {
      log("❌ Notification permission denied");
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Get token
    String? token = await _messaging.getToken();
    if (token != null) {
      //await appData.write(kKayFcmToken, token);
      log("🔑 FCM Token: $token");
     
    }

    // Token refresh listener
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
     // await appData.write(kKayFcmToken, newToken);
      // await _postTokenIfUserExists();
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Notification opened (background / terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("Notification clicked: ${message.data}");
     // Get.to(() => NotificationScreen());
    });
  }


}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize( settings: initSettings);

    // Request Android 13+ notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}

void _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;

  final data = message.data;

  log("-------data------$data-----------");

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'default_channel_id',
    'General Notifications',
    channelDescription: 'General notifications channel',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await NotificationService().flutterLocalNotificationsPlugin.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
   title:  notification?.title ?? data['title'] ?? "No Title",
  body:   notification?.body ?? data['body'] ?? "No Body",
    notificationDetails: notificationDetails,
    payload: data.toString(),
  );
}

// ----------------------
// FCM Token Service
// ----------------------
