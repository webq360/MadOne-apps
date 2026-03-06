import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/Auth/login_screen.dart';
import 'package:omnicare_app/Model/account_model.dart';
import 'package:omnicare_app/const/bottom_navbar.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/ui/screens/orderlist_screen.dart';
import 'package:omnicare_app/ui/subscreens/account/edit_profile_screen.dart';
import 'package:omnicare_app/ui/subscreens/account/wishlist_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}
class _AccountScreenState extends State<AccountScreen> {
  bool isLoading = false;
  File? _image; // Variable to store the selected image
  String storeName = '';
  String ownerName = '';
  String emailAddress = '';
  String storeAddress = '';
  String storeImageUrl = '';

  // Method to fetch store name from the API and handle token refresh
  Future<void> fetchStoreName() async {
    try {
      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        // Handle the case where the authorization token is not available
        print('Authorization token is missing.');
        return;
      }
      final response = await http.get(
        Uri.parse('https://app.omnicare.com.bd/api/profile'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      print('Fetch Store Name status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> fetchedData = json.decode(response.body);
        print('Fetched Data: $fetchedData');
        final Map<String, dynamic>? user = fetchedData['user'];
        final Map<String, dynamic>? pharmacy = fetchedData['pharmacy'];
        if (user != null && pharmacy != null) {
          setState(() {
            storeName = user['name'] ?? '';
            ownerName = pharmacy['owner_name'] ?? '';
            emailAddress = user['email'] ?? '';
            storeAddress = pharmacy['store_address'] ?? '';
            storeImageUrl = pharmacy['store_image'] ?? '';
          });
        } else {
          // Handle the case where 'user' or 'pharmacy' is null
          print('Error: Invalid response structure');
        }
      } else if (response.statusCode == 401) {
        // Token expired, attempt token refresh
        await _handleTokenRefresh(fetchStoreName);
      } else {
        // Handle API error
        print('Failed to fetch store name. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle network errors or unexpected situations
      print('Error during store name fetch: $error');
    }

  }
  // Function to handle token refresh
  Future<void> _handleTokenRefresh(Function onRefreshComplete) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? refreshToken = prefs.getString('refreshToken');
    if (refreshToken != null) {
      final String? newAccessToken = await _refreshToken(refreshToken);
      if (newAccessToken != null) {
        // Save the new access token
        prefs.setString('accessToken', newAccessToken);
        // Retry the original function after token refresh
        await onRefreshComplete();
      } else {
        // If refresh token is not available or refresh fails, show an error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  // Function to get the current access token
  Future<String?> _getAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }
  // Function to refresh the access token
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
  // Add a method to handle user logout
  Future<void> _logout() async {
    try {
      final String? authToken = await _getAccessToken();
      if (authToken == null) {
        print('Authorization token is missing.');
        return;
      }

      final response = await http.get(
        Uri.parse('https://app.omnicare.com.bd/api/logout'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        // Clear user data and navigate to login screen
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('accessToken');
        await prefs.remove('refreshToken');
        Get.offAll(const LoginScreen()); // Replace LoginScreen with your login screen widget
      } else {
        print('Failed to logout. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error during logout: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStoreName();
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to the bottom navigation bar screen when the back button is pressed
        Get.offAll(BottomNavBarScreen());
        // Return false to prevent the default back button behavior
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ColorPalette.primaryColor,
          leading: IconButton(onPressed: (){
            Get.offAll(const BottomNavBarScreen());
          }, icon: const Icon(Icons.arrow_back,color: Colors.white,)),
          title: const Text('Profile', style: TextStyle(color: Colors.white),),centerTitle: true,),
        body: RefreshIndicator(
          onRefresh: () async {
            await fetchStoreName();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
              child:  Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffB7D4FF),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30.r,
                      backgroundImage: storeImageUrl.isNotEmpty
                          ? NetworkImage(storeImageUrl) // Load store image from URL
                          : null, // If no image URL available, don't display any image
                      child: storeImageUrl.isEmpty && _image == null
                          ? const Icon(Icons.image, size: 40, color: Colors.white) // Show image icon only if no image URL and no selected image
                          : null, // Otherwise, don't display anything inside CircleAvatar
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    Text(
                      '$storeName',
                      style: fontStyle(14.sp, Colors.black, FontWeight.w600),
                    ),
                    Text(
                      '$ownerName',
                      style: fontStyle(12.sp, Colors.black),
                    ),
                    Text(
                      'Email: $emailAddress',
                      style: fontStyle(12.sp, Colors.green),
                    ),
                    Text(
                      'Shipping Address: $storeAddress',
                      style: fontStyle(12.sp, Colors.grey),
                    ),
                  ],),

                  SizedBox(height: 20.h),
                  for (var index = 0; index < myAccount.length; index++)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: InkWell(
                        onTap: () {
                          switch (index) {
                            case 0:
                              Get.to(const EditProfileScreen());
                              break;
                            case 1:
                              Get.to(const WishlistScreen());
                              break;
                            default:
                              Get.to(const OrderListScreen());
                          }
                        },
                        child: SizedBox(
                          height: 20.h,
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                '${myAccount[index].img1}',height: 15,width: 15,
                              ),
                              SizedBox(width: 15.w),
                              Text("${myAccount[index].title}",
                                  style: fontStyle(
                                      15.sp, Colors.black, FontWeight.w400)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: InkWell(
                      onTap: () {
                        _logout();
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset(ImageAssets.logoutIconSVG,height: 15,width: 15,),
                          SizedBox(width: 15.w),
                          Text(
                            "Log Out",
                            style: fontStyle(
                                15.sp, const Color(0xffE40404), FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
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
