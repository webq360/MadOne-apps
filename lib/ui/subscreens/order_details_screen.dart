// ignore_for_file: use_build_context_synchronously, prefer_const_declarations, unused_element, avoid_print, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/Auth/login_screen.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/ui/network_checker_screen/network_checker_screen.dart';
import 'package:omnicare_app/ui/screens/orderlist_screen.dart';
import 'package:omnicare_app/ui/screens/shimmer_widget.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final String orderStatus;
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.orderStatus,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Map<String, dynamic> orderDetails = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('accessToken');
    if (authToken == null) {
      print('Authorization token is missing.');
      return;
    }
    final int orderId = widget.orderId;
    try {
      setState(() {
        isLoading = true;
      });
      final response = await http.get(
        Uri.parse('https://app.omnicare.com.bd/api/orderDetails/$orderId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        setState(() {
          orderDetails = json.decode(response.body)['data'];
        });
      } else {
        // Handle unsuccessful response
        print(
            'Failed to fetch order details. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network error
      print('Error fetching order details: $error');
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
    final String apiUrl = 'https://app.omnicare.com.bd/api/refresh';
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
      _fetchOrderDetails();
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
            Get.offAll(() => const OrderListScreen());
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchOrderDetails();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: orderDetails != null
              ? _buildOrderDetails()
              : const ShimmerWidget(),
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return SingleChildScrollView(
      child: isLoading
          ? const ShimmerWidget()
          : Column(
              children: [
                ///tracking line
                _buildTimeline(),
                SizedBox(height: 20.h),

                ///order info
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xffB7D4FF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: #OR- ${orderDetails['order']['id']}'),
                          Text(
                              'Order Date: ${orderDetails['order']['order_date']}'),
                          Text(
                              'Payment Status: ${orderDetails['order']['payment_status']}'),
                          Text(
                              'Delivery Date: ${orderDetails['order']['delivery_date'] ?? ""}'),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('৳ ${orderDetails['order']['order_amount']}'),
                          Text(
                            '${orderDetails['order']['order_status'].toUpperCase()}',
                            style: TextStyle(
                              color: _getStatusColor(
                                  orderDetails['order']['order_status']),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                ///order product
                for (var item in orderDetails['order_items'])
                  _buildOrderItem(item),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Shipping charge:",
                      style: fontStyle(12, Colors.black, FontWeight.w400),
                    ),
                    Text(
                      '৳ ${orderDetails['order']['ship_charge']}',
                      style: fontStyle(12, Colors.black, FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total:",
                      style: fontStyle(
                          12, ColorPalette.primaryColor, FontWeight.w500),
                    ),
                    Text(
                      '৳ ${orderDetails['order']['order_amount']}',
                      style: fontStyle(
                          12.sp, ColorPalette.primaryColor, FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    // Ensure that the price and quantity are converted to numbers
    double price = double.parse(item['product']['after_discount_price']
        .replaceAll(RegExp(r'[^0-9.]'), ''));
    int quantity = int.parse(item['demand_quantity']);
// Calculate subtotal
    double subtotal = price * quantity;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      padding: EdgeInsets.symmetric(
        horizontal: 5.w,
        vertical: 10.h,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          ///image
          Container(
            width: MediaQuery.of(context).size.width * 0.20,
            decoration: BoxDecoration(
              color: const Color(0xff8AB9FF),
              // color: Colors.white,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5.r),
              child: InkWell(
                child: Image.network(
                  '${item['product']['image']}',
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
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['product']['name']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text('৳ ${item['product']['after_discount_price']}'),
                  SizedBox(width: 10.w),
                  Text(
                    '৳ ${item['product']['sell_price']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.red,
                      decorationThickness: 3,
                    ),
                  ),
                ],
              ),

              ///product quantity
              Row(
                children: [
                  const Text(
                    'Quantity : ',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  SizedBox(width: 10.w),
                  Text('${item['demand_quantity']}')
                ],
              ),

              ///subtotal price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal : ',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  SizedBox(width: 10.w),
                  // Display the calculated subtotal value
                  Text('৳ $subtotal'),
                ],
              ),
            ],
          ),
        ],
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
        return Colors.black;
    }
  }

  Widget _buildTimeline() {
    // Determine which steps should be active based on order status
    bool pendingActive =
        orderDetails['order']['order_status'].toLowerCase() == 'pending';
    bool confirmActive =
        orderDetails['order']['order_status'].toLowerCase() == 'confirmed';
    bool onTheWayActive =
        orderDetails['order']['order_status'].toLowerCase() == 'on_the_way';
    bool deliveredActive =
        orderDetails['order']['order_status'].toLowerCase() == 'delivered';
    bool denyActive =
        orderDetails['order']['order_status'].toLowerCase() == 'denied';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              _buildCircleIndicator(0,
                  active: pendingActive ||
                      confirmActive ||
                      onTheWayActive ||
                      deliveredActive ||
                      denyActive),
              _buildLine(0,
                  active: confirmActive ||
                      onTheWayActive ||
                      deliveredActive ||
                      denyActive),
              _buildCircleIndicator(1,
                  active: confirmActive ||
                      onTheWayActive ||
                      deliveredActive ||
                      denyActive),
              _buildLine(1,
                  active: onTheWayActive || deliveredActive || denyActive),
              _buildCircleIndicator(2,
                  active: onTheWayActive || deliveredActive || denyActive),
              _buildLine(2, active: deliveredActive),
              _buildCircleIndicator(3, active: deliveredActive),
              // _buildLine(3, active:  denyActive),
              // _buildCircleIndicator(4, active: denyActive),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimelineStep('Pending'),
            _buildTimelineStep('Confirmed'),
            _buildTimelineStep('On the way'),
            _buildTimelineStep('Delivered'),
            //_buildTimelineStep('Deny'),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIndicator(int index, {bool active = false}) {
    Color color = active ? Colors.green : Colors.grey;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLine(int index, {bool active = false}) {
    Color color = active ? Colors.green : Colors.grey;
    return Expanded(
      child: Container(
        height: 3,
        color: color,
      ),
    );
  }

  Widget _buildTimelineStep(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Text(
        title,
        textAlign: TextAlign.end,
      ),
    );
  }
}
