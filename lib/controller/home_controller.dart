import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:omnicare_app/hive/home_hive/hive_model.dart'; // Import Hive model classes
import 'package:omnicare_app/hive/home_hive/home_hive.dart';
import 'package:omnicare_app/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import HiveService

class HomeController extends GetxController {
  var isLoading = true.obs;
  RxList<HiveSlider> sliderList = <HiveSlider>[].obs;
  RxList<HiveBanner> bannerList = <HiveBanner>[].obs;
  var shipChargeInsideDhaka = '0'.obs;
  var shipChargeOutsideDhaka = '0'.obs;
  var currentIndex = 0.obs;
  var isDataLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDataFromHive();
    fetchData();
    initial();

  }
 Future<void> initial() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');

      if (userId == null) {
        log('userId not found in SharedPreferences');
        return;
      }

      String? fcmToken;

      if (!Platform.isIOS) {
        fcmToken = await FirebaseMessaging.instance.getToken();
        log("Android FCM Token: $fcmToken");
      } else {
        fcmToken = await FirebaseMessaging.instance.getToken();
        log("iOS FCM Token: $fcmToken");

        // Optional:
        // final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        // log("iOS APNS Token: $apnsToken");
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await sendFcmTokenToServer(
          token: fcmToken,
          userId: userId,
        );
      }
    } catch (e) {
      log("FCM Error: $e");
    }
  }

  Future<void> sendFcmTokenToServer({
    required String token,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.fcmToken),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'user_id': userId,
        }),
      );

      log('FCM Token API Status: ${response.statusCode}');
      log('FCM Token API Response: ${response.body}');
    } catch (e) {
      log('sendFcmTokenToServer Error: $e');
    }
  }

  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      final response = await http
          .get(Uri.parse(AppConstants.home));
      final json = jsonDecode(response.body);

      final List<dynamic> slidersJson = json['sliders'];
      final List<dynamic> bannersJson = json['site_settigs'];

      shipChargeInsideDhaka.value =
          bannersJson[0]['ship_charge_inside_dhaka'] ?? '0';
      shipChargeOutsideDhaka.value =
          bannersJson[0]['ship_charge_ouside_dhaka'] ?? '0';

      final List<HiveSlider> sliders = slidersJson
          .map((sliderJson) => HiveSlider(sliderJson['slider_image'] as String))
          .toList();
      final List<HiveBanner> banners = bannersJson
          .map((bannerJson) => HiveBanner(bannerJson['banner_image'] as String))
          .toList();

      sliderList.assignAll(sliders);
      bannerList.assignAll(banners);

      await HiveService.saveDataToHive(sliders, banners);

      isDataLoaded.value = true; // Set isDataLoaded to true
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDataFromHive() async {
    try {
      final data = await HiveService.loadDataFromHive();
      if (data[0].isNotEmpty && data[1].isNotEmpty) {
        final List<HiveSlider> sliders = data[0].cast<HiveSlider>();
        final List<HiveBanner> banners = data[1].cast<HiveBanner>();
        sliderList.assignAll(sliders);
        bannerList.assignAll(banners);
        isDataLoaded.value = true; // Set isDataLoaded to true
      }
    } catch (e) {
      print('Error loading data from Hive: $e');
    }
  }
}
