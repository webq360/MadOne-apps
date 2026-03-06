// ignore_for_file: prefer_const_constructors, unnecessary_null_comparison, avoid_print

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:omnicare_app/controller/product_controller.dart';
import 'package:omnicare_app/ui/screens/company_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/widgets/home/company_product_screen.dart';

class CompanySection extends StatefulWidget {
  const CompanySection({super.key});

  @override
  State<CompanySection> createState() => _CompanySectionState();
}

class _CompanySectionState extends State<CompanySection> {
  final controller = Get.find<ProductController>();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "All Company",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
            TextButton(
              onPressed: () {
                Get.off(() => const CompanyScreen());
              },
              child: Text(
                "See all",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        Obx(() {
          return SizedBox(
            height: 90.h,
            child: controller.inProgress.value
                ? Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      size: 40,
                      color: ColorPalette.primaryColor,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.companyList.length + 1,
                    itemBuilder: (context, index) {
                      if (index < controller.companyList.length) {
                        final company = controller.companyList[index];
                        return InkWell(
                          onTap: () {
                            Get.to(
                              () => CompanyProductsScreen(
                                companyId: company['id'],
                                companyName: company['brand_name'] ?? "",
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 5.w),
                            child: Column(
                              children: [
                                Container(
                                  width: 90,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.4),
                                        spreadRadius: 2,
                                        blurRadius: 3,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          company['brand_image'].toString(),
                                      progressIndicatorBuilder:
                                          (context, url, downloadProgress) =>
                                              Center(
                                        child: Container(
                                          height: 90.h,
                                          width: 60.w,
                                          margin: EdgeInsets.all(5.w),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                            color: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  company['brand_name'].split(' ').first,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                Get.off(() => const CompanyScreen());
                              },
                              child: Container(
                                height: 65.h,
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(5.w),
                                decoration: BoxDecoration(
                                  //color: const Color.fromARGB(255, 100, 99, 99),
                                  color: ColorPalette.primaryColor
                                      .withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  "See More",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(height: 10)
                          ],
                        );
                      }
                    },
                  ),
          );
        }),
      ],
    );
  }
}
