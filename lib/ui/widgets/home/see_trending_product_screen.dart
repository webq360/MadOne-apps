// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/screens/shimmer_widget.dart';
import 'package:omnicare_app/ui/subscreens/product_details_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:omnicare_app/ui/widgets/home/search_product_screen.dart';
import 'package:omnicare_app/util/app_constants.dart';
import 'package:provider/provider.dart';

class SeeTrendingProductScreen extends StatefulWidget {
  const SeeTrendingProductScreen({super.key});

  @override
  State<SeeTrendingProductScreen> createState() =>
      _SeeTrendingProductScreenState();
}

class _SeeTrendingProductScreenState extends State<SeeTrendingProductScreen> {
  List<dynamic> productsList = [];
  bool inProgress = false;
  Map<int, int> productQuantities = {};

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => inProgress = true);
    try {
      // top-sales only has {id, name, total_sold} — fetch full product data too
      final results = await Future.wait([
        http.get(Uri.parse(AppConstants.topSales)),
        http.get(Uri.parse(AppConstants.allProducts)),
      ]);

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final topJson = jsonDecode(results[0].body);
        final allJson = jsonDecode(results[1].body);

        final topSalesList = topJson['data'] ?? [];
        final allProducts = allJson['data'] ?? [];

        final Map<int, dynamic> productMap = {
          for (var p in allProducts) (p['id'] as int): p
        };

        final enriched = <dynamic>[];
        for (final item in topSalesList) {
          final id = item['id'] as int?;
          if (id != null && productMap.containsKey(id)) {
            enriched.add(productMap[id]);
          }
        }
        if (mounted) setState(() => productsList = enriched);
      } else {
        print('Failed to load trending. Status: ${results[0].statusCode}');
      }
    } catch (e) {
      print('Trending fetch error: $e');
    } finally {
      if (mounted) setState(() => inProgress = false);
    }
  }

  void addToCart(int index) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final product = productsList[index];
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
        after_discount_price: double.parse('${product['after_discount_price']}'.replaceAll(',', '')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Products', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Get.to(() => SearchedProductScreen()),
            icon: Icon(Icons.search_outlined, size: 30.h),
          ),
        ],
      ),
      body: inProgress && productsList.isEmpty
          ? const ShimmerWidget()
          : Padding(
              padding: EdgeInsets.all(10.w),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 270.h,
                ),
                itemCount: productsList.length,
                itemBuilder: (context, index) {
                  final product = productsList[index];
                  final productId = product['id'] as int;
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);

                  return InkWell(
                    onTap: () => Get.to(
                      () => ProductDetailsScreen(productDetails: product),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.r),
                        color: ColorPalette.cardColor,
                        border: Border.all(color: ColorPalette.primaryColor),
                        boxShadow: const [
                          BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 8,
                            child: CachedNetworkImage(
                              imageUrl: '${product['image']}',
                              progressIndicatorBuilder: (context, url, progress) =>
                                  Container(
                                height: 90,
                                color: Colors.grey[200],
                              ),
                              errorWidget: (_, __, ___) =>
                                  Image.asset(ImageAssets.productJPG, scale: 2),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Expanded(
                            flex: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${product['name']} - ${product['brand']?['brand_name']?.toString().split(' ').first ?? ''}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: fontStyle(12, Colors.black, FontWeight.w500),
                                ),
                                Text(
                                  '৳${product['after_discount_price']}',
                                  style: fontStyle(12.sp, Colors.black, FontWeight.w600),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '৳${product['sell_price']}',
                                      style: const TextStyle(
                                        fontSize: 12, color: Colors.grey,
                                        fontWeight: FontWeight.w400,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: Colors.red,
                                        decorationThickness: 3,
                                      ),
                                    ),
                                    SizedBox(width: 9.w),
                                    Text(
                                      '৳${double.tryParse('${product['discount']}')?.toStringAsFixed(2) ?? '0.00'}',
                                      style: fontStyle(12, Colors.green, FontWeight.w600),
                                    ),
                                    if ('${product['discount_type']}'.toLowerCase() == 'percent')
                                      Text('% Off', style: fontStyle(12, Colors.green, FontWeight.w600))
                                    else
                                      Text(' ${product['discount_type']}', style: fontStyle(11, Colors.green, FontWeight.w600)),
                                  ],
                                ),
                                // ADD / status button
                                cartProvider.getProductQuantityById(productId) == 0
                                    ? InkWell(
                                        onTap: isProductAvailable(product)
                                            ? () {
                                                setState(() {
                                                  productQuantities[productId] =
                                                      (productQuantities[productId] ?? 0) + 1;
                                                });
                                                SchedulerBinding.instance
                                                    .addPostFrameCallback((_) => addToCart(index));
                                              }
                                            : null,
                                        child: Container(
                                          height: 28.h,
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
                                          decoration: BoxDecoration(
                                            color: productStatusColor(product),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  productStatusLabel(product),
                                                  overflow: TextOverflow.ellipsis,
                                                  style: fontStyle(10.sp, Colors.white, FontWeight.w400),
                                                ),
                                              ),
                                              if (isProductAvailable(product)) ...[                                                
                                                SizedBox(width: 4.w),
                                                const Icon(Icons.add, color: Colors.white, size: 16),
                                              ],
                                            ],
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                final qty = cartProvider.getProductQuantityById(productId);
                                                cartProvider.updateQuantityById(productId, qty - 1);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(25),
                                                color: ColorPalette.primaryColor,
                                              ),
                                              child: const Icon(Icons.remove, color: Colors.white, size: 16),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                            child: Text(
                                              '${cartProvider.getProductQuantityById(productId)}',
                                              style: fontStyle(14, const Color.fromARGB(255, 184, 11, 11), FontWeight.w400),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                final qty = cartProvider.getProductQuantityById(productId);
                                                cartProvider.updateQuantityById(productId, qty + 1);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(25),
                                                color: ColorPalette.primaryColor,
                                              ),
                                              child: const Icon(Icons.add, color: Colors.white, size: 16),
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
                  );
                },
              ),
            ),
    );
  }
}
