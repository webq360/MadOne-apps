// ignore_for_file: avoid_print, deprecated_member_use, prefer_const_constructors

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:omnicare_app/const/bottom_navbar.dart';
import 'package:omnicare_app/ui/screens/shimmer_widget.dart';
import 'package:omnicare_app/ui/utils/color_palette.dart';
import 'package:omnicare_app/ui/widgets/home/company_product_screen.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  List<dynamic> companyList = [];
  bool isLoading = false;
  List<dynamic> filteredCompanyList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
      });
      final response = await http.get(
          Uri.parse('https://stage.medone.primeharvestbd.com/api/all_brands'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> brands = responseData['data']['brands'];

        // Sort the companyList based on 'brand_name'
        brands.sort((a, b) => a['brand_name'].compareTo(b['brand_name']));

        setState(() {
          companyList = List<Map<String, dynamic>>.from(brands);
          filteredCompanyList = List.from(companyList);
        });
      } else {
        // Handle error - response.statusCode
        print('Failed to load data');
      }
    } catch (error) {
      // Handle error - exception
      print('Error: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void searchProducts(String query) {
    setState(() {
      filteredCompanyList = companyList
          .where((company) =>
              company['brand_name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => const BottomNavBarScreen());
        // Return false to prevent the default back button behavior
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 100,
          backgroundColor: ColorPalette.primaryColor,
          title: Column(
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Get.offAll(() => const BottomNavBarScreen());
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      )),
                  SizedBox(
                    width: 70.w,
                  ),
                  const Text(
                    'Company',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              SizedBox(
                height: 40.h,
                // width: 130,
                child: TextFormField(
                  controller: searchController,
                  onChanged: searchProducts,
                  decoration: InputDecoration(
                    hintText: 'Search Company',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    prefixIcon:
                        Icon(Icons.search, size: 17, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await fetchData();
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: isLoading
                ? const ShimmerWidget()
                : ListView.separated(
                    itemCount: filteredCompanyList.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          final companyId = filteredCompanyList[index]['id'];
                          if (companyId != null) {
                            print(
                                'Navigating to CompanyProductsScreen with Company ID: $companyId');
                            Get.to(
                              () => CompanyProductsScreen(
                                companyId: companyId,
                                companyName: filteredCompanyList[index]
                                        ['brand_name'] ??
                                    "",
                              ),
                            );
                          } else {
                            print('Company ID is null for this entry');
                            // You can show a snackbar or any other UI feedback here
                          }
                        },
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            width: 60.w,
                            height: 60.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: ColorPalette.cardColor,
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 5,
                                  color: Colors.black12,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.network(
                              filteredCompanyList[index]['brand_image'] ?? '',
                            ),
                          ),
                          title: Text(
                              filteredCompanyList[index]['brand_name'] ?? ''),
                          subtitle: Text(
                              '${filteredCompanyList[index]['products_count'] ?? ''} items'),

                          // Add onTap or any other properties as needed
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      // Add a Divider between each ListTile
                      return Divider(
                        height: 15,
                        color: Colors.grey[300],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
