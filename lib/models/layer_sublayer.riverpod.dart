import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'layer_sublayer.riverpod.g.dart';

/// Enum for geometry types (used for rendering)
enum GeometryType { point, polyline, polygon }

/// A sublayer representing a specific dataset within a layer
@HiveType(typeId: 5)
@JsonSerializable()
class LayerSubLayer {
  @HiveField(1)
  @JsonKey(name: "id")
  final int id;

  @HiveField(3)
  @JsonKey(name: "name")
  final String name;

  @HiveField(5)
  @JsonKey(name: "description")
  final String? description;

  @HiveField(7)
  @JsonKey(name: "path")
  final String? path;

  @HiveField(9)
  @JsonKey(name: "url")
  final String? url;

  @HiveField(11)
  @JsonKey(name: "type")
  final String? type;

  @HiveField(13)
  @JsonKey(name: "featureType")
  final String? featureType;

  @HiveField(15)
  @JsonKey(name: "geometryType")
  final GeometryType? geometryType;

  @HiveField(17)
  @JsonKey(name: "mapIcon")
  final String? mapIcon;

  @HiveField(19)
  @JsonKey(name: "lineColor")
  final String? lineColor;

  LayerSubLayer({
    required this.id,
    required this.name,
    this.description,
    this.path,
    this.url,
    this.type,
    this.featureType,
    this.geometryType,
    this.mapIcon,
    this.lineColor,
  });

  factory LayerSubLayer.fromJson(Map<String, dynamic> json) => LayerSubLayer(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        path: json['path'] as String?,
        url: json['url'] as String?,
        type: json['type'] as String?,
        featureType: json['featureType'] as String?,
        geometryType: json['geometryType'] != null
            ? GeometryType.values.firstWhere(
                (e) => e.toString() == 'GeometryType.${json['geometryType']}',
                orElse: () => GeometryType.point)
            : null,
        mapIcon: json['mapIcon'] as String?,
        lineColor: json['lineColor'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'path': path,
        'url': url,
        'type': type,
        'featureType': featureType,
        'geometryType': geometryType?.toString().split('.').last,
        'mapIcon': mapIcon,
        'lineColor': lineColor,
      };
}
