import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:omnicare_app/application/app.dart';
import 'package:omnicare_app/firebase_options.dart';
import 'package:omnicare_app/hive/company_hive/company_model.dart';
import 'package:omnicare_app/hive/home_hive/hive_model.dart';
import 'package:omnicare_app/services/notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase first
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Register background message handler BEFORE any other Firebase calls
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Get the application documents directory path
    final appDocumentDirectory = await getApplicationDocumentsDirectory();
    await FirebaseNotificationService().init();
    // Initialize Hive with the application documents directory path
    Hive.init(appDocumentDirectory.path);
    // Register TypeAdapters
    Hive.registerAdapter(HiveSliderAdapter());
    Hive.registerAdapter(HiveBannerAdapter());
    Hive.registerAdapter(CompanyAdapter());

    // Open Hive boxes and SharedPreferences
    await Future.wait([
      Hive.openBox<HiveSlider>('sliders'),
      Hive.openBox<HiveBanner>('banners'),
      Hive.openBox<HiveBanner>('companyBox'),
      SharedPreferences.getInstance(),
    ]);
  } catch (error, stackTrace) {
    print('Error during initialization: $error');
    print('Stack trace: $stackTrace');
  }

  runApp(const OmniCare());
}