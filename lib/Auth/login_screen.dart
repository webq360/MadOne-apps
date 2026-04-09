// ignore_for_file: avoid_print, unused_local_variable, unused_element, prefer_const_constructors

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:omnicare_app/const/bottom_navbar.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:omnicare_app/util/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isPasswordVisible = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
        .hasMatch(email);
  }

  /// 🔹 Get Device ID
  Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? "";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "";
    }

    return "";
  }

  Future<void> _registerFcmToken(int userId, String accessToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      final deviceType = Platform.isAndroid ? 'android' : 'ios';
      await http.post(
        Uri.parse(AppConstants.fcmToken),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': fcmToken,
          'device_type': deviceType,
          'user_id': userId,
        }),
      );
      log('✅ FCM token registered for user $userId');
    } catch (e) {
      log('FCM token registration error: $e');
    }
  }

  Future<void> _login() async {
    print('Attempting login...');
    final String email = emailController.text;
    final String password = passwordController.text;

    String deviceId = await getDeviceId();

    log("-----deviceid--$deviceId");

    try {
      final response = await http.post(
        Uri.parse(AppConstants.login),
        body: {'email': email, 'password': password, 'device_id': deviceId},
      );

      log('Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> user =
            responseData['user'] as Map<String, dynamic>? ?? {};
        final Map<String, dynamic> authorization =
            responseData['authorization'] as Map<String, dynamic>? ?? {};
        final String accessToken = authorization['token'] as String? ?? '';
        final String refreshToken =
            authorization['refresh_token'] as String? ?? '';

        final int userId = user['id'] as int? ?? 0;

        final SharedPreferences prefs = await SharedPreferences.getInstance();

        log("accessToken--------$accessToken");
        log("refreshToken--------$refreshToken");

        prefs.setInt('userId', userId);
        prefs.setString('accessToken', accessToken);
        prefs.setString('refreshToken', refreshToken);

        // Register FCM token after successful login
        await _registerFcmToken(userId, accessToken);

        Get.offAll(() => const BottomNavBarScreen());
      } else if (response.statusCode == 401) {
        log("----response.statusCode---${response.statusCode}");
        log("----response.statusCode---$response");
        _showSnackBar('Incorrect email or password. Please try again.');
      } else {
        const errorMessage = 'An error occurred. Please try again later.';
        _showSnackBar(errorMessage);
      }
    } catch (error) {
      log("error--$error");
      const errorMessage = 'An error occurred during login. Please try again.';
      _showSnackBar(errorMessage);
    }
  }

  Future<void> _handleTokenRefresh() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? refreshToken = prefs.getString('refreshToken');

    if (refreshToken != null) {
      final String? newAccessToken = await _refreshToken(refreshToken);

      if (newAccessToken != null) {
        prefs.setString('accessToken', newAccessToken);
        await _login();
      } else {
        const errorMessage = 'Session expired. Please log in again.';
        _showSnackBar(errorMessage);
      }
    }
  }

  Future<String?> _refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.refresh),
        body: {
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> authorization =
            responseData['authorization'];
        final String newAccessToken = authorization['token'];

        return newAccessToken;
      } else {
        return null;
      }
    } catch (error) {
      print('Error during token refresh: $error');
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  ImageAssets.splashLogo,
                  width: 230.w,
                ),
                SizedBox(height: 30.h),
                Text(
                  "Login here",
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xff08377C),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(
                  height: 20.h,
                ),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Enter Email Address",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Color(0xff08377C)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email address';
                    } else if (!_isValidEmail(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null; // Return null if the validation is successful
                  },
                ),
                SizedBox(
                  height: 15.h,
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: "Enter Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Color(0xff08377C)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: 20.h,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _login();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColor,
                  ),
                  child: Text('Login', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
