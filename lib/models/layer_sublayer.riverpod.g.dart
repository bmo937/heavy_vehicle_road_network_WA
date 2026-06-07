// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layer_sublayer.riverpod.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LayerSubLayerAdapter extends TypeAdapter<LayerSubLayer> {
  @override
  final typeId = 5;

  @override
  LayerSubLayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LayerSubLayer(
      id: (fields[1] as num).toInt(),
      name: fields[3] as String,
      description: fields[5] as String?,
      path: fields[7] as String?,
      url: fields[9] as String?,
      type: fields[11] as String?,
      featureType: fields[13] as String?,
      geometryType: fields[15] as GeometryType?,
      mapIcon: fields[17] as String?,
      lineColor: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LayerSubLayer obj) {
    writer
      ..writeByte(10)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.path)
      ..writeByte(9)
      ..write(obj.url)
      ..writeByte(11)
      ..write(obj.type)
      ..writeByte(13)
      ..write(obj.featureType)
      ..writeByte(15)
      ..write(obj.geometryType)
      ..writeByte(17)
      ..write(obj.mapIcon)
      ..writeByte(19)
      ..write(obj.lineColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayerSubLayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LayerSubLayer _$LayerSubLayerFromJson(Map<String, dynamic> json) =>
    LayerSubLayer(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      path: json['path'] as String?,
      url: json['url'] as String?,
      type: json['type'] as String?,
      featureType: json['featureType'] as String?,
      geometryType:
          $enumDecodeNullable(_$GeometryTypeEnumMap, json['geometryType']),
      mapIcon: json['mapIcon'] as String?,
      lineColor: json['lineColor'] as String?,
    );

Map<String, dynamic> _$LayerSubLayerToJson(LayerSubLayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'path': instance.path,
      'url': instance.url,
      'type': instance.type,
      'featureType': instance.featureType,
      'geometryType': _$GeometryTypeEnumMap[instance.geometryType],
      'mapIcon': instance.mapIcon,
      'lineColor': instance.lineColor,
    };

const _$GeometryTypeEnumMap = {
  GeometryType.point: 'point',
  GeometryType.polyline: 'polyline',
  GeometryType.polygon: 'polygon',
};
