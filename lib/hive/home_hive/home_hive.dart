import 'package:hive/hive.dart';
import 'package:omnicare_app/hive/home_hive/hive_model.dart';

class HiveService {
  static Box<HiveSlider>? slidersBox;
  static Box<HiveBanner>? bannersBox;

  static Future<void> openBoxes() async {
    try {
      if (!Hive.isBoxOpen('sliders')) {
        slidersBox = await Hive.openBox<HiveSlider>('sliders');
      } else {
        slidersBox = Hive.box<HiveSlider>('sliders');
      }

      if (!Hive.isBoxOpen('banners')) {
        bannersBox = await Hive.openBox<HiveBanner>('banners');
      } else {
        bannersBox = Hive.box<HiveBanner>('banners');
      }
    } catch (e) {
      print('Error opening Hive boxes: $e');
    }
  }

  static Future<void> closeBoxes() async {
    try {
      await slidersBox?.close();
      await bannersBox?.close();
    } catch (e) {
      print('Error closing Hive boxes: $e');
    }
  }

  static Future<void> saveDataToHive(List<HiveSlider> sliders, List<HiveBanner> banners) async {
    try {
      if (slidersBox == null || bannersBox == null) {
        await openBoxes();
      }

      if (slidersBox!.isNotEmpty) {
        slidersBox!.clear(); // Clear the box before putting new data
      }
      if (bannersBox!.isNotEmpty) {
        bannersBox!.clear(); // Clear the box before putting new data
      }

      final slidersMap = { for (var slider in sliders) sliders.indexOf(slider).toString() : slider };
      await slidersBox!.putAll(slidersMap);

      final bannersMap = { for (var banner in banners) banners.indexOf(banner).toString() : banner };
      await bannersBox!.putAll(bannersMap);

      print('Data saved to Hive');
    } catch (e) {
      print('Error saving data to Hive: $e');
    }
  }

  static Future<List<dynamic>> loadDataFromHive() async {
    try {
      if (slidersBox == null || bannersBox == null) {
        await openBoxes();
      }

      final sliders = slidersBox!.values.toList().cast<HiveSlider>(); // Explicitly cast to HiveSlider
      final banners = bannersBox!.values.toList().cast<HiveBanner>(); // Explicitly cast to HiveBanner

      print('Data loaded from Hive');

      return [sliders, banners];
    } catch (e) {
      print('Error loading data from Hive: $e');
      return [[], []]; // Return empty lists in case of error
    }
  }
}
