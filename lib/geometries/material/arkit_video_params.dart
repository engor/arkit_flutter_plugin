import 'package:json_annotation/json_annotation.dart';

part 'arkit_video_params.g.dart';

@JsonSerializable()
class ARKitVideoParams {
  String url, name;
  int width, height;
  double volume;
  int repeat;

  ARKitVideoParams({
    this.url,
    this.name,
    this.width,
    this.height,
    this.volume = 0.7,
    this.repeat = -1,
  }) {
    name ??= url;
  }

  static ARKitVideoParams fromJson(Map<String, dynamic> json) =>
      _$ARKitVideoParamsFromJson(json);

  Map<String, dynamic> toJson() => _$ARKitVideoParamsToJson(this);
}
