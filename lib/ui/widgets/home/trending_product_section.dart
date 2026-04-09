// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/controller/product_controller.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/subscreens/product_details_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:omnicare_app/ui/widgets/home/see_trending_product_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omnicare_app/util/app_constants.dart';

class TrendingProductSection extends StatefulWidget {
  const TrendingProductSection({super.key});

  @override
  State<TrendingProductSection> createState() => _TrendingProductSectionState();
}

class _TrendingProductSectionState extends State<TrendingProductSection> {
  final controller = Get.find<ProductController>();
  Map<int, int> productQuantities = {};
  List<Map<String, dynamic>> _wishlistItems = [];

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) return;
      final res = await http.get(
        Uri.parse(AppConstants.wishlist),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _wishlistItems =
              List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      print('Wishlist fetch error: $e');
    }
  }

  Future<void> _addToWishlist(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;
    await http.get(
      Uri.parse(AppConstants.addToWishlist(productId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    await _fetchWishlist();
  }

  Future<void> _removeFromWishlist(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;
    final item = _wishlistItems.firstWhere(
      (e) => int.tryParse('${e['product_id']}') == productId,
      orElse: () => {},
    );
    if (item.isNotEmpty) {
      await http.get(
        Uri.parse(AppConstants.removeFromWishlist(item['id'] as int)),
        headers: {'Authorization': 'Bearer $token'},
      );
      await _fetchWishlist();
    }
  }

  void addToCart(int index) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final product = controller.trendingProductsList[index];
    final productId = product['id'] as int;

    final existing = cartProvider.cartItems.firstWhere(
      (item) => item.id == productId,
      orElse: () => CartItem(
        id: 0, image: '', name: '', sell_price: 0,
        after_discount_price: 0, company_name: '', subtitle: '', quantity: 0,
      ),
    );

    if (existing.quantity > 0) {
      cartProvider.updateCartItemQuantity(existing, existing.quantity);
    } else {
      cartProvider.addToCart(CartItem(
        id: productId,
        image: product['image'] ?? '',
        name: product['name'] ?? '',
        sell_price: double.parse('${product['sell_price']}'.replaceAll(',', '')),
        after_discount_price: double.parse(
            '${product['after_discount_price']}'.replaceAll(',', '')),
        company_name: product['brand']?['brand_name'] ?? '',
        subtitle: product['name'] ?? '',
        quantity: 1,
        addedFromProductDetails: true,
      ));
      cartProvider.updateQuantity(productId, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.trendingLoading.value) {
        return SizedBox(
          height: 160,
          child: Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              size: 40,
              color: ColorPalette.primaryColor,
            ),
          ),
        );
      }

      if (controller.trendingProductsList.isEmpty) return const SizedBox();

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trending Products',
                  style: fontStyle(12.sp, Colors.black, FontWeight.w400)),
              TextButton(
                onPressed: () =>
                    Get.to(() => const SeeTrendingProductScreen()),
                child: Text('See all',
                    style: fontStyle(12.sp, Colors.black, FontWeight.w400)),
              ),
            ],
          ),
          SizedBox(
            height: 260.h,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 5.h),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.trendingProductsList.length,
                itemBuilder: (context, index) {
                  final product = controller.trendingProductsList[index];
                  final productId = product['id'] as int;
                  final cartProvider = Provider.of<CartProvider>(context);
                  final favoriteProvider =
                      Provider.of<FavoriteProvider>(context);
                  final isWishlisted = _wishlistItems.any((e) =>
                      int.tryParse('${e['product_id']}') == productId);

                  return Stack(
                    children: [
                      InkWell(
                        onTap: () => Get.to(
                          () => ProductDetailsScreen(productDetails: product),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          margin: EdgeInsets.only(right: 5.w),
                          width: 155.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.r),
                            color: ColorPalette.cardColor,
                            border:
                                Border.all(color: ColorPalette.primaryColor),
                            boxShadow: const [
                              BoxShadow(
                                  blurRadius: 4,
                                  color: Colors.black12,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 8,
                                child: CachedNetworkImage(
                                  imageUrl: '${product['image']}',
                                  progressIndicatorBuilder:
                                      (context, url, progress) => Container(
                                    height: 90.h,
                                    width: 60.w,
                                    margin: EdgeInsets.all(5.w),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(8.r),
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(ImageAssets.productJPG,
                                          scale: 2),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Expanded(
                                flex: 10,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${product['name']} - ${product['brand']?['brand_name']?.toString().split(' ').first ?? ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: fontStyle(
                                          12, Colors.black, FontWeight.w500),
                                    ),
                                    Text(
                                      '৳${product['after_discount_price']}',
                                      style: fontStyle(12.sp, Colors.black,
                                          FontWeight.w600),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '৳${product['sell_price']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w400,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor: Colors.red,
                                            decorationThickness: 3,
                                          ),
                                        ),
                                        SizedBox(width: 9.w),
                                        Text(
                                          '৳${double.tryParse('${product['discount']}')?.toStringAsFixed(2) ?? '0.00'}',
                                          style: fontStyle(12, Colors.green,
                                              FontWeight.w600),
                                        ),
                                        if ('${product['discount_type']}'
                                                .toLowerCase() ==
                                            'percent')
                                          Text('% Off',
                                              style: fontStyle(12,
                                                  Colors.green,
                                                  FontWeight.w600))
                                        else
                                          Text(
                                              ' ${product['discount_type']}',
                                              style: fontStyle(11,
                                                  Colors.green,
                                                  FontWeight.w600)),
                                      ],
                                    ),
                                    cartProvider.getProductQuantityById(
                                                productId) ==
                                            0
                                        ? InkWell(
                                            onTap: isProductAvailable(product)
                                                ? () {
                                                    setState(() {
                                                      productQuantities[
                                                              productId] =
                                                          (productQuantities[
                                                                      productId] ??
                                                                  0) +
                                                              1;
                                                    });
                                                    SchedulerBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) =>
                                                                addToCart(
                                                                    index));
                                                  }
                                                : null,
                                            child: Container(
                                              height: 28.h,
                                              width: 80.w,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10.w,
                                                  vertical: 5.h),
                                              decoration: BoxDecoration(
                                                color: productStatusColor(
                                                    product),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                      productStatusLabel(
                                                          product),
                                                      style: fontStyle(
                                                          10.sp,
                                                          Colors.white,
                                                          FontWeight.w400)),
                                                  if (isProductAvailable(
                                                      product))
                                                    const Icon(Icons.add,
                                                        color: Colors.white,
                                                        size: 18),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    final qty = cartProvider
                                                        .getProductQuantityById(
                                                            productId);
                                                    cartProvider
                                                        .updateQuantityById(
                                                            productId,
                                                            qty - 1);
                                                  });
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                    color: ColorPalette
                                                        .primaryColor,
                                                  ),
                                                  child: const Icon(
                                                      Icons.remove,
                                                      color: Colors.white),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Text(
                                                  '${cartProvider.getProductQuantityById(productId)}',
                                                  style: fontStyle(
                                                      18,
                                                      const Color.fromARGB(
                                                          255, 184, 11, 11),
                                                      FontWeight.w400),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    final qty = cartProvider
                                                        .getProductQuantityById(
                                                            productId);
                                                    cartProvider
                                                        .updateQuantityById(
                                                            productId,
                                                            qty + 1);
                                                  });
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                    color: ColorPalette
                                                        .primaryColor,
                                                  ),
                                                  child: const Icon(Icons.add,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Wishlist heart icon
                      Positioned(
                        top: 8.h,
                        right: 12.w,
                        child: GestureDetector(
                          onTap: () async {
                            favoriteProvider.toggleFavorite(productId);
                            if (favoriteProvider.isFavorite(productId)) {
                              await _addToWishlist(productId);
                            } else {
                              await _removeFromWishlist(productId);
                            }
                          },
                          child: Icon(
                            (favoriteProvider.isFavorite(productId) ||
                                    isWishlisted)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: const Color(0xffE40404),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}
