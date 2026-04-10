import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:omnicare_app/const/custom_widgets.dart';
import 'package:omnicare_app/controller/product_controller.dart';
import 'package:omnicare_app/services/cart_provider.dart';
import 'package:omnicare_app/ui/subscreens/product_details_screen.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/utils/image_assets.dart';
import 'package:provider/provider.dart';

class CategoryWiseProductScreen extends StatefulWidget {
  const CategoryWiseProductScreen({super.key});

  @override
  State<CategoryWiseProductScreen> createState() => _CategoryWiseProductScreenState();
}

class _CategoryWiseProductScreenState extends State<CategoryWiseProductScreen> {
  final controller = Get.find<ProductController>();
  bool _isUpdatingQuantity = false;

  void _addToCart(Map<String, dynamic> product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final productId = product['id'] as int;
    final existing = cartProvider.cartItems.firstWhere(
      (item) => item.id == productId,
      orElse: () => CartItem(id: 0, image: '', name: '', sell_price: 0, after_discount_price: 0, company_name: '', subtitle: '', quantity: 0),
    );
    if (existing.quantity > 0) {
      cartProvider.updateCartItemQuantity(existing, existing.quantity);
    } else {
      cartProvider.addToCart(CartItem(
        id: productId,
        image: product['image'] ?? '',
        name: product['name'] ?? '',
        sell_price: double.tryParse('${product['sell_price']}'.replaceAll(',', '')) ?? 0,
        after_discount_price: double.tryParse('${product['after_discount_price']}'.replaceAll(',', '')) ?? 0,
        company_name: product['brand']?['brand_name'] ?? '',
        subtitle: product['name'] ?? '',
        quantity: 1,
        addedFromProductDetails: true,
      ));
      cartProvider.updateQuantity(productId, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          controller.selectedCategoryName.value.isEmpty ? 'Category Products' : controller.selectedCategoryName.value,
          style: const TextStyle(color: Colors.white),
        )),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: ColorPalette.primaryColor,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.categoryWiseLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.categoryWiseProductsList.isEmpty) {
          return const Center(child: Text('No products found'));
        }
        return GridView.builder(
          padding: EdgeInsets.all(10.w),
          itemCount: controller.categoryWiseProductsList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 270.h,
          ),
          itemBuilder: (context, index) {
            final product = controller.categoryWiseProductsList[index];
            final productId = product['id'] as int;
            final cartProvider = Provider.of<CartProvider>(context, listen: false);

            return Stack(
              children: [
                InkWell(
                  onTap: () => Get.to(() => ProductDetailsScreen(productDetails: product)),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: ColorPalette.primaryColor),
                      boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 8,
                          child: CachedNetworkImage(
                            imageUrl: '${product['image']}',
                            fit: BoxFit.contain,
                            placeholder: (_, __) => Container(color: Colors.grey.shade200),
                            errorWidget: (_, __, ___) => Image.asset(ImageAssets.productJPG, scale: 2),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Expanded(
                          flex: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${product['name']} - ${product['brand']?['brand_name']?.toString().split(' ').first ?? ''}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: fontStyle(12, Colors.black, FontWeight.w500),
                              ),
                              Text('৳${product['after_discount_price']}', style: fontStyle(12.sp, Colors.black, FontWeight.w600)),
                              Wrap(
                                spacing: 4,
                                children: [
                                  Text(
                                    '৳${product['sell_price']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w400, decoration: TextDecoration.lineThrough, decorationColor: Colors.red, decorationThickness: 3),
                                  ),
                                  Text(
                                    '${product['discount_type']}'.toLowerCase() == 'percent'
                                        ? '${product['discount']}% Off'
                                        : '৳${product['discount']} ${product['discount_type']}',
                                    style: fontStyle(11, Colors.green, FontWeight.w600),
                                  ),
                                ],
                              ),
                              // ADD / status button
                              Provider.of<CartProvider>(context).getProductQuantityById(productId) == 0
                                  ? InkWell(
                                      onTap: isProductAvailable(product)
                                          ? () {
                                              SchedulerBinding.instance.addPostFrameCallback((_) => _addToCart(product));
                                            }
                                          : null,
                                      child: Container(
                                        height: 28.h,
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
                                        decoration: BoxDecoration(
                                          color: productStatusColor(product),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                productStatusLabel(product),
                                                overflow: TextOverflow.ellipsis,
                                                style: fontStyle(10.sp, Colors.white, FontWeight.w400),
                                              ),
                                            ),
                                            if (isProductAvailable(product)) ...[
                                              SizedBox(width: 4.w),
                                              const Icon(Icons.add, color: Colors.white, size: 16),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (!_isUpdatingQuantity) {
                                              setState(() {
                                                _isUpdatingQuantity = true;
                                                final qty = cartProvider.getProductQuantityById(productId);
                                                cartProvider.updateQuantityById(productId, qty - 1);
                                              });
                                              Future.delayed(const Duration(milliseconds: 700), () => setState(() => _isUpdatingQuantity = false));
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: ColorPalette.primaryColor),
                                            child: const Icon(Icons.remove, color: Colors.white, size: 16),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(
                                            '${cartProvider.getProductQuantityById(productId)}',
                                            style: fontStyle(14, const Color.fromARGB(255, 184, 11, 11), FontWeight.w400),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            if (!_isUpdatingQuantity) {
                                              setState(() {
                                                _isUpdatingQuantity = true;
                                                final qty = cartProvider.getProductQuantityById(productId);
                                                cartProvider.updateQuantityById(productId, qty + 1);
                                              });
                                              Future.delayed(const Duration(milliseconds: 700), () => setState(() => _isUpdatingQuantity = false));
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: ColorPalette.primaryColor),
                                            child: const Icon(Icons.add, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
