// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_assets.riverpod.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuAssetsAdapter extends TypeAdapter<MenuAssets> {
  @override
  final typeId = 1;

  @override
  MenuAssets read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuAssets(
      appVersion: fields[1] as String,
      menuVersion: fields[3] as String,
      mapName: fields[5] as String,
      layers: (fields[7] as List).cast<Layer>(),
    );
  }

  @override
  void write(BinaryWriter writer, MenuAssets obj) {
    writer
      ..writeByte(4)
      ..writeByte(1)
      ..write(obj.appVersion)
      ..writeByte(3)
      ..write(obj.menuVersion)
      ..writeByte(5)
      ..write(obj.mapName)
      ..writeByte(7)
      ..write(obj.layers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuAssetsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LayerAdapter extends TypeAdapter<Layer> {
  @override
  final typeId = 2;

  @override
  Layer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Layer(
      id: (fields[1] as num).toInt(),
      name: fields[3] as String,
      downloadUrl: fields[5] as dynamic,
      path: fields[7] as dynamic,
      url: fields[9] as String?,
      listTiletype: fields[11] as LayerListTiletype?,
      listMenu: fields[13] as ListMenu?,
      filters: (fields[15] as List).cast<Filter>(),
      type: fields[17] as LayerType,
      groupLabel: fields[19] as String?,
      groupMembers: (fields[21] as List?)?.cast<GroupMember>(),
      subLayers: (fields[23] as List?)?.cast<SubLayer>(),
    );
  }

  @override
  void write(BinaryWriter writer, Layer obj) {
    writer
      ..writeByte(12)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.downloadUrl)
      ..writeByte(7)
      ..write(obj.path)
      ..writeByte(9)
      ..write(obj.url)
      ..writeByte(11)
      ..write(obj.listTiletype)
      ..writeByte(13)
      ..write(obj.listMenu)
      ..writeByte(15)
      ..write(obj.filters)
      ..writeByte(17)
      ..write(obj.type)
      ..writeByte(19)
      ..write(obj.groupLabel)
      ..writeByte(21)
      ..write(obj.groupMembers)
      ..writeByte(23)
      ..write(obj.subLayers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupMemberAdapter extends TypeAdapter<GroupMember> {
  @override
  final typeId = 3;

  @override
  GroupMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupMember(
      id: (fields[1] as num).toInt(),
      name: fields[3] as String,
      downloadUrl: fields[5] as dynamic,
      path: fields[7] as dynamic,
      subLayers: (fields[9] as List?)?.cast<SubLayer>(),
      url: fields[11] as String?,
      listTiletype: fields[13] as GroupMemberListTiletype,
      filters: (fields[15] as List).cast<Filter>(),
      type: fields[17] as SubLayerType,
      featureType: fields[19] as GroupMemberFeatureType?,
      geometryType: fields[21] as GeometryType?,
      mapIcon: fields[23] as String?,
      lineColor: fields[25] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupMember obj) {
    writer
      ..writeByte(13)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.downloadUrl)
      ..writeByte(7)
      ..write(obj.path)
      ..writeByte(9)
      ..write(obj.subLayers)
      ..writeByte(11)
      ..write(obj.url)
      ..writeByte(13)
      ..write(obj.listTiletype)
      ..writeByte(15)
      ..write(obj.filters)
      ..writeByte(17)
      ..write(obj.type)
      ..writeByte(19)
      ..write(obj.featureType)
      ..writeByte(21)
      ..write(obj.geometryType)
      ..writeByte(23)
      ..write(obj.mapIcon)
      ..writeByte(25)
      ..write(obj.lineColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubLayerAdapter extends TypeAdapter<SubLayer> {
  @override
  final typeId = 4;

  @override
  SubLayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubLayer(
      id: (fields[1] as num).toInt(),
      name: fields[3] as String,
      downloadUrl: fields[5] as dynamic,
      path: fields[7] as dynamic,
      subLayers: fields[9] as dynamic,
      url: fields[11] as String,
      type: fields[13] as SubLayerType,
      featureType: fields[15] as SubLayerFeatureType,
      geometryType: fields[17] as GeometryType,
      mapIcon: fields[19] as MapIcon?,
      lineColor: fields[21] as LineColor?,
    );
  }

  @override
  void write(BinaryWriter writer, SubLayer obj) {
    writer
      ..writeByte(11)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.downloadUrl)
      ..writeByte(7)
      ..write(obj.path)
      ..writeByte(9)
      ..write(obj.subLayers)
      ..writeByte(11)
      ..write(obj.url)
      ..writeByte(13)
      ..write(obj.type)
      ..writeByte(15)
      ..write(obj.featureType)
      ..writeByte(17)
      ..write(obj.geometryType)
      ..writeByte(19)
      ..write(obj.mapIcon)
      ..writeByte(21)
      ..write(obj.lineColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubLayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuAssets _$MenuAssetsFromJson(Map<String, dynamic> json) => MenuAssets(
      appVersion: json['appVersion'] as String,
      menuVersion: json['menuVersion'] as String,
      mapName: json['mapName'] as String,
      layers: (json['layers'] as List<dynamic>)
          .map((e) => Layer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MenuAssetsToJson(MenuAssets instance) =>
    <String, dynamic>{
      'appVersion': instance.appVersion,
      'menuVersion': instance.menuVersion,
      'mapName': instance.mapName,
      'layers': instance.layers,
    };

Layer _$LayerFromJson(Map<String, dynamic> json) => Layer(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      downloadUrl: json['downloadUrl'],
      path: json['path'],
      url: json['url'] as String?,
      listTiletype:
          $enumDecodeNullable(_$LayerListTiletypeEnumMap, json['listTiletype']),
      listMenu: $enumDecodeNullable(_$ListMenuEnumMap, json['listMenu']),
      filters: (json['filters'] as List<dynamic>)
          .map((e) => $enumDecode(_$FilterEnumMap, e))
          .toList(),
      type: $enumDecode(_$LayerTypeEnumMap, json['type']),
      groupLabel: json['groupLabel'] as String?,
      groupMembers: (json['groupMembers'] as List<dynamic>?)
          ?.map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      subLayers: (json['subLayers'] as List<dynamic>?)
          ?.map((e) => SubLayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LayerToJson(Layer instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'downloadUrl': instance.downloadUrl,
      'path': instance.path,
      'url': instance.url,
      'listTiletype': _$LayerListTiletypeEnumMap[instance.listTiletype],
      'listMenu': _$ListMenuEnumMap[instance.listMenu],
      'filters': instance.filters.map((e) => _$FilterEnumMap[e]!).toList(),
      'type': _$LayerTypeEnumMap[instance.type]!,
      'groupLabel': instance.groupLabel,
      'groupMembers': instance.groupMembers,
      'subLayers': instance.subLayers,
    };

const _$LayerListTiletypeEnumMap = {
  LayerListTiletype.header: 'header',
  LayerListTiletype.radioListTile: 'radioListTile',
};

const _$ListMenuEnumMap = {
  ListMenu.pointsOfInterest: 'Points of Interest',
  ListMenu.roadNetworks: 'Road Networks',
};

const _$FilterEnumMap = {
  Filter.agricultural: 'Agricultural',
  Filter.ammsLevel1: 'AMMS Level 1',
  Filter.ammsLevel2: 'AMMS Level 2',
  Filter.ammsLevel3: 'AMMS Level 3',
  Filter.empty: '',
  Filter.oversizeOvermass: 'Oversize / Overmass',
  Filter.restArea: 'Rest Area',
  Filter.spv: 'SPV',
  Filter.tandemDrive: 'Tandem Drive',
  Filter.travelImpact: 'Travel Impact',
  Filter.triDrive: 'Tri Drive',
};

const _$LayerTypeEnumMap = {
  LayerType.layerGroup: 'Layer Group',
  LayerType.menuGroup: 'Menu Group',
};

GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) => GroupMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      downloadUrl: json['downloadUrl'],
      path: json['path'],
      subLayers: (json['subLayers'] as List<dynamic>?)
          ?.map((e) => SubLayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      url: json['url'] as String?,
      listTiletype:
          $enumDecode(_$GroupMemberListTiletypeEnumMap, json['listTiletype']),
      filters: (json['filters'] as List<dynamic>)
          .map((e) => $enumDecode(_$FilterEnumMap, e))
          .toList(),
      type: $enumDecode(_$SubLayerTypeEnumMap, json['type']),
      featureType: $enumDecodeNullable(
          _$GroupMemberFeatureTypeEnumMap, json['featureType']),
      geometryType:
          $enumDecodeNullable(_$GeometryTypeEnumMap, json['geometryType']),
      mapIcon: json['mapIcon'] as String?,
      lineColor: json['lineColor'] as String?,
    );

Map<String, dynamic> _$GroupMemberToJson(GroupMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'downloadUrl': instance.downloadUrl,
      'path': instance.path,
      'subLayers': instance.subLayers,
      'url': instance.url,
      'listTiletype': _$GroupMemberListTiletypeEnumMap[instance.listTiletype]!,
      'filters': instance.filters.map((e) => _$FilterEnumMap[e]!).toList(),
      'type': _$SubLayerTypeEnumMap[instance.type]!,
      'featureType': _$GroupMemberFeatureTypeEnumMap[instance.featureType],
      'geometryType': _$GeometryTypeEnumMap[instance.geometryType],
      'mapIcon': instance.mapIcon,
      'lineColor': instance.lineColor,
    };

const _$GroupMemberListTiletypeEnumMap = {
  GroupMemberListTiletype.radioListTile: 'radioListTile',
  GroupMemberListTiletype.switchListTile: 'switchListTile',
};

const _$SubLayerTypeEnumMap = {
  SubLayerType.featureLayer: 'Feature Layer',
  SubLayerType.layerGroup: 'Layer Group',
};

const _$GroupMemberFeatureTypeEnumMap = {
  GroupMemberFeatureType.incident: 'incident',
  GroupMemberFeatureType.osom: 'osom',
  GroupMemberFeatureType.rav: 'rav',
  GroupMemberFeatureType.single: 'single',
};

const _$GeometryTypeEnumMap = {
  GeometryType.point: 'point',
  GeometryType.polyline: 'polyline',
};

SubLayer _$SubLayerFromJson(Map<String, dynamic> json) => SubLayer(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      downloadUrl: json['downloadUrl'],
      path: json['path'],
      subLayers: json['subLayers'],
      url: json['url'] as String,
      type: $enumDecode(_$SubLayerTypeEnumMap, json['type']),
      featureType:
          $enumDecode(_$SubLayerFeatureTypeEnumMap, json['featureType']),
      geometryType: $enumDecode(_$GeometryTypeEnumMap, json['geometryType']),
      mapIcon: $enumDecodeNullable(_$MapIconEnumMap, json['mapIcon']),
      lineColor: $enumDecodeNullable(_$LineColorEnumMap, json['lineColor']),
    );

Map<String, dynamic> _$SubLayerToJson(SubLayer instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'downloadUrl': instance.downloadUrl,
      'path': instance.path,
      'subLayers': instance.subLayers,
      'url': instance.url,
      'type': _$SubLayerTypeEnumMap[instance.type]!,
      'featureType': _$SubLayerFeatureTypeEnumMap[instance.featureType]!,
      'geometryType': _$GeometryTypeEnumMap[instance.geometryType]!,
      'mapIcon': _$MapIconEnumMap[instance.mapIcon],
      'lineColor': _$LineColorEnumMap[instance.lineColor],
    };

const _$SubLayerFeatureTypeEnumMap = {
  SubLayerFeatureType.bridges: 'bridges',
  SubLayerFeatureType.intersections: 'intersections',
  SubLayerFeatureType.withoutConditions: 'without_conditions',
  SubLayerFeatureType.withConditions: 'with_conditions',
};

const _$MapIconEnumMap = {
  MapIcon.bridge: 'bridge',
  MapIcon.intersection: 'intersection',
};

const _$LineColorEnumMap = {
  LineColor.be121e: '#be121e',
  LineColor.d55e67: '#d55e67',
  LineColor.the2aa198: '#2aa198',
};
