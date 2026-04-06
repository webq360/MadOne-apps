// ignore_for_file: non_constant_identifier_names, avoid_print, use_build_context_synchronously, unused_element

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/Auth/login_screen.dart';
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/services/button_provider.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/network_checker_screen/network_checker_screen.dart';
import 'package:omnicare_app/ui/screens/cart_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> productDetails;
  const ProductDetailsScreen({Key? key, required this.productDetails})
      : super(key: key);
  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool isFavourite = false;
  List<CartItem> cartItems = [];
  bool showQuantityButtons = false;
  int quantity = 0;
  Map<int, int> productQuantities = {};
  List<Map<String, dynamic>> _wishlistItems = [];

  double extractSellingPrice() {
    final dynamic sellingPrice = widget.productDetails['sell_price'];
    if (sellingPrice is num || sellingPrice is String) {
      return double.tryParse(sellingPrice.toString().replaceAll(',', '')) ??
          0.0;
    } else {
      return 0.0;
    }
  }

  double extractAfterDiscountPrice() {
    final dynamic afterDiscountPrice =
        widget.productDetails['after_discount_price'];
    if (afterDiscountPrice is num || afterDiscountPrice is String) {
      return double.tryParse(
              afterDiscountPrice.toString().replaceAll(',', '')) ??
          0.0;
    } else {
      return 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkNetworkAndLoggedIn();
    // Load favorite status from SharedPreferences when the widget initializes
    loadFavoriteStatus();
    //fetchWishlist();
  }

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
        setState(() {
          _wishlistItems =
              List<Map<String, dynamic>>.from(responseData['data']).map((item) {
            return {
              ...item,
            };
          }).toList();
        });
        // Sort the wishlist items based on the timestamp, with the latest added item appearing first
        //  _wishlistItems.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      }
      // else {
      //   print('Failed to load wishlist. Status code: ${response.statusCode}');
      //   // Display a message to the user
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Failed to load wishlist. Please try again later.'),
      //       duration: Duration(seconds: 2),
      //     ),
      //   );
      // }
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

  Future<void> addToWishlist(int productId, BuildContext context) async {
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
          // Toggle favorite status using the FavoriteProvider
          Provider.of<FavoriteProvider>(context, listen: false)
              .toggleFavorite(productId);
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

  Future<void> removeFromWishlist(String productId) async {
    try {
      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        print('Authorization token is missing.');
        return;
      }
      print('Wishlist items before removal: $_wishlistItems');
      // Find the wishlist item index with the matching product ID
      final int wishlistIndex =
          _wishlistItems.indexWhere((item) => item['product_id'] == productId);
      if (wishlistIndex == -1) {
        print('Wishlist item not found for product ID: $productId');
        return;
      }
      final int wishlistId = _wishlistItems[wishlistIndex]['id'];
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
          _wishlistItems.removeAt(wishlistIndex);
          isFavourite = false;
        });
        // Update the favorite icon wherever the product is used
        Provider.of<FavoriteProvider>(context, listen: false)
            .toggleFavorite(int.parse(productId));
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

  Future<void> loadFavoriteStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int productId = widget.productDetails['id'];
    final bool? isFavorite = prefs.getBool('isFavorite_$productId');
    if (isFavorite != null) {
      setState(() {
        isFavourite = isFavorite;
      });
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

  void addToCart() {
    var cartProvider = Provider.of<CartProvider>(context, listen: false);
    var existingItem = cartItems.firstWhere(
      (item) => item.name == widget.productDetails['name'],
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
      context.read<QuantityButtonsProvider>().setShowQuantityButtons(true);
    } else {
      var productId = widget.productDetails['id'] as int;
      var item = CartItem(
        id: productId,
        image: widget.productDetails['image'] ?? 'default_image_path',
        name: widget.productDetails['name'] ?? 'Unknown Product',
        sell_price: extractSellingPrice(),
        after_discount_price: extractAfterDiscountPrice(),
        company_name:
            widget.productDetails['brand']['brand_name'] ?? 'Unknown Company',
        subtitle: widget.productDetails['subtitle'] ?? 'Unknown',
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
    double sell_price = extractSellingPrice();
    double after_discount_price = extractAfterDiscountPrice();
    var favoriteProvider = Provider.of<FavoriteProvider>(context);
    bool isFavorite =
        favoriteProvider.isFavorite(widget.productDetails['id']) || isFavourite;
    var cartProviders = Provider.of<CartProvider>(context, listen: false);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ColorPalette.primaryColor,
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          title: const Text(
            'Product Details',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
            child: ChangeNotifierProvider(
              create: (context) {
                return QuantityButtonsProvider();
              },
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Center(
                          child: Image.network(
                            widget.productDetails['image'] ??
                                '', // Use an empty string if image URL is null
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Return a fallback image when an error occurs
                              return Image.asset(
                                ImageAssets.productJPG,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 10.h,
                          right: 10.w,
                          child: // Inside the build method of ProductDetailsScreen
                              Consumer<FavoriteProvider>(
                            builder: (context, favoriteProvider, _) {
                              return IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : null,
                                  // favoriteProvider.isFavorite(widget.productDetails['id']) ? Icons.favorite : Icons.favorite_border,
                                  // color: favoriteProvider.isFavorite(widget.productDetails['id']) ? Colors.red : null,
                                ),
                                onPressed: () async {
                                  // String productId = widget.productDetails['id'].toString(); // Convert to string
                                  //  if (favoriteProvider.isFavorite(int.parse(productId))) {
                                  String productId =
                                      widget.productDetails['id'].toString();
                                  if (isFavorite) {
                                    // Remove from wishlist if already favorited
                                    await removeFromWishlist(productId);
                                  } else {
                                    // Add to wishlist if not already favorited
                                    await addToWishlist(
                                        int.parse(productId), context);
                                  }
                                  setState(() {
                                    isFavorite = !isFavorite;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productDetails['name'] ?? 'Unknown Product',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          // Text(
                          //   widget.productDetails['brand'] != null && widget.productDetails['brand']['brand_name'] != null
                          //       ? widget.productDetails['brand']['brand_name'] : 'Unknown company',
                          //   style: const TextStyle(fontSize: 12, color: Color(0xff555555), fontWeight: FontWeight.w400,),
                          // ),
                          Text(
                            (widget.productDetails['brand'] != null &&
                                    widget.productDetails['brand']
                                            ['brand_name'] !=
                                        null)
                                ? widget.productDetails['brand']['brand_name']
                                : (widget.productDetails['company_name'] ??
                                    'Unknown company'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff555555),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Product Price',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '৳ $sell_price'.replaceAll(',', ''),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.red,
                          decorationThickness: 3,
                        ),
                      ),
                      Text(
                        '৳ $after_discount_price'.replaceAll(',', ''),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      // Display either the "ADD" button or quantity control buttons
                      int.parse(cartProviders
                                  .getProductQuantityById(
                                      widget.productDetails['id'])
                                  .toString()) ==
                              0
                          ? InkWell(
                              onTap: () {
                                setState(() {
                                  productQuantities[
                                          widget.productDetails['id']] =
                                      (productQuantities[widget
                                                  .productDetails['id']] ??
                                              0) +
                                          1;
                                  showQuantityButtons = true;
                                });
                                SchedulerBinding.instance
                                    .addPostFrameCallback((_) {
                                  addToCart();
                                });
                              },
                              child: Container(
                                height: 45.h,
                                width: 280.w,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorPalette.primaryColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Text(
                                    'Add to cart',
                                    style: fontStyle(
                                      16.sp,
                                      Colors.white,
                                      FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 45.h,
                              width: 280.w,
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: ColorPalette.primaryColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ///decrement cart quantity
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        var quantity = cartProviders
                                            .getProductQuantityById(
                                          widget.productDetails['id'],
                                        );
                                        quantity--;

                                        cartProviders.updateQuantityById(
                                          widget.productDetails['id'],
                                          quantity,
                                        );
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        borderRadius: BorderRadius.circular(30),
                                        color: ColorPalette.primaryColor,
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  ///cart quantity
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20, right: 20),
                                    child: Text(
                                      '${int.parse(cartProviders.getProductQuantityById(widget.productDetails['id']).toString())}',
                                      style: fontStyle(
                                        18,
                                        Colors.white,
                                        FontWeight.w400,
                                      ),
                                    ),
                                  ),

                                  ///inecrement cart quantity
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        var quantity = cartProviders
                                            .getProductQuantityById(
                                          widget.productDetails['id'],
                                        );
                                        quantity++;

                                        cartProviders.updateQuantityById(
                                          widget.productDetails['id'],
                                          quantity,
                                        );
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        borderRadius: BorderRadius.circular(30),
                                        color: ColorPalette.primaryColor,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      Container(
                        margin: EdgeInsets.only(left: 8.w),
                        child: InkWell(
                          onTap: () {
                            Get.to(const CartScreen());
                          },
                          child: const Icon(
                            Icons.shopping_cart,
                            color: Colors.black,
                            size: 35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Product Details",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        widget.productDetails['long_desc'] ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          height: 1.8,
                          wordSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
