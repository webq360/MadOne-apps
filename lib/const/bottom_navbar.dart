// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/screens/account_screen.dart';
import 'package:omnicare_app/ui/screens/cart_screen.dart';
import 'package:omnicare_app/ui/screens/company_screen.dart';
import 'package:omnicare_app/ui/screens/home_screen.dart';
import 'package:omnicare_app/ui/screens/orderlist_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:internet_connection_checker/internet_connection_checker.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  List pages = [
    const HomeScreen(),
    const CompanyScreen(),
    const OrderListScreen(),
    const CartScreen(),
    const AccountScreen()
  ];
  int currentIndex = 0;
  int get cartItemCount {
    return Provider.of<CartProvider>(context, listen: false).cartItems.length;
  }

  late StreamSubscription subscription;
  var isDeviceConnected = false;
  bool isAlertSet = false;

  @override
  void initState() {
    getConnectivity(context);
    super.initState();
  }

  // void getConnectivity(BuildContext context) =>
  //     subscription = Connectivity().onConnectivityChanged.listen(
  //       (ConnectivityResult result) async {
  //         isDeviceConnected = await InternetConnectionChecker().hasConnection;
  //         if (!isDeviceConnected && !isAlertSet) {
  //           showDialogBox(context);
  //           setState(() => isAlertSet = true);
  //         } else if (isDeviceConnected && isAlertSet) {
  //           Navigator.pop(context);
  //           setState(() => isAlertSet = false);
  //         }
  //       },
  //     );

  void getConnectivity(BuildContext context) {
    subscription = Connectivity().onConnectivityChanged.listen((results) {
      // results is a List<ConnectivityResult>
      if (results.contains(ConnectivityResult.wifi)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connected to WiFi")),
        );
      } else if (results.contains(ConnectivityResult.mobile)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connected to Mobile Network")),
        );
      } else if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No Internet Connection")),
        );
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        exitDialog(context);
      },
      child: Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xffEBF2FD),
          selectedItemColor: ColorPalette.primaryColor,
          unselectedItemColor: Colors.black,
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: currentIndex == 0
                  ? Image.asset(ImageAssets.homeColorIconPNG, scale: 3)
                  : Image.asset(ImageAssets.homeIconPNG, scale: 3),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: currentIndex == 1
                  ? Image.asset(ImageAssets.categoryColorIconPNG, scale: 3)
                  : Image.asset(ImageAssets.categoryIconPNG, scale: 3),
              label: 'Company',
            ),
            BottomNavigationBarItem(
              icon: currentIndex == 2
                  ? Image.asset(ImageAssets.orderColorIconPNG, scale: 3)
                  : Image.asset(ImageAssets.orderIconPNG, scale: 3),
              label: 'Order',
            ),
            BottomNavigationBarItem(
              icon: badges.Badge(
                position: badges.BadgePosition.topEnd(top: -15, end: -12),
                badgeContent: Text(
                  Provider.of<CartProvider>(context)
                      .getTotalCartItems()
                      .toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                badgeAnimation: const badges.BadgeAnimation.slide(
                  animationDuration: Duration(seconds: 1),
                  colorChangeAnimationDuration: Duration(seconds: 1),
                  loopAnimation: false,
                  curve: Curves.fastOutSlowIn,
                  colorChangeAnimationCurve: Curves.easeInCubic,
                ),
                child: Icon(Icons.shopping_cart,
                    color: currentIndex == 3
                        ? ColorPalette.primaryColor
                        : Colors.black),
              ),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: currentIndex == 4
                  ? Image.asset(ImageAssets.accountColorIconPNG, scale: 3)
                  : Image.asset(ImageAssets.accountIconPNG, scale: 3),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> showDialogBox(BuildContext context) => showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text("No Connection"),
          content: const Text("Please check your internet connectivity"),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.pop(context, 'Cancel');
                isDeviceConnected =
                   await InternetConnectionChecker.createInstance().hasConnection;
                if (!isDeviceConnected) {
                  showDialogBox(context);
                  setState(() => isAlertSet = true);
                } else {
                  setState(() => isAlertSet = false);
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
}

Future exitDialog(context) {
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: Container(
          height: 170.h,
          width: 310.w,
          padding: const EdgeInsets.only(
            left: 18,
            right: 18,
            top: 5,
          ),
          decoration: BoxDecoration(
            color: ColorPalette.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Column(
                children: [
                  Image.asset(
                    ImageAssets.splashLogo,
                    height: 50.h,
                    fit: BoxFit.fill,
                  ),
                  Text(
                    "Are you sure you want to close application?",
                    style: fontStyle(
                      16,
                      Colors.white,
                      FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                        child: const Text(
                          "YES",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "NO",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
