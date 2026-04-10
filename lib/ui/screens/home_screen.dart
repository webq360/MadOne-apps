// ignore_for_file: avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables, override_on_non_overriding_member

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/const/custom_appbar.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/controller/company_controller.dart';
import 'package:omnicare_app/controller/home_controller.dart';
import 'package:omnicare_app/controller/product_controller.dart';
import 'package:omnicare_app/ui/screens/all_featured_categories_screen.dart';
import 'package:omnicare_app/hive/home_hive/hive_model.dart';
import 'package:omnicare_app/hive/home_hive/home_hive.dart';
import 'package:omnicare_app/ui/widgets/category_list.dart';
import 'package:omnicare_app/ui/widgets/home/offer_product_section.dart';
import 'package:omnicare_app/ui/widgets/home/company_section.dart';
import 'package:omnicare_app/ui/widgets/home/all_product_section.dart';
import 'package:omnicare_app/ui/widgets/home/see_all_product_screen.dart';
import 'package:omnicare_app/ui/widgets/home/trending_product_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController homeController = Get.put(HomeController());
  bool showNotificationDot = false;
  late final CompanyController companyController;

  @override
  void initState() {
    super.initState();
    companyController = Get.put(CompanyController());
    if (!homeController.isDataLoaded.value) {
      loadData();
    }
    Get.find<ProductController>().refreshAllData();
  }

  void loadData() async {
    try {
      homeController.isLoading.value = true;
      final data = await HiveService.loadDataFromHive();
      // Check if data exists in Hive
      if (data[0].isNotEmpty && data[1].isNotEmpty) {
        // Convert data to List<HiveSlider> and List<HiveBanner>
        final List<HiveSlider> sliders = data[0].cast<HiveSlider>();
        final List<HiveBanner> banners = data[1].cast<HiveBanner>();
        // Update sliderList and bannerList
        homeController.sliderList.assignAll(sliders);
        homeController.bannerList.assignAll(banners);
        // Set the flag to true indicating data is loaded
        homeController.isDataLoaded.value = true;
      }
    } catch (e) {
      print('Error loading data from Hive: $e');
    } finally {
      homeController.isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          onNotificationUpdate: (hasUpdate) {
            print('Notification Update Received: $hasUpdate');
          },
        ),
      body: Obx(() {
        if (homeController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        } else {
          if (!homeController.isDataLoaded.value) {
            return Center(child: Text(''));
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  if (homeController.sliderList.isNotEmpty)
                    Stack(
                      children: [
                        ///slider
                        CarouselSlider(
                          items: homeController.sliderList.map((slider) {
                            return Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Colors.black12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.network(
                                slider.imageUrl,
                                fit: BoxFit.fill,
                                width: double.infinity,
                              ),
                            );
                          }).toList(),
                          options: CarouselOptions(
                            height: 180.0,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 10),
                            autoPlayAnimationDuration:
                                const Duration(milliseconds: 800),
                            pauseAutoPlayOnTouch: true,
                            viewportFraction: 1.0,
                            enlargeCenterPage: false,
                            onPageChanged: (index, reason) {
                              homeController.currentIndex.value = index;
                            },
                          ),
                        ),
                        if (homeController.sliderList.isNotEmpty)
                          Positioned(
                            bottom: 3.0,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                homeController.sliderList.length,
                                (index) => Container(
                                  width: 10.0,
                                  height: 10.0,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index ==
                                            homeController.currentIndex.value
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.h),
                          child: CompanySection(),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Featured categories",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.to(() => const AllFeaturedCategoriesScreen());
                                  },
                                  child: Text(
                                    "See all",
                                    style: fontStyle(
                                        12.sp, Colors.black, FontWeight.w400),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 20.h),
                            CategoryList(),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        const TrendingProductSection(),
                        SizedBox(height: 20.h),
                        const AllProductSection(),
                        //const OfferedProductSection(),
                        SizedBox(height: 20.h),
                        if (homeController.bannerList.isNotEmpty)
                          Image.network(
                            homeController.bannerList[0].imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        SizedBox(height: 20.h),
                        const OfferProductSection(),

                        //const OtherProductsSection(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        }
      }),
    );
  }


}
