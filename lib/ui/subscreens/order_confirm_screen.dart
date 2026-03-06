import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/const/bottom_navbar.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key});

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
          leading: IconButton(
            onPressed: () {
              Get.offAll(
                BottomNavBarScreen(),
              );
            },
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            'Order Status',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

          Center(child: Image.asset(ImageAssets.orderConfirmedPNG, scale: 2,)),
            SizedBox(height: 20.h,),
            MaterialButton(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 30.w),
              //minWidth: double.infinity,
              color: ColorPalette.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              onPressed: () {
                Get.offAll(
                  BottomNavBarScreen(),
                );
              },
              child: Text(
                "Continue Shopping",
                style: fontStyle(
                    14.sp, Colors.white, FontWeight.w400),
              ),
            ),
        ],),
      ),
    );
  }
}
