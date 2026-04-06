// ignore_for_file: avoid_print, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, unused_element

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/Auth/login_screen.dart';
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:omnicare_app/services/button_provider.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/network_checker_screen/network_checker_screen.dart';
import 'package:omnicare_app/ui/screens/cart_screen.dart';
import 'package:omnicare_app/ui/screens/company_screen.dart';
import 'package:omnicare_app/ui/screens/shimmer_widget.dart';
import 'package:omnicare_app/ui/subscreens/product_details_screen.dart';
import 'package:omnicare_app/ui/widgets/home/search_barnd_wise_product.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyProductsScreen extends StatefulWidget {
  final int companyId;
  final String companyName;
  const CompanyProductsScreen({
    Key? key,
    required this.companyId,
    required this.companyName,
  }) : super(key: key);
  @override
  State<CompanyProductsScreen> createState() => _CompanyProductsScreenState();
}

class _CompanyProductsScreenState extends State<CompanyProductsScreen> {
  List<Map<String, dynamic>> companyproductList = [];
  bool isLoading = false;
  List<bool> isFavouriteList = [];
  //TextEditingController searchController = TextEditingController();
  //List<Map<String, dynamic>> searchResults = [];
  List<CartItem> cartItems = [];
  bool showQuantityButtons = false;
  int quantity = 0;
  // Map to store quantity for each product
  Map<int, int> productQuantities = {};
  List<Map<String, dynamic>> _wishlistItems = [];
  @override
  void initState() {
    super.initState();
    print(
        'Initiating CompanyProductsScreen for Company ID: ${widget.companyId}');
    //fetchCompanyData(); // Update the method name
    fetchData();
    fetchWishlist();
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
      });
      final response = await http.get(Uri.parse(
          'https://app.medonetrade.com/api/brand_wise_product/${widget.companyId}'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> products = responseData['products'];
        print('Company products data: $products');
        setState(() {
          companyproductList = List<Map<String, dynamic>>.from(products);
        });
      } else {
        print(
            'Failed to load company products data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching company products data: $error');
    } finally {
      setState(() {
        isLoading = false;
        Provider.of<CartProvider>(context, listen: false).notifyListeners();
      });
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

  Future<void> toggleFavorite(int productId) async {
    final provider = Provider.of<FavoriteProvider>(context, listen: false);
    final isFavorite = provider.isFavorite(productId);

    if (isFavorite) {
      //  provider.removeFavorite(productId);
    } else {
      // provider.addFavorite(productId);
      await addToWishlist(productId);
    }

    setState(
        () {}); // Ensure the UI is updated to reflect the change in favorite status
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
        setState(() {
          _wishlistItems =
              List<Map<String, dynamic>>.from(responseData['data']);
        });
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
      }
      // else {
      //   print('Failed to remove product from wishlist. Status code: ${response.statusCode}');
      //   // Display a message to the user
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Failed to remove product from wishlist. Please try again later.'),
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
    for (int i = 0; i < companyproductList.length; i++) {
      var productId = companyproductList[i]['id'] as int;
      if (wishlistProductIds.contains(productId)) {
        // If the product ID exists in the wishlist, set the corresponding index in isFavouriteList to true
        isFavouriteList[i] = true;
      } else {
        // Otherwise, set it to false
        isFavouriteList[i] = false;
      }
    }
  }

  void addToCart(int index) {
    var cartProvider = Provider.of<CartProvider>(context, listen: false);
    var existingItem = cartItems.firstWhere(
      (item) => item.name == companyproductList[index]['name'],
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
      var productId = companyproductList[index]['id'] as int;
      var item = CartItem(
        id: productId,
        image: companyproductList[index]['image'] ?? 'default_image_path',
        name: companyproductList[index]['name'] ?? 'Unknown Product',
        sell_price: double.parse(
            '${companyproductList[index]['sell_price'].replaceAll(',', '')}'),
        after_discount_price: double.parse(
            '${companyproductList[index]['after_discount_price'].replaceAll(',', '')}'),
        subtitle: 'Unknown Subtitle',
        company_name: companyproductList[index]['brand']['brand_name'] ??
            'Unknown Company',
        quantity: 1,
        addedFromProductDetails: true,
      );
      cartProvider.addToCart(item);
      cartProvider.updateQuantity(productId, 1);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Container(
      //       height: 30.h,
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         children: [
      //           const Text('Added to cart'),
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
      context.read<QuantityButtonsProvider>().setShowQuantityButtons(false);
    }
  }

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

  // void searchProduct(String query) async {
  //   try {
  //     setState(() {
  //       isLoading = true;
  //     });
  //     final response = await http.post(
  //       Uri.parse('https://app.medonetrade.com/api/search_product?query=$query'),
  //     );
  //     if (response.statusCode == 200) {
  //       final json = jsonDecode(response.body);
  //       if (json['suggested_products'] != null && json['suggested_products'] is List) {
  //         setState(() {
  //           searchResults = List<Map<String, dynamic>>.from(json['suggested_products']);
  //           isFavouriteList = List.filled(companyproductList.length, false);
  //         });
  //       } else {
  //         print('Invalid search results format.');
  //       }
  //     } else {
  //       print('Failed to load search results. Status code: ${response.statusCode}');
  //     }
  //   } catch (error) {
  //     print('Error during product search: $error');
  //   }
  //   finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  // void runFilter(String enteredKeyword) {
  //   if (enteredKeyword.isEmpty) {
  //     setState(() {
  //       searchResults.clear();
  //     });
  //   } else {
  //     setState(() {
  //       searchResults = companyproductList.where((product) =>
  //           product['name']
  //               .toString()
  //               .toLowerCase()
  //               .contains(enteredKeyword.toLowerCase())).toList();
  //     });
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    cartItems = Provider.of<CartProvider>(context).cartItems;
    return ChangeNotifierProvider(
      create: (context) {
        return QuantityButtonsProvider();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: ColorPalette.primaryColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Get.offAll(() => const CompanyScreen());
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(widget.companyName,
              style: const TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                Get.offAll(() => const CartScreen());
              },
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
          ],
        ),
        body: isLoading
            ? const ShimmerWidget()
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    toolbarHeight: 50,
                    automaticallyImplyLeading: false,
                    pinned: true,
                    backgroundColor: ColorPalette.primaryColor,
                    elevation: 0,
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        height: 55.h,
                        // width: 130,
                        child: TextButton(
                          onPressed: () {
                            Get.to(
                              () => SearchedBrandWiseProductScreen(
                                brandId: widget.companyId.toString(),
                                brandName: widget.companyName,
                              ),
                            );
                          },
                          child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              height: 100,
                              // width: 370,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: Row(
                                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(
                                    Icons.search,
                                    size: 17,
                                  ),
                                  SizedBox(
                                    width: 6.w,
                                  ),
                                  const Text(
                                    "Search Product",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              )),
                        ),
                      ),
                    ),
                  ),
                  // searchResults.isNotEmpty || searchController.text.isNotEmpty
                  //     ? SliverPadding(
                  //   padding:
                  //   EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
                  //   sliver: SliverGrid(
                  //     // Use searchResults instead of companyproductList
                  //     gridDelegate:
                  //     const SliverGridDelegateWithFixedCrossAxisCount(
                  //       crossAxisCount: 2,
                  //       crossAxisSpacing: 15,
                  //       childAspectRatio: 0.68,
                  //       mainAxisSpacing: 20,
                  //     ),
                  //     delegate: SliverChildBuilderDelegate(
                  //           (context, index) {
                  //         final suggestedProduct = searchResults[index];
                  //         return buildProductCard(suggestedProduct, index);
                  //       },
                  //       childCount: searchResults.length,
                  //     ),
                  //   ),
                  // )
                  //     :
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.60,
                        mainAxisSpacing: 20,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return buildProductCard(
                            companyproductList[index],
                            index,
                          );
                        },
                        childCount: companyproductList.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildProductCard(Map<String, dynamic> product, int index) {
    var cartProvider = Provider.of<CartProvider>(context, listen: false);
    final favoriteProvider = Provider.of<FavoriteProvider>(
        context); // Retrieve FavoriteProvider instance
    final productId = product['id'] as int; // Retrieve product ID
    return Stack(
      children: [
        InkWell(
          onTap: () {
            Get.to(ProductDetailsScreen(productDetails: product));
          },
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.r),
              color: ColorPalette.cardColor,
              border: Border.all(color: ColorPalette.primaryColor),
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
                    product['image'],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${companyproductList[index]['name']} - ${companyproductList[index]['brand']['brand_name'].split(' ').first}',
                        style: fontStyle(12, Colors.black, FontWeight.w500),
                      ),
                      Text(
                        '৳${companyproductList[index]['after_discount_price']}',
                        style: fontStyle(12.sp, Colors.black, FontWeight.w600),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '৳${companyproductList[index]['sell_price']}',
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
                                '৳${double.parse(companyproductList[index]['discount']).toStringAsFixed(2)}',
                                style: fontStyle(
                                    12.sp, Colors.green, FontWeight.w600),
                              ),
                              if (companyproductList[index]['discount_type']
                                      ?.toLowerCase() ==
                                  'percent')
                                Text(
                                  '% Off',
                                  style: fontStyle(
                                      12.sp, Colors.green, FontWeight.w600),
                                ),
                              if (companyproductList[index]['discount_type']
                                      ?.toLowerCase() !=
                                  'percent')
                                Text(
                                  ' ${companyproductList[index]['discount_type']} Off',
                                  style: fontStyle(
                                      11.sp, Colors.green, FontWeight.w600),
                                ),
                            ],
                          ),
                        ],
                      ),
                      int.parse(cartProvider
                                  .getProductQuantityById(
                                      companyproductList[index]['id'])
                                  .toString()) ==
                              0
                          ? InkWell(
                              onTap: () {
                                setState(() {
                                  productQuantities[companyproductList[index]
                                      ['id']] = (productQuantities[
                                              companyproductList[index]
                                                  ['id']] ??
                                          0) +
                                      1;
                                  showQuantityButtons = true;
                                });
                                SchedulerBinding.instance
                                    .addPostFrameCallback((_) {
                                  addToCart(
                                      index); // Pass index of allproductsList
                                });
                              },
                              child: Container(
                                height: 28.h,
                                width: 80.w,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorPalette.primaryColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ADD',
                                        style: fontStyle(
                                          12.sp,
                                          Colors.white,
                                          FontWeight.w400,
                                        ),
                                      ),
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
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      var quantity =
                                          cartProvider.getProductQuantityById(
                                        companyproductList[index]['id'],
                                      );
                                      quantity--;

                                      cartProvider.updateQuantityById(
                                        companyproductList[index]['id'],
                                        quantity,
                                      );
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      color: ColorPalette.primaryColor,
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    '${int.parse(cartProvider.getProductQuantityById(companyproductList[index]['id']).toString())}',
                                    style: fontStyle(
                                      18,
                                      Colors.black,
                                      FontWeight.w400,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      var quantity =
                                          cartProvider.getProductQuantityById(
                                        companyproductList[index]['id'],
                                      );
                                      quantity++;

                                      cartProvider.updateQuantityById(
                                        companyproductList[index]['id'],
                                        quantity,
                                      );
                                    });
                                    // Notify the CartProvider
                                    Provider.of<CartProvider>(context,
                                            listen: false)
                                        .notifyListeners();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 10.h,
          right: 10.w,
          child: GestureDetector(
            // Wrap with GestureDetector to handle tap events
            onTap: () async {
              // Toggle the favorite status in the provider
              favoriteProvider.toggleFavorite(productId);

              // Perform the appropriate action based on the updated status
              if (favoriteProvider.isFavorite(productId)) {
                // If the product is now in the wishlist, add it
                await addToWishlist(productId);
              } else {
                // If the product is removed from the wishlist, remove it
                await removeFromWishlist(productId);
              }
            },
            child: Icon(
              // Use isFavorite method to determine the initial state of the favorite icon
              favoriteProvider.isFavorite(productId)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: const Color(0xffE40404),
            ),
          ),
        ),
      ],
    );
  }
}
