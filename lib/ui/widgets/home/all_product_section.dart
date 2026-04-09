// ignore_for_file: avoid_print, use_build_context_synchronously, non_constant_identifier_names, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, unused_element

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:omnicare_app/Auth/login_screen.dart';
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/controller/product_controller.dart';
import 'package:omnicare_app/services/button_provider.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/network_checker_screen/network_checker_screen.dart';
import 'package:omnicare_app/ui/subscreens/product_details_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:omnicare_app/ui/widgets/home/see_all_product_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllProductSection extends StatefulWidget {
  const AllProductSection({
    super.key,
  });

  @override
  State<AllProductSection> createState() => _AllProductSectionState();
}

class _AllProductSectionState extends State<AllProductSection> {
  // List<bool> isFavouriteList = [];
  List<CartItem> cartItems = [];
  //List<dynamic> controller.allproductsList = [];
  //bool inProgress = false;
  //bool showAllProducts = false;
  bool showQuantityButtons = false;
  int quantity = 0;
  // Map to store quantity for each product
  Map<int, int> productQuantities = {};
  List<Map<String, dynamic>> _wishlistItems = [];

  final controller = Get.find<ProductController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch wishlist every time the screen is opened
    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    try {
      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        print('Authorization token is missing.');
        return;
      }
      final response = await http.get(
        Uri.parse('https://app.medonetrade.com/api/wishlist'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Iterate through the wishlist items and add a timestamp for each item
        if (mounted) {
          setState(() {
            _wishlistItems =
                List<Map<String, dynamic>>.from(responseData['data'])
                    .map((item) {
              return {...item};
            }).toList();
          });
        }
        // Sort the wishlist items based on the timestamp, with the latest added item appearing first
      }
    } catch (error) {
      print('Error: $error');
      // Display a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  Future<void> addToWishlist(int productId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('accessToken');
    if (accessToken != null) {
      try {
        final response = await http.get(
          Uri.parse(
              'https://app.medonetrade.com/api/addToWishlist/$productId'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        if (response.statusCode == 200) {
          // Product added to wishlist successfully
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Product added to wishlist'),
          //   ),
          // );
        } else {
          // Failed to add product to wishlist
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Failed to add product to wishlist'),
          //   ),
          // );
        }
      } catch (error) {
        // Error occurred during request
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
          ),
        );
      }
    } else {
      // No access token found, user not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add to wishlist'),
        ),
      );
    }
  }

  Future<void> removeFromWishlist(int wishlistId) async {
    try {
      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        print('Authorization token is missing.');
        return;
      }
      final Uri url = Uri.parse(
          'https://app.medonetrade.com/api/removeFromWishlist/$wishlistId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        print('Product removed from wishlist successfully');
        // Remove the item from the _wishlistItems list
        setState(() {
          _wishlistItems.removeWhere((item) => item['id'] == wishlistId);
        });
      } else {
        print(
            'Failed to remove product from wishlist. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
      // Display a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void updateFavoriteStatus(List<dynamic> wishlistData) {
    // Initialize a set to store the product IDs present in the wishlist
    Set<int> wishlistProductIds = {};
    // Extract product IDs from the wishlistData and add them to the set
    for (var item in wishlistData) {
      var productId = item['product_id'];
      if (productId != null) {
        wishlistProductIds.add(productId);
      }
    }
    // Update isFavouriteList based on wishlistProductIds
    for (int i = 0; i < controller.allproductsList.length; i++) {
      var productId = controller.allproductsList[i]['id'] as int;
      if (wishlistProductIds.contains(productId)) {
        // If the product ID exists in the wishlist, set the corresponding index in isFavouriteList to true
        controller.isFavouriteList[i] = true;
      } else {
        // Otherwise, set it to false
        controller.isFavouriteList[i] = false;
      }
    }
  }

  Future<void> _handleTokenRefresh(Function onRefreshComplete) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? refreshToken = prefs.getString('refreshToken');
    if (refreshToken != null) {
      final String? newAccessToken = await _refreshToken(refreshToken);
      if (newAccessToken != null) {
        prefs.setString('accessToken', newAccessToken);
        await onRefreshComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            duration: Duration(seconds: 2),
          ),
        );
        Get.to(() => const LoginScreen());
      }
    }
  }

  Future<String?> _getAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<String?> _refreshToken(String refreshToken) async {
    const String apiUrl = 'https://app.medonetrade.com/api/refresh';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'refresh_token': refreshToken,
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> authorization =
            responseData['authorization'];
        return authorization['token'];
      } else {
        return null;
      }
    } catch (error) {
      print('Error during token refresh: $error');
      return null;
    }
  }

  Future<void> _checkNetworkAndLoggedIn() async {
    bool hasNetwork = await checkNetwork();
    bool userLoggedIn = await isLoggedIn();

    if (hasNetwork && userLoggedIn) {
      fetchWishlist();
    } else {
      Get.to(() => const NetworkCheckScreen());
    }
  }

  void addToCart(int index) {
    var cartProvider = Provider.of<CartProvider>(context, listen: false);
    var existingItem = cartItems.firstWhere(
      (item) => item.name == controller.allproductsList[index]['name'],
      orElse: () => CartItem(
        id: 0,
        image: 'default_image_path',
        name: 'Unknown Product',
        sell_price: 0.0,
        after_discount_price: 0.0,
        company_name: 'Unknown Company',
        subtitle: 'Unknown',
        quantity: 0,
      ),
    );
    if (existingItem.quantity > 0) {
      cartProvider.updateCartItemQuantity(existingItem, existingItem.quantity);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Container(
      //       height: 30.h,
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         children: [
      //           const Text('Item is already in the cart'),
      //           TextButton(
      //             onPressed: () {
      //               Get.to(const CartScreen());
      //             },
      //             child: const Text('View', style: TextStyle(color: Colors.yellow)),
      //           )
      //         ],
      //       ),
      //     ),
      //   ),
      // );
      context.read<QuantityButtonsProvider>().setShowQuantityButtons(true);
    } else {
      var productId = controller.allproductsList[index]['id'] as int;
      var item = CartItem(
        id: productId,
        image:
            controller.allproductsList[index]['image'] ?? 'default_image_path',
        name: controller.allproductsList[index]['name'] ?? 'Unknown Product',
        sell_price: double.parse(
            '${controller.allproductsList[index]['sell_price'].replaceAll(',', '')}'),
        after_discount_price: double.parse(
            '${controller.allproductsList[index]['after_discount_price'].replaceAll(',', '')}'),
        company_name: controller.allproductsList[index]['brand']
                ['brand_name'] ??
            'Unknown Company',
        subtitle:
            controller.allproductsList[index]['name'] ?? 'Unknown Product',
        quantity: 1,
        addedFromProductDetails: true,
      );
      cartProvider.addToCart(item);
      cartProvider.updateQuantity(productId, 1);
      context.read<QuantityButtonsProvider>().setShowQuantityButtons(false);
    }
  }

  // This method updates the quantity in the productQuantities map
  void updateProductQuantityInMap(int productId, int newQuantity) {
    setState(() {
      productQuantities[productId] = newQuantity;

      // Check if the new quantity is zero
      if (newQuantity == 0) {
        // Remove the product from the cart
        var cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.removeFromCartById(productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    cartItems = Provider.of<CartProvider>(context).cartItems;
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    return ChangeNotifierProvider(
      create: (context) {
        return QuantityButtonsProvider();
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "All Product",
                style: fontStyle(12.sp, Colors.black, FontWeight.w400),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    Get.to(() => const SeeAllProductScreen());
                  });
                },
                child: Text(
                  "See all",
                  style: fontStyle(12.sp, Colors.black, FontWeight.w400),
                ),
              )
            ],
          ),
          controller.inProgress.value
              ? SizedBox(
                  height: 160,
                  child: Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      size: 40,
                      color: ColorPalette.primaryColor,
                    ),
                  ),
                )
              : SizedBox(
                  height: 270.h,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.allproductsList.length,
                      itemBuilder: (context, index) {
                        var cartProviders =
                            Provider.of<CartProvider>(context, listen: false);
                        return Stack(
                          children: [
                            InkWell(
                              onTap: () {
                                Get.to(
                                  () => ProductDetailsScreen(
                                    productDetails:
                                        controller.allproductsList[index],
                                  ),
                                );
                              },
                              child: Container(
                                clipBehavior: Clip.hardEdge,
                                padding: EdgeInsets.all(8.w),
                                margin: EdgeInsets.only(right: 5.w),
                                width: 155.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.r),
                                  color: ColorPalette.cardColor,
                                  border: Border.all(
                                      color: ColorPalette.primaryColor),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 4,
                                      color: Colors.black12,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: 8,
                                      child: CachedNetworkImage(
                                        imageUrl: controller
                                            .allproductsList[index]['image']
                                            .toString(),
                                        progressIndicatorBuilder:
                                            (context, url, downloadProgress) =>
                                                Center(
                                          child: Container(
                                            height: 90.h,
                                            width: 60.w,
                                            margin: EdgeInsets.all(5.w),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Image.asset(
                                          ImageAssets.productJPG,
                                          scale: 2,
                                        ),
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
                                            '${controller.allproductsList[index]['name']} - ${controller.allproductsList[index]['brand']['brand_name'].split(' ').first}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: fontStyle(
                                              12,
                                              Colors.black,
                                              FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '৳${controller.allproductsList[index]['after_discount_price']}',
                                            style: fontStyle(12.sp,
                                                Colors.black, FontWeight.w600),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '৳${controller.allproductsList[index]['sell_price']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w400,
                                                  decoration: TextDecoration.lineThrough,
                                                  decorationColor: Colors.red,
                                                  decorationThickness: 3,
                                                ),
                                              ),
                                              SizedBox(width: 9.w),
                                              Row(
                                                children: [
                                                  Text(
                                                    '৳${double.tryParse('${controller.allproductsList[index]['discount']}'.replaceAll(',', ''))?.toStringAsFixed(2) ?? '0.00'}',
                                                    style: fontStyle(12, Colors.green, FontWeight.w600),
                                                  ),
                                                  if (controller.allproductsList[index]['discount_type']?.toLowerCase() == 'percent')
                                                    Text('% Off', style: fontStyle(12, Colors.green, FontWeight.w600)),
                                                  if (controller.allproductsList[index]['discount_type']?.toLowerCase() != 'percent')
                                                    Text(' ${controller.allproductsList[index]['discount_type']}', style: fontStyle(11, Colors.green, FontWeight.w600)),
                                                ],
                                              ),
                                            ],
                                          ),
                                          cartProviders.getProductQuantityById(controller.allproductsList[index]['id']) == 0
                                              ? InkWell(
                                                  onTap: isProductAvailable(controller.allproductsList[index])
                                                      ? () {
                                                          setState(() {
                                                            productQuantities[controller.allproductsList[index]['id']] =
                                                                (productQuantities[controller.allproductsList[index]['id']] ?? 0) + 1;
                                                            showQuantityButtons = true;
                                                          });
                                                          SchedulerBinding.instance.addPostFrameCallback((_) { addToCart(index); });
                                                        }
                                                      : null,
                                                  child: Container(
                                                    height: 28.h,
                                                    width: 80.w,
                                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                                    decoration: BoxDecoration(
                                                      color: productStatusColor(controller.allproductsList[index]),
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(productStatusLabel(controller.allproductsList[index]), style: fontStyle(10.sp, Colors.white, FontWeight.w400)),
                                                        if (isProductAvailable(controller.allproductsList[index]))
                                                          const Icon(Icons.add, color: Colors.white, size: 18),
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
                                                          var q = cartProviders.getProductQuantityById(controller.allproductsList[index]['id']);
                                                          cartProviders.updateQuantityById(controller.allproductsList[index]['id'], q - 1);
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: ColorPalette.primaryColor),
                                                        child: const Icon(Icons.remove, color: Colors.white, size: 16),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                      child: Text(
                                                        '${cartProviders.getProductQuantityById(controller.allproductsList[index]['id'])}',
                                                        style: fontStyle(14, const Color.fromARGB(255, 184, 11, 11), FontWeight.w400),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          var q = cartProviders.getProductQuantityById(controller.allproductsList[index]['id']);
                                                          cartProviders.updateQuantityById(controller.allproductsList[index]['id'], q + 1);
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: ColorPalette.primaryColor),
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
                            ),
                            Positioned(
                              top: 10.h,
                              right: 15.w,
                              child: GestureDetector(
                                onTap: () async {
                                  favoriteProvider.toggleFavorite(controller.allproductsList[index]['id']);
                                  if (favoriteProvider.isFavorite(controller.allproductsList[index]['id'])) {
                                    await addToWishlist(controller.allproductsList[index]['id']);
                                  } else {
                                    int? wishlistId;
                                    for (var item in _wishlistItems) {
                                      int wid = int.tryParse('${item['product_id']}') ?? -1;
                                      if (wid == controller.allproductsList[index]['id']) {
                                        wishlistId = item['id'];
                                        break;
                                      }
                                    }
                                    if (wishlistId != null) await removeFromWishlist(wishlistId);
                                  }
                                },
                                child: Icon(
                                  favoriteProvider.isFavorite(controller.allproductsList[index]['id']) ? Icons.favorite : Icons.favorite_border,
                                  color: const Color(0xffE40404),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                )
        ],
      ),
    );
  }
}
