// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/util/app_constants.dart';

bool _isTrue(dynamic val) => val == 1 || val == true || val == '1';

class ProductController extends GetxController {
  final RxList<dynamic> offeredproductsList = <dynamic>[].obs;
  final RxList<dynamic> allproductsList = <dynamic>[].obs;
  final RxList<dynamic> companyList = <dynamic>[].obs;
  final RxList<dynamic> featuredCategoryList = <dynamic>[].obs;
  final RxList<bool> isFavouriteList = <bool>[].obs;
  final RxList<dynamic> trendingProductsList = <dynamic>[].obs;
  final RxBool trendingLoading = false.obs;

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
        AppConstants.categoryWiseProduct(categoryId),
      ),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final raw = json['products'] is List
          ? json['products']
          : (json['products']?['data'] ?? json['data'] ?? []);
      categoryWiseProductsList.assignAll(
        (raw as List).where((p) =>
            !_isTrue(p['is_banned']) &&
            !_isTrue(p['banned']) &&
            !_isTrue(p['is_hide']) &&
            !_isTrue(p['hide'])).toList(),
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
    try {
      final response = await http.get(Uri.parse(AppConstants.allOfferedProducts));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final raw = json is List
            ? json
            : (json['data'] ?? json['offered_products'] ?? json['products'] ?? []);
        final list = (raw as List)
            .where((p) => !_isTrue(p['is_banned']) && !_isTrue(p['banned']) && !_isTrue(p['is_hide']) && !_isTrue(p['hide']))
            .toList();
        offeredproductsList.assignAll(list);
        isFavouriteList.assignAll(List.filled(list.length, false));
      }
    } catch (error) {
      print('Offer Products Error: $error');
    }
  }

  Future<void> getCompany() async {
    try {
      final response = await http.get(Uri.parse(AppConstants.home));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        companyList.assignAll(json['brands'] ?? []);
      }
    } catch (error) {
      print('Company Error: $error');
    }
  }

  Future<void> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse(AppConstants.allProducts));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = ((json['data'] ?? []) as List)
            .where((p) => !_isTrue(p['is_banned']) && !_isTrue(p['banned']) && !_isTrue(p['is_hide']) && !_isTrue(p['hide']))
            .toList();
        allproductsList.assignAll(list);
        isFavouriteList.assignAll(List.filled(list.length, false));
      }
    } catch (error) {
      print('All Products Error: $error');
    }
  }

  Future<void> getFeaturedCategories() async {
    try {
      final response = await http.get(Uri.parse(AppConstants.featuredCategories));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          featuredCategoryList.assignAll(json['data'] ?? []);
        }
      }
    } catch (error) {
      print('Featured Categories Error: $error');
    }
  }
  Future<void> getTrendingProducts() async {
    trendingLoading.value = true;
    try {
      final response = await http.get(Uri.parse(AppConstants.topSales));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final topSalesList = json['data'] ?? [];
        final Map<int, dynamic> productMap = {
          for (var p in allproductsList) (p['id'] as int): p
        };
        final enriched = <dynamic>[];
        for (final item in topSalesList) {
          final id = item['id'] as int?;
          if (id != null && productMap.containsKey(id)) enriched.add(productMap[id]);
        }
        trendingProductsList.assignAll(enriched);
      }
    } catch (error) {
      print('Trending Products Error: $error');
    } finally {
      trendingLoading.value = false;
    }
  }

  Future<void> refreshAllData() async {
    inProgress.value = true;
    trendingLoading.value = true;
    try {
      await Future.wait([
        getOfferProducts(),
        getCompany(),
        getFeaturedCategories(),
        getAllProducts(),
      ]);
      await getTrendingProducts();
    } catch (error, stackTrace) {
      print('Error in refreshAllData: $error');
      print('Stack trace: $stackTrace');
    } finally {
      inProgress.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    try {
      refreshAllData();
    } catch (error, stackTrace) {
      print('ProductController Init Error: $error');
      print('Stack trace: $stackTrace');
    }
  }
}