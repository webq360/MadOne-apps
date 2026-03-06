// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ProductController extends GetxController {
  final RxList<dynamic> offeredproductsList = <dynamic>[].obs;
  final RxList<dynamic> allproductsList = <dynamic>[].obs;

  final RxList<bool> isFavouriteList = <bool>[].obs;
  List<dynamic> companyList = [];
  final RxBool inProgress = false.obs;

  void getOfferProducts() async {
    if (offeredproductsList.isEmpty) {
      inProgress.value = true;
      try {
        final response =
            await http.get(Uri.parse('https://app.omnicare.com.bd/api'));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          offeredproductsList.assignAll(json['offered_products']);
          isFavouriteList
              .assignAll(List.filled(offeredproductsList.length, false));
        } else {
          print(
              'Failed to load company names. Status code: ${response.statusCode}');
        }
      } catch (error) {
        print('Error: $error');
      }
      inProgress.value = false;
    }
  }

  void getCompany() async {
    if (companyList.isEmpty) {
      inProgress.value = true;
      try {
        final response =
            await http.get(Uri.parse('https://app.omnicare.com.bd/api'));
        if (response.statusCode == 200) {
          companyList.clear();
          final json = jsonDecode(response.body);
          companyList.assignAll(json['brands']);
        } else {
          print(
              'Failed to load company names. Status code: ${response.statusCode}');
        }
      } catch (error) {
        print('Error: $error');
      }
      inProgress.value = false;
    }
  }

  void getAllProducts() async {
    if (allproductsList.isEmpty) {
      inProgress.value = true;
      try {
        final response =
            await http.get(Uri.parse('https://app.omnicare.com.bd/api'));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          allproductsList.assignAll(json['all_products']);
          isFavouriteList
              .assignAll(List.filled(allproductsList.length, false));
        } else {
          print(
              'Failed to load company names. Status code: ${response.statusCode}');
        }
      } catch (error) {
        print('Error: $error');
      }
      inProgress.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    getOfferProducts();
    getCompany();
    getAllProducts();
  }
}
