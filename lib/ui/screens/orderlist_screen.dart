// ignore_for_file: avoid_log, unused_element, use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/Auth/login_screen.dart';
import 'package:omnicare_app/Model/order_model.dart';
import 'package:omnicare_app/const/bottom_navbar.dart';
import 'package:omnicare_app/ui/network_checker_screen/network_checker_screen.dart';
import 'package:omnicare_app/ui/screens/shimmer_widget.dart';
import 'package:omnicare_app/ui/subscreens/order_details_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);
  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<OrderModel> orderList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkAndLoggedIn();
  }

  Future<void> _fetchOrderData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        log('Authorization token is missing.');
        return;
      }
      final response = await http.get(
        Uri.parse('https://app.omnicare.com.bd/api/orderlist'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      log('Fetch Order Data status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          orderList.clear();
          orderList = (jsonData['data'] as List)
              .map((orderData) => OrderModel.fromJson(orderData))
              .toList();
          // Sort the orderList based on order ID in descending order
          orderList.sort((a, b) => b.id.compareTo(a.id));
          log('Order List Length: ${orderList.length}');
        });
      } else {
        log('Failed to load order data. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
        throw Exception('Failed to load order data');
      }
    } catch (error) {
      log('Error during orderlist fetch: $error');
    } finally {
      setState(() {
        isLoading = false;
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
    const String apiUrl = 'https://app.omnicare.com.bd/api/refresh';
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
      log('Error during token refresh: $error');
      return null;
    }
  }

  Future<void> _checkNetworkAndLoggedIn() async {
    bool hasNetwork = await checkNetwork();
    bool userLoggedIn = await isLoggedIn();
    if (hasNetwork && userLoggedIn) {
      _fetchOrderData();
    } else {
      Get.to(() => const NetworkCheckScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to the bottom navigation bar screen when the back button is pressed
        Get.offAll(() => const BottomNavBarScreen());
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
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          title: const Text(
            'Order List',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _fetchOrderData();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              child: isLoading
                  ? const ShimmerWidget()
                  : Column(
                      children: [
                        for (var index = 0; index < orderList.length; index++)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  Get.to(
                                    () => OrderDetailsScreen(
                                      orderId: orderList[index].id,
                                      orderStatus: orderList[index].orderStatus,
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 10.h),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 10.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: const Color(0xffB7D4FF),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order ID: #OR-${orderList[index].id}',
                                          ),
                                          Text(
                                            'Order Date: ${orderList[index].orderDate}',
                                          ),
                                          Text(
                                            'Payment Status: ${orderList[index].paymentStatus}',
                                          ),
                                          Text(
                                            'Delivery Date-${orderList[index].deliveryDate}',
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          //Text('৳ ${orderList[index].price}'),
                                          Text(
                                            orderList[index]
                                                .orderStatus
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: _getStatusColor(
                                                orderList[index].orderStatus,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String orderStatus) {
    switch (orderStatus.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'denied':
        return Colors.red;
      case 'delivered':
        return Colors.green;
      case 'on_the_way':
        return Colors.orange;
      case 'pending':
        return Colors.yellow;
      default:
        return Colors.black; // Change to your default color
    }
  }
  // Widget _buildShimmerList() {
  //   return Column(
  //     children: List.generate(
  //       5,
  //           (index) => Shimmer.fromColors(
  //         baseColor: Colors.grey[300]!,
  //         highlightColor: Colors.grey[100]!,
  //         child: Container(
  //           margin: EdgeInsets.symmetric(vertical: 10.h),
  //           padding: EdgeInsets.symmetric(
  //             horizontal: 20.w,
  //             vertical: 10.h,
  //           ),
  //           height: 100.h,
  //           width: 328.w,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(10.r),
  //             color: Colors.white,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
