// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveSliderAdapter extends TypeAdapter<HiveSlider> {
  @override
  final int typeId = 0;

  @override
  HiveSlider read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSlider(
      fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSlider obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSliderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveBannerAdapter extends TypeAdapter<HiveBanner> {
  @override
  final int typeId = 1;

  @override
  HiveBanner read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveBanner(
      fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveBanner obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveBannerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
