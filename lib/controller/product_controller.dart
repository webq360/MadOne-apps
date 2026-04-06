// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ProductController extends GetxController {
  final RxList<dynamic> offeredproductsList = <dynamic>[].obs;
  final RxList<dynamic> allproductsList = <dynamic>[].obs;
  final RxList<dynamic> companyList = <dynamic>[].obs;
  final RxList<dynamic> featuredCategoryList = <dynamic>[].obs;
  final RxList<bool> isFavouriteList = <bool>[].obs;

  final RxBool inProgress = false.obs;


// category wise products
final RxList<dynamic> categoryWiseProductsList = <dynamic>[].obs;
final RxBool categoryWiseLoading = false.obs;
final RxString selectedCategoryName = ''.obs;
final RxInt selectedCategoryId = 0.obs;

Future<void> getCategoryWiseProducts({
  required int categoryId,
  String categoryName = '',
}) async {
  categoryWiseLoading.value = true;
  selectedCategoryId.value = categoryId;
  selectedCategoryName.value = categoryName;
  categoryWiseProductsList.clear();

  try {
    final response = await http.get(
      Uri.parse(
        'https://stage.medone.primeharvestbd.com/api/category_wise_product/$categoryId',
      ),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      categoryWiseProductsList.assignAll(
        json['products']?['data'] ?? [],
      );

      print(
        'Category Wise Products Loaded: ${categoryWiseProductsList.length}',
      );
    } else {
      print(
        'Failed to load category wise products. Status code: ${response.statusCode}',
      );
    }
  } catch (error) {
    print('Category Wise Products Error: $error');
  } finally {
    categoryWiseLoading.value = false;
  }
}



  Future<void> getOfferProducts() async {
    if (offeredproductsList.isEmpty) {
      inProgress.value = true;
      try {
        final response = await http.get(
          Uri.parse('https://stage.medone.primeharvestbd.com/api'),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          offeredproductsList.assignAll(json['offered_products'] ?? []);
          isFavouriteList.assignAll(
            List.filled(offeredproductsList.length, false),
          );
        } else {
          print(
            'Failed to load offered products. Status code: ${response.statusCode}',
          );
        }
      } catch (error) {
        print('Offer Products Error: $error');
      } finally {
        inProgress.value = false;
      }
    }
  }

  Future<void> getCompany() async {
    if (companyList.isEmpty) {
      inProgress.value = true;
      try {
        final response = await http.get(
          Uri.parse('https://stage.medone.primeharvestbd.com/api'),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          companyList.assignAll(json['brands'] ?? []);
        } else {
          print(
            'Failed to load company names. Status code: ${response.statusCode}',
          );
        }
      } catch (error) {
        print('Company Error: $error');
      } finally {
        inProgress.value = false;
      }
    }
  }

  Future<void> getAllProducts() async {
    if (allproductsList.isEmpty) {
      inProgress.value = true;
      try {
        final response = await http.get(
          Uri.parse('https://stage.medone.primeharvestbd.com/api'),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          allproductsList.assignAll(json['all_products'] ?? []);

          if (isFavouriteList.length != allproductsList.length) {
            isFavouriteList.assignAll(
              List.filled(allproductsList.length, false),
            );
          }
        } else {
          print(
            'Failed to load all products. Status code: ${response.statusCode}',
          );
        }
      } catch (error) {
        print('All Products Error: $error');
      } finally {
        inProgress.value = false;
      }
    }
  }

Future<void> getFeaturedCategories() async {
  if (featuredCategoryList.isEmpty) {
    inProgress.value = true;
    try {
      final response = await http.get(
        Uri.parse(
          'https://stage.medone.primeharvestbd.com/api/featured_categories',
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['success'] == true) {
          featuredCategoryList.assignAll(json['data'] ?? []);
          print('Featured Categories Loaded: ${featuredCategoryList.length}');
        } else {
          print(json['message'] ?? 'Failed to load featured categories');
        }
      } else {
        print(
          'Failed to load featured categories. Status code: ${response.statusCode}',
        );
      }
    } catch (error) {
      print('Featured Categories Error: $error');
    } finally {
      inProgress.value = false;
    }
  }
}
  Future<void> refreshAllData() async {
    offeredproductsList.clear();
    allproductsList.clear();
    companyList.clear();
    featuredCategoryList.clear();
    isFavouriteList.clear();

    await Future.wait([
      getOfferProducts(),
      getCompany(),
      getAllProducts(),
      getFeaturedCategories(),
    ]);
  }

  @override
  void onInit() {
    super.onInit();
    getOfferProducts();
    getCompany();
    getAllProducts();
    getFeaturedCategories();
  }
}