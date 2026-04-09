import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/ui/subscreens/notification_screen.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showLocalNotification(message);
}

void _navigateToNotificationScreen() {
  Get.to(
    () => NotificationScreen(onNotificationUpdate: (_) {}),
    preventDuplicates: true,
  );
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await Firebase.initializeApp();
    await NotificationService().init();

    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    log(settings.authorizationStatus == AuthorizationStatus.authorized
        ? '✅ Notification permission granted'
        : '❌ Notification permission denied');

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final String? token = await _messaging.getToken();
    if (token != null) log('🔑 FCM Token: $token');

    FirebaseMessaging.instance.onTokenRefresh.listen((t) => log('🔄 Token: $t'));

    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log('Tapped (background): ${message.data}');
      _navigateToNotificationScreen();
    });

    final RemoteMessage? initial =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      log('Tapped (terminated): ${initial.data}');
      Future.delayed(const Duration(seconds: 1), _navigateToNotificationScreen);
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        log('Local notification tapped: ${response.payload}');
        _navigateToNotificationScreen();
      },
    );

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final Map<String, dynamic> data = message.data;

  log('FCM data: $data');

  final String? imageUrl = data['image'] as String?;
  log('Notification image URL: $imageUrl');

  AndroidNotificationDetails androidDetails;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    final ByteArrayAndroidBitmap? bitmap = await _downloadImage(imageUrl);
    if (bitmap != null) {
      androidDetails = AndroidNotificationDetails(
        'default_channel_id',
        'General Notifications',
        channelDescription: 'General notifications channel',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        largeIcon: bitmap,
        styleInformation: BigPictureStyleInformation(
          bitmap,
          largeIcon: bitmap,
          contentTitle: notification?.title ?? data['title'] ?? '',
          summaryText: notification?.body ?? data['body'] ?? '',
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        ),
      );
    } else {
      androidDetails = _defaultAndroidDetails();
    }
  } else {
    androidDetails = _defaultAndroidDetails();
  }

  await NotificationService().flutterLocalNotificationsPlugin.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: notification?.title ?? data['title'] ?? 'No Title',
    body: notification?.body ?? data['body'] ?? 'No Body',
    notificationDetails: NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    ),
    payload: data.toString(),
  );
}

AndroidNotificationDetails _defaultAndroidDetails() {
  return const AndroidNotificationDetails(
    'default_channel_id',
    'General Notifications',
    channelDescription: 'General notifications channel',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );
}

Future<ByteArrayAndroidBitmap?> _downloadImage(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return ByteArrayAndroidBitmap(response.bodyBytes);
    }
  } catch (e) {
    log('Failed to download notification image: $e');
  }
  return null;
}
