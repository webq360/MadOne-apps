import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/controller/product_controller.dart';
import 'package:omnicare_app/ui/screens/category_wise_product_screen.dart';

class CategoryList extends StatelessWidget {
  CategoryList({super.key});

  final ProductController controller = Get.find<ProductController>();

  final String baseImageUrl =
      "https://stage.medone.primeharvestbd.com/uploads/category/";

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.inProgress.value &&
          controller.featuredCategoryList.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.featuredCategoryList.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('No category found'),
          ),
        );
      }

      return GridView.builder(
        itemCount: controller.featuredCategoryList.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final category = controller.featuredCategoryList[index];

          final String name =
              category['category_name']?.toString() ?? 'No Name';

          final String imageName =
              category['category_image']?.toString() ?? '';

          final int categoryId = category['id'] ?? 0;

          final String imageUrl =
              imageName.isNotEmpty ? "$baseImageUrl$imageName" : "";

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
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
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
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(Icons.image_not_supported),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}