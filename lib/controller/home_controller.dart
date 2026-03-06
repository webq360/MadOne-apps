import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:omnicare_app/hive/home_hive/hive_model.dart'; // Import Hive model classes
import 'package:omnicare_app/hive/home_hive/home_hive.dart'; // Import HiveService

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
  }

  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      final response =
          await http.get(Uri.parse('https://app.omnicare.com.bd/api'));
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
