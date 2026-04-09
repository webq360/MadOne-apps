// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/controller/company_controller.dart';
import 'package:omnicare_app/services/button_provider.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/splash_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class OmniCare extends StatelessWidget {

  const OmniCare({super.key});
  @override
  Widget build(BuildContext context) {
    final CompanyController companyController = Get.put(CompanyController());
    return  ScreenUtilInit(
      builder: (context, child) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => QuantityButtonsProvider()),
          ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ],
        child: GetMaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'OmniCare',
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: ColorPalette.primaryColor,
              toolbarHeight: 58,
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
      designSize: const Size(360, 800),
    );
  }
}
