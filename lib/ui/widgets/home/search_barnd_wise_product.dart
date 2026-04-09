// ignore_for_file: use_build_context_synchronously, avoid_print, unused_element, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, prefer_const_constructors, sized_box_for_whitespace

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
import 'package:omnicare_app/ui/screens/cart_screen.dart';
import 'package:omnicare_app/ui/subscreens/product_details_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omnicare_app/util/app_constants.dart';

class SearchedBrandWiseProductScreen extends StatefulWidget {
  final String brandId;
  final String brandName;
  const SearchedBrandWiseProductScreen({
    super.key,
    required this.brandId,
    required this.brandName,
  });

  @override
  State<SearchedBrandWiseProductScreen> createState() =>
      _SearchedBrandWiseProductScreenState();
}

class _SearchedBrandWiseProductScreenState
    extends State<SearchedBrandWiseProductScreen> {
  List<bool> isFavouriteList = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<CartItem> cartItems = [];
  List<Map<String, dynamic>> allproductsList = [];
  bool showQuantityButtons = false;
  int quantity = 0;
  // Map to store quantity for each product
  Map<int, dynamic> productQuantities = {};
  List<Map<String, dynamic>> _wishlistItems = [];

  @override
  void initState() {
    super.initState();
    fetchWishlist();
    allProducts();
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
        Uri.parse(AppConstants.wishlist),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Iterate through the wishlist items and add a timestamp for each item
        setState(() {
          _wishlistItems =
              List<Map<String, dynamic>>.from(responseData['data']).map((item) {
            return {...item, 'timestamp': DateTime.now()};
          }).toList();
        });
        // Sort the wishlist items based on the timestamp, with the latest added item appearing first
        _wishlistItems.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
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

  void allProducts() async {
    try {
      setState(() {
        isLoading = true;
      });
      final response = await http.get(Uri.parse(
          AppConstants.brandWiseProduct(widget.brandId)));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> products = responseData['products'];
        print('Company products data: $products');
        setState(() {
          allproductsList = List<Map<String, dynamic>>.from(products);
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
    // try {
    //   setState(() {
    //     isLoading = true;
    //   });
    //   final response =
    //       await http.get(Uri.parse('https://app.medonetrade.com/api/'));
    //   if (response.statusCode == 200) {
    //     final json = jsonDecode(response.body);
    //     if (json['all_products'] is List) {
    //       setState(() {
    //         allproductsList =
    //             List<Map<String, dynamic>>.from(json['all_products']);
    //       });
    //       print(allproductsList);
    //     } else {
    //       print('Invalid data format for featured products.');
    //     }
    //   } else {
    //     print(
    //         'Failed to load company names. Status code: ${response.statusCode}');
    //   }
    // } catch (error) {
    //   print('Error: $error');
    // } finally {
    //   setState(() {
    //     isLoading = false;
    //   });
    // Provider.of<CartProvider>(context, listen: false).notifyListeners();
  }

  Future<void> addToWishlist(int productId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('accessToken');
    if (accessToken != null) {
      try {
        final response = await http.get(
          Uri.parse(AppConstants.addToWishlist(productId)),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        if (response.statusCode == 200) {
          // Product added to wishlist successfully
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added to wishlist'),
            ),
          );
        } else {
          // Failed to add product to wishlist
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add product to wishlist'),
            ),
          );
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
      final Uri url = Uri.parse(AppConstants.removeFromWishlist(wishlistId));
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
    for (int i = 0; i < searchResults.length; i++) {
      var productId = searchResults[i]['id'] as int;
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
        AppConstants.refresh;
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

  void addToCart(int index, List itemList) {
    var cartProvider = Provider.of<CartProvider>(context, listen: false);
    var existingItem = cartItems.firstWhere(
      (item) => item.name == itemList[index]['name'],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            height: 30.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item is already in the cart'),
                TextButton(
                  onPressed: () {
                    Get.to(() => const CartScreen());
                  },
                  child: Text('View', style: TextStyle(color: Colors.yellow)),
                )
              ],
            ),
          ),
        ),
      );
      context.read<QuantityButtonsProvider>().setShowQuantityButtons(true);
    } else {
      var productId = itemList[index]['id'] as int;
      var item = CartItem(
        id: productId,
        image: itemList[index]['image'] ?? 'default_image_path',
        name: itemList[index]['name'] ?? 'Unknown Product',
        sell_price: double.parse(
            '${itemList[index]['sell_price'].replaceAll(',', '')}'),
        after_discount_price: double.parse(
            '${itemList[index]['after_discount_price'].replaceAll(',', '')}'),
        company_name:
            itemList[index]['brand']['brand_name'] ?? 'Unknown Company',
        subtitle: 'Unknown',
        quantity: 1,
        addedFromProductDetails: true,
      );
      cartProvider.addToCart(item);
      cartProvider.updateQuantity(productId, 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            height: 30.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Added to cart'),
                TextButton(
                  onPressed: () {
                    Get.to(() => const CartScreen());
                  },
                  child: const Text(
                    'View',
                    style: TextStyle(color: Colors.yellow),
                  ),
                )
              ],
            ),
          ),
        ),
      );
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

  void searchProduct(String query) async {
    try {
      setState(() {
        isLoading = true;
      });

      ///https://app.medonetrade.com/api//brand_wise_product/9 //check post api or get api
      final response = await http.post(
        Uri.parse(AppConstants.searchBrandProduct(widget.brandId)),
        body: {'query': query},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['products'] != null && json['products'] is List) {
          setState(() {
            searchResults = List<Map<String, dynamic>>.from(json['products']);
            isFavouriteList = List.filled(allproductsList.length, false);
          });
        } else {
          print('Invalid search results format.');
        }
      } else {
        print(
            'Failed to load search results. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error during product search: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    cartItems = Provider.of<CartProvider>(context).cartItems;
    return ChangeNotifierProvider(
      create: (context) {
        return QuantityButtonsProvider();
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              toolbarHeight: 65,
              automaticallyImplyLeading: false,
              pinned: true,
              backgroundColor: ColorPalette.primaryColor,
              elevation: 0,
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(bottom: 5),
                title: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            controller: searchController,
                            onChanged: (query) {
                              searchProduct(query);
                            },
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 9,
                                horizontal: 9.w,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Search ${widget.brandName} Product ',
                              suffixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// Conditionally build either search results or featured products
            searchResults.isNotEmpty
                ? SliverPadding(
                    padding:
                        EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.60,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final suggestedProduct = searchResults[index];
                          return buildProductCard(
                              suggestedProduct, index, searchResults);
                        },
                        childCount: searchResults.length,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.symmetric(
                      vertical: 20.h,
                      horizontal: 15.w,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.60,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return buildProductCard(
                            allproductsList[index],
                            index,
                            allproductsList,
                          );
                        },
                        childCount: allproductsList.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget buildProductCard(
      Map<String, dynamic> product, int index, List itemList) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return Stack(
      children: [
        InkWell(
          onTap: () {
            Get.to(() => ProductDetailsScreen(productDetails: product));
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
                  child: InkWell(
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
                ),
                SizedBox(height: 8.h),
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ///product & brand name
                      Text(
                        '${product['name']} - ${product['brand']['brand_name'].split(' ').first}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: fontStyle(12, Colors.black, FontWeight.w500),
                      ),

                      ///discount price
                      Text(
                        '৳${product['after_discount_price']}',
                        style: fontStyle(12.sp, Colors.black, FontWeight.w600),
                      ),

                      ///sell price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '৳${product['sell_price']}',
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
                                '৳${double.tryParse('${product['discount']}'.replaceAll(',', ''))?.toStringAsFixed(2) ?? '0.00'}',
                                style: fontStyle(
                                    12.sp, Colors.green, FontWeight.w600),
                              ),
                              if (product['discount_type']?.toLowerCase() ==
                                  'percent')
                                Text(
                                  '% Off',
                                  style: fontStyle(
                                      12.sp, Colors.green, FontWeight.w600),
                                ),
                              if (product['discount_type']?.toLowerCase() !=
                                  'percent')
                                Text(
                                  ' ${product['discount_type']} Off',
                                  style: fontStyle(
                                      11.sp, Colors.green, FontWeight.w600),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Check if the index is within range before accessing searchResults

                      int.parse(cartProvider
                                  .getProductQuantityById(itemList[index]['id'])
                                  .toString()) ==
                              0
                          ? InkWell(
                              onTap: () {
                                setState(() {
                                  productQuantities[itemList[index]['id']] =
                                      (productQuantities[itemList[index]
                                                  ['id']] ??
                                              0) +
                                          1;
                                  showQuantityButtons = true;
                                });
                                SchedulerBinding.instance
                                    .addPostFrameCallback((_) {
                                  addToCart(
                                    index,
                                    itemList,
                                  ); // Pass index of allproductsList
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
                                        style: fontStyle(12.sp, Colors.white,
                                            FontWeight.w400),
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
                                        itemList[index]['id'],
                                      );
                                      quantity--;

                                      cartProvider.updateQuantityById(
                                        itemList[index]['id'],
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

                                ///cart quantity
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    '${int.parse(cartProvider.getProductQuantityById(itemList[index]['id']).toString())}',
                                    style: fontStyle(
                                      18,
                                      const Color.fromARGB(255, 184, 11, 11),
                                      FontWeight.w400,
                                    ),
                                  ),
                                ),

                                ///inecrement cart quantity
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      var quantity =
                                          cartProvider.getProductQuantityById(
                                        itemList[index]['id'],
                                      );
                                      quantity++;

                                      cartProvider.updateQuantityById(
                                        itemList[index]['id'],
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
            onTap: () async {
              favoriteProvider.toggleFavorite(product['id']);
              if (favoriteProvider.isFavorite(product['id'])) {
                await addToWishlist(product['id']);
              } else {
                int? wishlistId;

                print('_wishlistItems: $_wishlistItems');

                for (var item in _wishlistItems) {
                  String productId = item['product_id'];
                  int wishlistProductId = int.tryParse(productId) ?? -1;

                  print(
                      'productId: $productId, wishlistProductId: $wishlistProductId');

                  if (wishlistProductId == product['id']) {
                    wishlistId = item['id'];
                    break;
                  }
                }

                print('wishlistId: $wishlistId');

                if (wishlistId != null) {
                  await removeFromWishlist(wishlistId);
                } else {
                  print('Wishlist ID not found for the product.');
                }
              }
            },
            child: Icon(
              favoriteProvider.isFavorite(product['id'])
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
