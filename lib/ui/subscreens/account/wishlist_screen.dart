// ignore_for_file: avoid_print, use_build_context_synchronously, unused_element

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/Auth/login_screen.dart';
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/network_checker_screen/network_checker_screen.dart';
import 'package:omnicare_app/ui/screens/cart_screen.dart';
import 'package:omnicare_app/ui/screens/shimmer_widget.dart';
import 'package:omnicare_app/ui/subscreens/product_details_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> _wishlistItems = [];
  List<CartItem> cartItems = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkAndLoggedIn();
  }

  // Modify fetchWishlist() to include timestamp for each item
  Future<void> fetchWishlist() async {
    try {
      setState(() {
        isLoading = true;
      });
      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        print('Authorization token is missing.');
        return;
      }
      final response = await http.get(
        Uri.parse('https://stage.medone.primeharvestbd.com/api/wishlist'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _wishlistItems =
              List<Map<String, dynamic>>.from(responseData['data']).map((item) {
            return {...item, 'timestamp': DateTime.now()};
          }).toList();
        });
        // Sort the wishlist items based on the timestamp, with the latest added item appearing first
        _wishlistItems.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add this function to handle deletion of items from the wishlist
  Future<void> removeFromWishlist(int wishlistId) async {
    try {
      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        print('Authorization token is missing.');
        return;
      }
      final Uri url = Uri.parse(
          'https://stage.medone.primeharvestbd.com/api/removeFromWishlist/$wishlistId');
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
        // Display a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to remove product from wishlist. Please try again later.'),
            duration: Duration(seconds: 2),
          ),
        );
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

  void addToCart(int index) {
    var cartProvider = Provider.of<CartProvider>(context, listen: false);
    var productData = _wishlistItems[index]['product'];

    if (productData != null) {
      var existingItem = cartItems.firstWhere(
        (item) => item.name == productData['name'],
        orElse: () => CartItem(
          id: 0,
          image: 'default_image_path',
          name: 'Unknown Product',
          sell_price: 0.0,
          after_discount_price: 0.0,
          subtitle: 'Unknown Subtitle',
          company_name: 'Unknown Company',
          quantity: 0,
        ),
      );

      if (existingItem.quantity > 0) {
        cartProvider.updateCartItemQuantity(
            existingItem, existingItem.quantity);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SizedBox(
              height: 30.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Item is already in the cart'),
                  TextButton(
                    onPressed: () {
                      Get.to(const CartScreen());
                    },
                    child: const Text('View',
                        style: TextStyle(color: Colors.yellow)),
                  )
                ],
              ),
            ),
          ),
        );
      } else {
        var productId = productData['id'] as int;
        var item = CartItem(
          id: productId,
          image: productData['image'] ?? 'default_image_path',
          name: productData['name'] ?? 'Unknown Product',
          sell_price: double.tryParse('${productData['sell_price']}') ?? 0.0,
          after_discount_price:
              double.tryParse('${productData['after_discount_price']}') ?? 0.0,
          subtitle: productData['subtitle'] ?? 'Unknown Subtitle',
          company_name: productData['brand']['brand_name'] ?? 'Unknown Company',
          quantity: 1,
          addedFromProductDetails: true,
        );
        cartProvider.addToCart(item);
        cartProvider.updateQuantity(productId, 1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SizedBox(
              height: 30.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Added to cart'),
                  TextButton(
                    onPressed: () {
                      Get.to(const CartScreen());
                    },
                    child: const Text('View',
                        style: TextStyle(color: Colors.yellow)),
                  )
                ],
              ),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product data not available. Unable to add to cart.'),
          duration: Duration(seconds: 2),
        ),
      );
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
    const String apiUrl = 'https://stage.medone.primeharvestbd.com/api/refresh';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Wishlist',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchWishlist();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: isLoading
                ? const ShimmerWidget()
                : Column(
                    children: _wishlistItems
                        .asMap()
                        .entries
                        .map((MapEntry<int, Map<String, dynamic>> entry) {
                      final int index = entry.key;
                      final Map<String, dynamic> item = entry.value;
                      final Map<String, dynamic>? productData = item['product'];
                      if (productData != null) {
                        return InkWell(
                          onTap: () {
                            Get.to(ProductDetailsScreen(
                                productDetails: productData));
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 10.h),
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 11.h),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xff8AB9FF)),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 95.h,
                                  width:
                                      MediaQuery.of(context).size.width * 0.25,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff8AB9FF),
                                    borderRadius: BorderRadius.circular(5.r),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.r),
                                    child: Image.network(
                                      productData['image'] ??
                                          '', // Use product image URL
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          ImageAssets.productJPG,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${productData['name'].split(' ').take(3).join(' ')} - ${productData['brand']['brand_name'].split(' ').first ?? ''}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '৳${productData['after_discount_price'] ?? ''}',
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.green),
                                        ),
                                        SizedBox(
                                          width: 80.w,
                                        ),
                                        Row(
                                          children: [
                                            InkWell(
                                                onTap: () {
                                                  // Call the function to remove the item from the wishlist
                                                  removeFromWishlist(
                                                      item['id'] as int);
                                                },
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 32,
                                                )),
                                            InkWell(
                                              onTap: () async {
                                                try {
                                                  addToCart(index);
                                                  // Remove the product from the wishlist
                                                  await removeFromWishlist(
                                                      item['id'] as int);
                                                  // ScaffoldMessenger.of(context).showSnackBar(
                                                  //   SnackBar(
                                                  //     content: Text('Product added to cart and removed from wishlist'),
                                                  //     duration: Duration(seconds: 2),
                                                  //   ),
                                                  // );
                                                } catch (error) {
                                                  print('Error: $error');
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'An error occurred. Please try again later.'),
                                                      duration:
                                                          Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  color:
                                                      ColorPalette.primaryColor,
                                                ),
                                                child: const Icon(
                                                  Icons.shopping_cart,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                    Text(
                                      '৳${productData['sell_price'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox
                            .shrink(); // Skip rendering if product data is null
                      }
                    }).toList(),
                  ),
          ),
        ),
      ),
    );
  }
}
