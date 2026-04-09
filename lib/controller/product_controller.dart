// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/util/app_constants.dart';

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
          Uri.parse(AppConstants.allOfferedProducts),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final list = json is List
              ? json
              : (json['data'] ?? json['offered_products'] ?? json['products'] ?? []);
          offeredproductsList.assignAll(list);
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
          Uri.parse(AppConstants.home),
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
          Uri.parse(AppConstants.allProducts),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final list = json['data'] ?? [];
          // Filter out hidden products (status == 0) if backend adds status field
          // Also filter out products explicitly marked as hidden
          final filtered = (list as List).where((p) {
            // If backend adds status field: exclude status=0
            if (p['status'] != null && p['status'] == 0) return false;
            // If backend adds is_hidden field: exclude hidden
            if (p['is_hidden'] == 1 || p['is_hidden'] == true) return false;
            return true;
          }).toList();
          allproductsList.assignAll(filtered);
          print('All Products Loaded: ${allproductsList.length}');

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
          AppConstants.featuredCategories,
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
  Future<void> getTrendingProducts() async {
    trendingLoading.value = true;
    try {
      if (allproductsList.isEmpty) await getAllProducts();

      final response = await http.get(
        Uri.parse(AppConstants.topSales),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final topSalesList = json['data'] ?? [];

        final Map<int, dynamic> productMap = {
          for (var p in allproductsList) (p['id'] as int): p
        };

        final enriched = <dynamic>[];
        for (final item in topSalesList) {
          final id = item['id'] as int?;
          if (id != null && productMap.containsKey(id)) {
            enriched.add(productMap[id]);
          }
        }
        trendingProductsList.assignAll(enriched);
        print('Trending Products Loaded: ${trendingProductsList.length}');
      } else {
        print('Failed to load trending products. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Trending Products Error: $error');
    } finally {
      trendingLoading.value = false;
    }
  }

  Future<void> refreshAllData() async {
    offeredproductsList.clear();
    allproductsList.clear();
    companyList.clear();
    featuredCategoryList.clear();
    isFavouriteList.clear();
    trendingProductsList.clear();

    await Future.wait([
      getOfferProducts(),
      getCompany(),
      getFeaturedCategories(),
    ]);
    await getAllProducts();
    await getTrendingProducts();
  }

  @override
  void onInit() {
    super.onInit();
    getOfferProducts();
    getCompany();
    getFeaturedCategories();
    getAllProducts().then((_) => getTrendingProducts());
  }
}