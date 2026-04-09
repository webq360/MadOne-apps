// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:omnicare_app/ui/subscreens/account/wishlist_screen.dart';
import 'package:omnicare_app/ui/subscreens/notification_screen.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/ui/widgets/home/search_product_screen.dart';
import 'package:omnicare_app/util/app_constants.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(bool) onNotificationUpdate;

  const CustomAppBar({super.key, required this.onNotificationUpdate});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  String phoneNumber = "";
  bool showNotificationDot = false;
  Map<String, dynamic>? previousResponse;
  bool isNotificationScreenVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchPhoneNumber();
    _checkForNewNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForNewNotifications();
  }

  Future<void> _fetchPhoneNumber() async {
    const apiUrl = AppConstants.settings;

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> siteSettings = data['site_settigs'];
        if (siteSettings.isNotEmpty) {
          final Map<String, dynamic> firstSetting = siteSettings.first;

          // Print details about the structure of the response
          print("First Setting: $firstSetting");

          // Check if 'help_number' is a string
          final dynamic helpNumber = firstSetting['help_number'];
          if (helpNumber is String) {
            // The 'help_number' is directly available
            print("Type of 'help_number': ${helpNumber.runtimeType}");

            // Set the phone number
            setState(() {
              phoneNumber = helpNumber;
            });

            // Print the fetched phone number
            print("Phone number fetched successfully: $phoneNumber");
          } else {
            // Handle case where 'help_number' is not a string
            print("Invalid type for 'help_number': ${helpNumber.runtimeType}");
          }
        } else {
          print("No site settings found in the API response.");
        }
      } else {
        // Handle error
        print("Failed to fetch phone number: ${response.statusCode}");
        print(
            "API Response: ${response.body}"); // Print the API response for error analysis
      }
    } catch (e) {
      // Handle error
      print("Error fetching phone number: $e");
    }
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final response = await http.get(
          Uri.parse(AppConstants.settings));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> siteSettings = data['site_settigs'];

        if (siteSettings.isNotEmpty) {
          final Map<String, dynamic> currentSetting = siteSettings.first;
          final List<String> currentNotificationTexts = List.generate(
              5,
              (index) =>
                  currentSetting['notification_text_${index + 1}'] ?? '');

          if (_hasNewNotifications(currentNotificationTexts)) {
            setState(() {
              showNotificationDot =
                  true; // Set showNotificationDot to true if there are new notifications
            });
            if (widget.onNotificationUpdate != null) {
              widget.onNotificationUpdate(
                  true); // Notify the parent widget of the new notifications
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching or decoding settings: $e");
    }
  }

  bool _hasNewNotifications(List<String> currentNotificationTexts) {
    // Implement your logic to determine if there are new notifications
    // For example, compare currentNotificationTexts with the previous notifications
    // If there are differences, return true; otherwise, return false
    // You can compare it with the previous state if you have stored it
    // For simplicity, let's assume all notifications are new for now
    return currentNotificationTexts
        .any((notification) => notification.isNotEmpty);
  }

  void handleNotificationUpdate(bool hasUpdate) {
    setState(() {
      showNotificationDot = hasUpdate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          SizedBox(width: 8.w),
          // Logo
          Image.asset(
            ImageAssets.landscapeLogo,
            width: 90.w,
            height: 36.h,
          ),
          SizedBox(width: 8.w),
          // Search bar
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => const SearchedProductScreen()),
              child: Container(
                height: 34.h,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: Colors.grey),
                    SizedBox(width: 4.w),
                    const Text(
                      'Search Product',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Call
          InkWell(
            onTap: () {},
            child: SvgPicture.asset(
              ImageAssets.callIconSVG,
              height: 20.h,
              width: 20.w,
            ),
          ),
          SizedBox(width: 10.w),
          // Notification
          Stack(
            children: [
              InkWell(
                onTap: () {
                  setState(() => isNotificationScreenVisible = true);
                  Get.to(() => NotificationScreen(
                        onNotificationUpdate: handleNotificationUpdate,
                      ))?.then((_) {
                    setState(() {
                      isNotificationScreenVisible = false;
                      _checkForNewNotifications();
                    });
                  });
                },
                child: SvgPicture.asset(
                  ImageAssets.notificationIconSVG,
                  height: 20.h,
                  width: 20.w,
                ),
              ),
              if (showNotificationDot && !isNotificationScreenVisible)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 10.w),
          // Wishlist
          InkWell(
            onTap: () => Get.to(() => const WishlistScreen()),
            child: const Icon(Icons.favorite, color: Colors.white, size: 22),
          ),
          SizedBox(width: 8.w),
        ],
      ),
    );
  }
}
