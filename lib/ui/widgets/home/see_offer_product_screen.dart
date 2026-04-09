// ignore_for_file: avoid_print, use_build_context_synchronously, non_constant_identifier_names, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, unused_element, prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/Auth/login_screen.dart';
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/services/button_provider.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/network_checker_screen/network_checker_screen.dart';
import 'package:omnicare_app/ui/screens/shimmer_widget.dart';
import 'package:omnicare_app/ui/subscreens/product_details_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:omnicare_app/ui/widgets/home/search_product_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeeOfferedProductScreen extends StatefulWidget {
  const SeeOfferedProductScreen({
    super.key,
  });

  @override
  State<SeeOfferedProductScreen> createState() =>
      _SeeOfferedProductScreenState();
}

class _SeeOfferedProductScreenState extends State<SeeOfferedProductScreen> {
  List<bool> isFavouriteList = [];
  List<CartItem> cartItems = [];
  List<dynamic> offeredproductsList = [];
  bool inProgress = false;
  bool showQuantityButtons = false;
  int quantity = 0;
  // Map to store quantity for each product
  Map<int, int> productQuantities = {};
  List<Map<String, dynamic>> _wishlistItems = [];
  @override
  void initState() {
    super.initState();
    fetchWishlist();
    AllProducts();
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
        Uri.parse('https://stage.medone.primeharvestbd.com/api/wishlist'),
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

  void AllProducts() async {
    inProgress = true;
    setState(() {});
    try {
      final response = await http.get(Uri.parse(
          'https://stage.medone.primeharvestbd.com/api/all_offered_products'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            offeredproductsList = json;
            isFavouriteList = List.filled(offeredproductsList.length, false);
          });
        }
        print(offeredproductsList);
      } else {
        print(
            'Failed to load company names. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
    inProgress = false;
    setState(() {});
    Provider.of<CartProvider>(context, listen: false).notifyListeners();
  }

  Future<void> addToWishlist(int productId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('accessToken');
    if (accessToken != null) {
      try {
        final response = await http.get(
          Uri.parse(
              'https://stage.medone.primeharvestbd.com/api/addToWishlist/$productId'),
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
    for (int i = 0; i < offeredproductsList.length; i++) {
      var productId = offeredproductsList[i]['id'] as int;
      if (wishlistProductIds.contains(productId)) {
        // If the product ID exists in the wishlist, set the corresponding index in isFavouriteList to true
        isFavouriteList[i] = true;
      } else {
        // Otherwise, set it to false
        isFavouriteList[i] = false;
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
    const String apiUrl =
        'https://stage.medone.primeharvestbd.com/api/refresh';
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
      (item) => item.name == offeredproductsList[index]['name'],
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
      var productId = offeredproductsList[index]['id'] as int;
      var item = CartItem(
        id: productId,
        image: offeredproductsList[index]['image'] ?? 'default_image_path',
        name: offeredproductsList[index]['name'] ?? 'Unknown Product',
        sell_price: double.parse(
            '${offeredproductsList[index]['sell_price'].replaceAll(',', '')}'),
        after_discount_price: double.parse(
            '${offeredproductsList[index]['after_discount_price'].replaceAll(',', '')}'),
        company_name: offeredproductsList[index]['brand']['brand_name'] ??
            'Unknown Company',
        subtitle: offeredproductsList[index]['name'] ?? 'Unknown Product',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Offer Products",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Get.to(() => SearchedProductScreen());
            },
            icon: Icon(
              Icons.search_outlined,
              size: 30.h,
            ),
          ),
        ],
      ),
      body: inProgress
          ? ShimmerWidget()
          : ChangeNotifierProvider(
              create: (context) {
                return QuantityButtonsProvider();
              },
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 260.h,
                  ),
                  itemCount: offeredproductsList.length,
                  itemBuilder: (context, index) {
                    var cartProviders =
                        Provider.of<CartProvider>(context, listen: false);
                    return Stack(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(
                              () => ProductDetailsScreen(
                                productDetails: offeredproductsList[index],
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.r),
                              color: ColorPalette.cardColor,
                              border:
                                  Border.all(color: ColorPalette.primaryColor),
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
                                  child: Image.network(
                                    '${offeredproductsList[index]['image']}',
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        ImageAssets.productJPG,
                                        scale: 2,
                                      );
                                    },
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
                                        '${offeredproductsList[index]['name']} - ${offeredproductsList[index]['brand']['brand_name'].split(' ').first}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: fontStyle(
                                          12,
                                          Colors.black,
                                          FontWeight.w500,
                                        ),
                                      ),

                                      Text(
                                        '৳${offeredproductsList[index]['after_discount_price']}',
                                        style: fontStyle(12.sp, Colors.black,
                                            FontWeight.w600),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '৳${offeredproductsList[index]['sell_price']}',
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
                                          Row(
                                            children: [
                                              Text(
                                                '৳${double.parse(offeredproductsList[index]['discount']).toStringAsFixed(2)}',
                                                style: fontStyle(
                                                  12,
                                                  Colors.green,
                                                  FontWeight.w600,
                                                ),
                                              ),
                                              if (offeredproductsList[index]
                                                          ['discount_type']
                                                      ?.toLowerCase() ==
                                                  'percent')
                                                Text(
                                                  '% Off',
                                                  style: fontStyle(
                                                      12,
                                                      Colors.green,
                                                      FontWeight.w600),
                                                ),
                                              if (offeredproductsList[index]
                                                          ['discount_type']
                                                      ?.toLowerCase() !=
                                                  'percent')
                                                Text(
                                                  ' ${offeredproductsList[index]['discount_type']}',
                                                  style: fontStyle(
                                                    11,
                                                    Colors.green,
                                                    FontWeight.w600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Display either the "ADD" button or quantity control buttons
                                      int.parse(cartProviders
                                                  .getProductQuantityById(
                                                      offeredproductsList[index]
                                                          ['id'])
                                                  .toString()) ==
                                              0
                                          ? InkWell(
                                              onTap: isProductAvailable(offeredproductsList[index])
                                                  ? () {
                                                      setState(() {
                                                        productQuantities[
                                                                offeredproductsList[
                                                                    index]['id']] =
                                                            (productQuantities[
                                                                        offeredproductsList[
                                                                                index]
                                                                            ['id']] ??
                                                                    0) +
                                                                1;
                                                        showQuantityButtons = true;
                                                      });
                                                      SchedulerBinding.instance
                                                          .addPostFrameCallback((_) {
                                                        addToCart(index);
                                                      });
                                                    }
                                                  : null,
                                              child: Container(
                                                height: 28.h,
                                                width: 80.w,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.w,
                                                  vertical: 5.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: productStatusColor(offeredproductsList[index]),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        productStatusLabel(offeredproductsList[index]),
                                                        style: fontStyle(
                                                          10.sp,
                                                          Colors.white,
                                                          FontWeight.w400,
                                                        ),
                                                      ),
                                                      if (isProductAvailable(offeredproductsList[index]))
                                                        const Icon(
                                                          Icons.add,
                                                          color: Colors.white,
                                                          size: 18,
                                                        )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                ///decrement cart quantity
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      var quantity = cartProviders
                                                          .getProductQuantityById(
                                                        offeredproductsList[
                                                            index]['id'],
                                                      );
                                                      quantity--;

                                                      cartProviders
                                                          .updateQuantityById(
                                                        offeredproductsList[
                                                            index]['id'],
                                                        quantity,
                                                      );
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
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),

                                                ///cart quantity
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: Text(
                                                    '${int.parse(cartProviders.getProductQuantityById(offeredproductsList[index]['id']).toString())}',
                                                    style: fontStyle(
                                                      18,
                                                      const Color.fromARGB(
                                                        255,
                                                        184,
                                                        11,
                                                        11,
                                                      ),
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
                                                        offeredproductsList[
                                                            index]['id'],
                                                      );
                                                      quantity++;

                                                      cartProviders
                                                          .updateQuantityById(
                                                        offeredproductsList[
                                                            index]['id'],
                                                        quantity,
                                                      );
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        25,
                                                      ),
                                                      color: ColorPalette
                                                          .primaryColor,
                                                    ),
                                                    child: const Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10.h,
                          right: 10.w,
                          child: GestureDetector(
                            onTap: () async {
                              // Toggle the favorite status in the provider
                              favoriteProvider.toggleFavorite(
                                  offeredproductsList[index]['id']);
                              // Perform the appropriate action based on the updated status
                              if (favoriteProvider.isFavorite(
                                  offeredproductsList[index]['id'])) {
                                // If the product is now in the wishlist, add it
                                await addToWishlist(
                                    offeredproductsList[index]['id']);
                              } else {
                                int? wishlistId;

                                for (var item in _wishlistItems) {
                                  String productId = item['product_id'];
                                  int wishlistProductId =
                                      int.tryParse(productId) ?? -1;

                                  if (wishlistProductId ==
                                      offeredproductsList[index]['id']) {
                                    wishlistId = item['id'];
                                    break;
                                  }
                                }

                                if (wishlistId != null) {
                                  await removeFromWishlist(wishlistId);
                                } else {
                                  print(
                                      'Wishlist ID not found for the product.');
                                }
                              }
                            },
                            child: Icon(
                              favoriteProvider.isFavorite(
                                      offeredproductsList[index]['id'])
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: const Color(0xffE40404),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}
