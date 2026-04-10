import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/controller/product_controller.dart';
import 'package:omnicare_app/ui/screens/category_wise_product_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';

class AllFeaturedCategoriesScreen extends StatelessWidget {
  const AllFeaturedCategoriesScreen({super.key});

  String _buildImageUrl(String? imageName) {
    if (imageName == null || imageName.isEmpty) return '';
    if (imageName.startsWith('http')) return imageName;
    return 'https://app.medonetrade.com//public/uploads/$imageName';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Featured Categories', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: ColorPalette.primaryColor,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.featuredCategoryList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return GridView.builder(
          padding: EdgeInsets.all(12.w),
          itemCount: controller.featuredCategoryList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final category = controller.featuredCategoryList[index];
            final String name = category['category_name']?.toString() ?? '';
            final String imageUrl = _buildImageUrl(category['image']?.toString() ?? category['category_image']?.toString());
            final int categoryId = category['id'] ?? 0;

            return InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () async {
                await controller.getCategoryWiseProducts(
                  categoryId: categoryId,
                  categoryName: name,
                );
                Get.to(() => const CategoryWiseProductScreen());
              },
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                errorWidget: (_, __, ___) => Container(
                                  color: ColorPalette.primaryColor.withOpacity(0.1),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: ColorPalette.primaryColor),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: ColorPalette.primaryColor.withOpacity(0.1),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: ColorPalette.primaryColor),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
