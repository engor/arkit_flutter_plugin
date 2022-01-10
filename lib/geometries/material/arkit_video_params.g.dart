// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arkit_video_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ARKitVideoParams _$ARKitVideoParamsFromJson(Map<String, dynamic> json) {
  return ARKitVideoParams(
    url: json['url'] as String,
    name: json['name'] as String,
    width: json['width'] as int,
    height: json['height'] as int,
    volume: (json['volume'] as num).toDouble(),
    repeat: json['repeat'] as int,
  );
}

Map<String, dynamic> _$ARKitVideoParamsToJson(ARKitVideoParams instance) =>
    <String, dynamic>{
      'url': instance.url,
      'name': instance.name,
      'width': instance.width,
      'height': instance.height,
      'volume': instance.volume,
      'repeat': instance.repeat,
    };
