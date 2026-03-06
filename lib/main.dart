import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:omnicare_app/application/app.dart';
import 'package:omnicare_app/hive/company_hive/company_model.dart';
import 'package:omnicare_app/hive/home_hive/hive_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get the application documents directory path
  final appDocumentDirectory = await getApplicationDocumentsDirectory();

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

  runApp(const OmniCare());
}