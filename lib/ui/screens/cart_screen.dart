// ignore_for_file: no_leading_underscores_for_local_identifiers, deprecated_member_use, prefer_const_constructors, avoid_print, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:omnicare_app/const/bottom_navbar.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/subscreens/payment_method_screen.dart';
import 'package:omnicare_app/ui/subscreens/product_details_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    var cartProvider = Provider.of<CartProvider>(context);
    List<CartItem> cartItems = cartProvider.cartItems;
    bool isCartEmpty = cartItems.isEmpty;
    double totalSellPrice = cartProvider.getTotalSellPrice();
    //double totalAfterDiscountPrice = cartProvider.getTotalAfterDiscountPrice();

    void _navigateToProductDetails(CartItem cartItem) {
      print(cartItem.toMap());
      Get.to(()=>ProductDetailsScreen(productDetails: cartItem.toMap()));
    }

    return WillPopScope(
      onWillPop: () async {
        // Navigate to the bottom navigation bar screen when the back button is pressed
        Get.offAll(() => BottomNavBarScreen());
        // Return false to prevent the default back button behavior
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ColorPalette.primaryColor,
          leading: IconButton(
              onPressed: () {
                Get.offAll(() => const BottomNavBarScreen());
              },
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          title: Text(
            'Cart',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(
                      height: 20.h,
                    ),
                    // Display default image if cart is empty
                    if (isCartEmpty)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            ImageAssets.emptyCartPNG,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(
                            height: 20.h,
                          ),
                          MaterialButton(
                            padding: EdgeInsets.symmetric(
                                vertical: 16.h, horizontal: 30.w),
                            //minWidth: double.infinity,
                            color: ColorPalette.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            onPressed: () {
                              Get.offAll(
                                () => BottomNavBarScreen(),
                              );
                            },
                            child: Text(
                              "Continue Shopping",
                              style: fontStyle(
                                  14.sp, Colors.white, FontWeight.w400),
                            ),
                          ),
                        ],
                      )
                    else
                      // Display selected products
                      for (var cartItem in cartItems)
                        CartItemWidget(
                          cartItem: cartItem,
                          onQuantityChanged: (newQuantity) {
                            // Update the quantity in the cart
                            cartProvider.updateCartItemQuantity(
                                cartItem, newQuantity);
                            // Notify listeners or update the state management logic
                            cartProvider.notifyListeners();
                          },
                          onProductImageTapped: () {
                            // Navigate to ProductDetailsScreen with the specific product details
                            _navigateToProductDetails(cartItem);
                          },
                        ),
                    SizedBox(height: 65.h),
                    if (!isCartEmpty)
                      Column(
                        children: [
                          Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "All Product Price:",
                                      style: fontStyle(
                                          12.sp,
                                          const Color(0xff959090),
                                          FontWeight.w400),
                                    ),
                                    Text(
                                      "৳ $totalSellPrice",
                                      style: fontStyle(
                                        12.sp,
                                        Colors.black,
                                        FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "After Discount:",
                                      style: fontStyle(
                                        12.sp,
                                        const Color(0xff959090),
                                        FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      // "৳ $totalAfterDiscountPrice",
                                      "৳ ${cartProvider.getTotalAfterDiscountPrice()}",
                                      style: fontStyle(
                                        12.sp,
                                        Colors.green,
                                        FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Total:",
                                      style: fontStyle(
                                          12.sp,
                                          ColorPalette.primaryColor,
                                          FontWeight.w400),
                                    ),
                                    Text(
                                      // "৳ $totalAfterDiscountPrice",
                                      "৳ ${cartProvider.getTotalAfterDiscountPrice()}",
                                      style: fontStyle(
                                          12.sp,
                                          ColorPalette.primaryColor,
                                          FontWeight.w500),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 25.h,
                                ),
                                // ----------------------------------------- Button --------------------------------------------
                                MaterialButton(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  minWidth: double.infinity,
                                  color: ColorPalette.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  onPressed: () {
                                    // Pass cart items and total price to the PaymentMethodScreen
                                    Get.to(
                                      () => PaymentMethodScreen(),
                                    );
                                  },
                                  child: Text(
                                    "Buy Now",
                                    style: fontStyle(
                                        14.sp, Colors.white, FontWeight.w400),
                                  ),
                                ),

                                SizedBox(
                                  height: 10.h,
                                ),
                              ],
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
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;
  final Function(int) onQuantityChanged;
  final VoidCallback onProductImageTapped;

  const CartItemWidget({
    Key? key,
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onProductImageTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var cartProvider = Provider.of<CartProvider>(context);
    double totalAfterDiscountPrice = cartProvider.getTotalAfterDiscountPrice();
    return InkWell(
      onTap: onProductImageTapped,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.h),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff8AB9FF)),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Container(
              height: 95.h,
              width: MediaQuery.of(context).size.width * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xff8AB9FF),
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5.r),
                child: Image.network(
                  cartItem.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
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
                  '${cartItem.name.split(' ').take(3).join(' ')} - ${cartItem.company_name.split(' ').first}',
                  style: fontStyle(11.sp, Colors.black, FontWeight.w500),
                ),

                // Text(
                //   cartItem.name.split(' ').take(3).join(' '),
                //   style: fontStyle(11.sp, Colors.black, FontWeight.w500),
                // ),
                SizedBox(height: 5.h),
                Text(
                  '৳ ${cartItem.sell_price}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.red,
                    decorationThickness: 3,
                  ),
                ),
                Text(
                  '৳ ${cartItem.after_discount_price}  (${cartItem.after_discount_price.toStringAsFixed(2)} x ${cartItem.quantity})',
                  style: fontStyle(11.sp, Colors.green, FontWeight.w500),
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        int newQuantity = cartItem.quantity - 1;
                        if (newQuantity > 0) {
                          onQuantityChanged(newQuantity);
                        } else {
                          // If the new quantity is 0 or less, remove the item from the cart
                          cartProvider.removeFromCart(cartItem);
                          cartProvider.notifyListeners();
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: ColorPalette.primaryColor,
                        ),
                        child: Icon(
                          Icons.remove,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        '${cartItem.quantity}',
                        style: fontStyle(18, Colors.black, FontWeight.w400),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        onQuantityChanged(cartItem.quantity + 1);
                      },
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: ColorPalette.primaryColor,
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10.w,
                    ),
                    InkWell(
                      onTap: () {
                        cartProvider.removeFromCart(cartItem);
                        cartProvider.notifyListeners();
                      },
                      child: Icon(Icons.delete, color: Colors.red, size: 30),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(width: 16.w),
          ],
        ),
      ),
    );
  }
}
