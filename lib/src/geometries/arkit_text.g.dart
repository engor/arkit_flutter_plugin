// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arkit_text.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ARKitText _$ARKitTextFromJson(Map json) => ARKitText(
      text: json['text'] as String,
      extrusionDepth: (json['extrusionDepth'] as num).toDouble(),
      materials: (json['materials'] as List<dynamic>?)
          ?.map((e) => ARKitMaterial.fromJson(e as Map))
          .toList(),
      align: json['align'] as String? ?? 'left',
    );

Map<String, dynamic> _$ARKitTextToJson(ARKitText instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('materials',
      const ListMaterialsValueNotifierConverter().toJson(instance.materials));
  writeNotNull(
      'text', const StringValueNotifierConverter().toJson(instance.text));
  val['extrusionDepth'] = instance.extrusionDepth;
  val['align'] = instance.align;
  return val;
}
