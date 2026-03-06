// import 'package:flutter/material.dart';
//
// class QuantityButtonsProvider with ChangeNotifier {
//   bool _showQuantityButtons = false;
//
//   bool get showQuantityButtons => _showQuantityButtons;
//
//   void setShowQuantityButtons(bool value) {
//     _showQuantityButtons = value;
//     notifyListeners();
//   }
// }
//
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuantityButtonsProvider with ChangeNotifier {
  bool _showQuantityButtons = false;

  bool get showQuantityButtons => _showQuantityButtons;

  QuantityButtonsProvider() {
    // Load quantity button state from SharedPreferences when the provider is initialized
    loadQuantityButtonState();
  }

  Future<void> loadQuantityButtonState() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _showQuantityButtons = prefs.getBool('showQuantityButtons') ?? false;
      notifyListeners();
    } catch (error) {
      print('Error loading quantity button state: $error'); // Debug print
    }
  } 

  Future<void> setShowQuantityButtons(bool value) async {
    try {
      _showQuantityButtons = value;
      notifyListeners();

      // Save the state to shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('showQuantityButtons', value);
    } catch (error) {
      print('Error setting quantity button state: $error'); // Debug print
    }
  }
}





