import 'package:hive/hive.dart';
part 'company_model.g.dart';

@HiveType(typeId: 1)
class Company extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late String brandName;

  @HiveField(2)
  late String brandImage;

  Company({required this.id, required this.brandName, required this.brandImage});
}
