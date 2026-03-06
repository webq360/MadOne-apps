// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:omnicare_app/hive/company_hive/company_hive_service.dart';
import 'package:omnicare_app/hive/company_hive/company_model.dart';

class CompanyController extends GetxController {
  var companyList = <Company>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanyList();
  }

  void fetchCompanyList() async {
    try {
      // Open Hive boxes before saving or loading data
      await CompanyHiveService.openBoxes();

      final List<Company> companiesFromHive =
          await CompanyHiveService.loadCompaniesFromHive();
      if (companiesFromHive.isNotEmpty) {
        print('Data loaded from Hive');
        companyList.assignAll(companiesFromHive);
      } else {
        final response = await http
            .get(Uri.parse('https://app.omnicare.com.bd/api/all_brands'));
        if (response.statusCode == 200) {
          print('Data fetched from API');
          // Rest of the code...
        } else {
          print('Failed to load data from API');
        }
      }
    } catch (error) {
      print('Error: $error');
    }
  }
}
