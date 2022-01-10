import 'dart:ui';

import 'package:arkit_plugin/geometries/material/arkit_video_params.dart';
import 'package:arkit_plugin/utils/json_converters.dart';
import 'package:json_annotation/json_annotation.dart';

part 'arkit_material_property.g.dart';

/// The contents of a ARKitMaterial slot
/// This can be used to specify the various properties of SCNMaterial slots such as diffuse, ambient, etc.
@JsonSerializable()
class ARKitMaterialProperty {
  ARKitMaterialProperty({this.color, this.image, this.video, this.url});

  /// Specifies the receiver's color.
  @ColorConverter()
  final Color color;

  /// Specifies the receiver's image.
  /// It might be either a name of an image stored in native iOS project or
  /// a full path to the file in the Flutter folder (/assets/image/img.jpg)
  /// or URL
  /// or base64 string (highly not recommended due to potential performance issues)
  final String image;
  
  /// Specifies the receiver's video.
  /// It might be either a name of an image stored in native iOS project or
  /// a full path to the file in the Flutter folder (/assets/image/img.jpg)
  /// or URL
  /// or base64 string (highly not recommended due to potential performance issues)
  @ARKitVideoParamsConverter()
  final ARKitVideoParams video;

  /// Specifies the location of an image file
  /// Deprecated: use image field instead
  @deprecated
  final String url;

  static ARKitMaterialProperty fromJson(Map<String, dynamic> json) =>
      _$ARKitMaterialPropertyFromJson(json);

  Map<String, dynamic> toJson() => _$ARKitMaterialPropertyToJson(this)
    ..removeWhere((String k, dynamic v) => v == null);
}
