import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeDataProvider extends ChangeNotifier {
  List<dynamic> sliderList = [];
  List<dynamic> bannerList = [];
  bool isLoading = false;
  bool _isDataLoaded = false; // Add a flag to track if data is loaded

  bool get isDataLoaded => _isDataLoaded; // Getter for isDataLoaded

  Future<void> fetchSliderAndBannerData() async {
    if (_isDataLoaded) {
      // Data is already loaded, no need to fetch again
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://app.omnicare.com.bd/api'));
      final json = jsonDecode(response.body);
      sliderList = json['sliders'];
      bannerList = json['site_settigs'];
      _isDataLoaded = true; // Update flag to indicate data is loaded
    } catch (error) {
      print('Error fetching data: $error');
    }

    isLoading = false;
    notifyListeners();
  }
}