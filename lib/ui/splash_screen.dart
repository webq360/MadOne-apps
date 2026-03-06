import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/controller/product_controller.dart';
import 'package:omnicare_app/ui/network_checker_screen/network_checker_screen.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final controller = Get.put(ProductController());

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () async {
      Get.off(() => const NetworkCheckScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              ImageAssets.splashLogo,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}
