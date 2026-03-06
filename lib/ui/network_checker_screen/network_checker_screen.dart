// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/Auth/login_screen.dart';
import 'package:omnicare_app/const/bottom_navbar.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> checkNetwork() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

Future<bool> isLoggedIn() async {
  // Check if the access token is present in SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? accessToken = prefs.getString('accessToken');
  return accessToken != null && accessToken.isNotEmpty;
}

class NetworkCheckScreen extends StatelessWidget {
  const NetworkCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkNetwork(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == false) {
          return NetworkErrorDialog();
        } else {
          // Check if the user is already logged in
          return FutureBuilder<bool>(
            future: isLoggedIn(),
            builder: (context, loggedInSnapshot) {
              if (loggedInSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(body: CircularProgressIndicator());
              } else if (loggedInSnapshot.hasError || !loggedInSnapshot.data!) {
                // User is not logged in, show the login screen
                return LoginScreen();
              } else {
                // User is logged in, navigate to BottomNavBarScreen
                return BottomNavBarScreen();
              }
            },
          );
        }
      },
    );
  }
}

class NetworkErrorDialog extends StatelessWidget {
  const NetworkErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(ImageAssets.splashLogo, width: 200),
              Text("Something went wrong"),
              Text("Check your connection and try again"),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  bool hasNetwork = await checkNetwork();
                  if (hasNetwork) {
                    // Check if the user is already logged in after network restoration
                    bool userLoggedIn = await isLoggedIn();
                    if (userLoggedIn) {
                      Get.offAll(BottomNavBarScreen());
                    } else {
                      Get.to(() => LoginScreen());
                    }
                  } else {
                    Get.to(() => NetworkErrorDialog());
                  }
                },
                child: Text("TRY AGAIN"),
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
