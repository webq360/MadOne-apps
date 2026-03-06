import 'package:hive/hive.dart';
part 'hive_model.g.dart';

@HiveType(typeId: 0)
class HiveSlider extends HiveObject {
  @HiveField(0)
  late String imageUrl;

  HiveSlider(this.imageUrl);
}

@HiveType(typeId: 1)
class HiveBanner extends HiveObject {
  @HiveField(0)
  late String imageUrl;

  HiveBanner(this.imageUrl);
}

