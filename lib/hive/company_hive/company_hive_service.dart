// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:hive/hive.dart';
import 'package:omnicare_app/hive/company_hive/company_model.dart';

class CompanyHiveService {
  static late Box<Company> companyBox;

  static Future<void> openBoxes() async {
    try {
      if (!Hive.isBoxOpen('companies')) {
        companyBox = await Hive.openBox<Company>('companies');
      } else {
        companyBox = Hive.box<Company>('companies');
      }
    } catch (e) {
      print('Error opening Hive box: $e');
    }
  }

  static Future<void> closeBoxes() async {
    try {
      await companyBox.close();
    } catch (e) {
      print('Error closing Hive box: $e');
    }
  }

  static Future<void> saveCompaniesToHive(List<Company> companies) async {
    try {
      if (companyBox == null) {
        await openBoxes();
      }

      if (companyBox.isNotEmpty) {
        companyBox.clear(); // Clear the box before putting new data
      }

      await companyBox.addAll(companies);
    } catch (e) {
      print('Error saving companies to Hive: $e');
    }
  }

  static Future<List<Company>> loadCompaniesFromHive() async {
    try {
      if (companyBox == null) {
        await openBoxes();
      }

      return companyBox.values.toList();
    } catch (e) {
      print('Error loading companies from Hive: $e');
      return [];
    }
  }
}
