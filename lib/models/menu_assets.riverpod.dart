import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'menu_assets.riverpod.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class MenuAssets {
  @HiveField(1)
  @JsonKey(name: "appVersion")
  final String appVersion;
  @HiveField(3)
  @JsonKey(name: "menuVersion")
  final String menuVersion;
  @HiveField(5)
  @JsonKey(name: "mapName")
  final String mapName;
  @HiveField(7)
  @JsonKey(name: "layers")
  final List<Layer> layers;

  MenuAssets({
    required this.appVersion,
    required this.menuVersion,
    required this.mapName,
    required this.layers,
  });

  factory MenuAssets.fromJson(Map<String, dynamic> json) => _$MenuAssetsFromJson(json);

  Map<String, dynamic> toJson() => _$MenuAssetsToJson(this);
}

@HiveType(typeId: 2)
@JsonSerializable()
class Layer {
  @HiveField(1)
  @JsonKey(name: "id")
  final int id;
  @HiveField(3)
  @JsonKey(name: "name")
  final String name;
  @HiveField(5)
  @JsonKey(name: "downloadUrl")
  final dynamic downloadUrl;
  @HiveField(7)
  @JsonKey(name: "path")
  final dynamic path;
  @HiveField(9)
  @JsonKey(name: "url")
  final String? url;
  @HiveField(11)
  @JsonKey(name: "listTiletype")
  final LayerListTiletype? listTiletype;
  @HiveField(13)
  @JsonKey(name: "listMenu")
  final ListMenu? listMenu;
  @HiveField(15)
  @JsonKey(name: "filters")
  final List<Filter> filters;
  @HiveField(17)
  @JsonKey(name: "type")
  final LayerType type;
  @HiveField(19)
  @JsonKey(name: "groupLabel")
  final String? groupLabel;
  @HiveField(21)
  @JsonKey(name: "groupMembers")
  final List<GroupMember>? groupMembers;
  @HiveField(23)
  @JsonKey(name: "subLayers")
  final List<SubLayer>? subLayers;

  Layer({
    required this.id,
    required this.name,
    required this.downloadUrl,
    required this.path,
    required this.url,
    this.listTiletype,
    this.listMenu,
    required this.filters,
    required this.type,
    this.groupLabel,
    this.groupMembers,
    this.subLayers,
  });

  factory Layer.fromJson(Map<String, dynamic> json) => _$LayerFromJson(json);

  Map<String, dynamic> toJson() => _$LayerToJson(this);
}

enum Filter {
  @JsonValue("Agricultural")
  agricultural,
  @JsonValue("AMMS Level 1")
  ammsLevel1,
  @JsonValue("AMMS Level 2")
  ammsLevel2,
  @JsonValue("AMMS Level 3")
  ammsLevel3,
  @JsonValue("")
  empty,
  @JsonValue("Oversize / Overmass")
  oversizeOvermass,
  @JsonValue("Rest Area")
  restArea,
  @JsonValue("SPV")
  spv,
  @JsonValue("Tandem Drive")
  tandemDrive,
  @JsonValue("Travel Impact")
  travelImpact,
  @JsonValue("Tri Drive")
  triDrive
}

final filterValues = EnumValues({
  "Agricultural": Filter.agricultural,
  "AMMS Level 1": Filter.ammsLevel1,
  "AMMS Level 2": Filter.ammsLevel2,
  "AMMS Level 3": Filter.ammsLevel3,
  "": Filter.empty,
  "Oversize / Overmass": Filter.oversizeOvermass,
  "Rest Area": Filter.restArea,
  "SPV": Filter.spv,
  "Tandem Drive": Filter.tandemDrive,
  "Travel Impact": Filter.travelImpact,
  "Tri Drive": Filter.triDrive
});

@HiveType(typeId: 3)
@JsonSerializable()
class GroupMember {
  @HiveField(1)
  @JsonKey(name: "id")
  final int id;
  @HiveField(3)
  @JsonKey(name: "name")
  final String name;
  @HiveField(5)
  @JsonKey(name: "downloadUrl")
  final dynamic downloadUrl;
  @HiveField(7)
  @JsonKey(name: "path")
  final dynamic path;
  @HiveField(9)
  @JsonKey(name: "subLayers")
  final List<SubLayer>? subLayers;
  @HiveField(11)
  @JsonKey(name: "url")
  final String? url;
  @HiveField(13)
  @JsonKey(name: "listTiletype")
  final GroupMemberListTiletype listTiletype;
  @HiveField(15)
  @JsonKey(name: "filters")
  final List<Filter> filters;
  @HiveField(17)
  @JsonKey(name: "type")
  final SubLayerType type;
  @HiveField(19)
  @JsonKey(name: "featureType")
  final GroupMemberFeatureType? featureType;
  @HiveField(21)
  @JsonKey(name: "geometryType")
  final GeometryType? geometryType;
  @HiveField(23)
  @JsonKey(name: "mapIcon")
  final String? mapIcon;
  @HiveField(25)
  @JsonKey(name: "lineColor")
  final String? lineColor;

  GroupMember({
    required this.id,
    required this.name,
    required this.downloadUrl,
    required this.path,
    required this.subLayers,
    required this.url,
    required this.listTiletype,
    required this.filters,
    required this.type,
    this.featureType,
    this.geometryType,
    this.mapIcon,
    this.lineColor,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => _$GroupMemberFromJson(json);

  Map<String, dynamic> toJson() => _$GroupMemberToJson(this);
}

enum GroupMemberFeatureType {
  @JsonValue("incident")
  incident,
  @JsonValue("osom")
  osom,
  @JsonValue("rav")
  rav,
  @JsonValue("single")
  single
}

final groupMemberFeatureTypeValues =
    EnumValues({"incident": GroupMemberFeatureType.incident, "osom": GroupMemberFeatureType.osom, "rav": GroupMemberFeatureType.rav, "single": GroupMemberFeatureType.single});

enum GeometryType {
  @JsonValue("point")
  point,
  @JsonValue("polyline")
  polyline
}

final geometryTypeValues = EnumValues({"point": GeometryType.point, "polyline": GeometryType.polyline});

enum GroupMemberListTiletype {
  @JsonValue("radioListTile")
  radioListTile,
  @JsonValue("switchListTile")
  switchListTile
}

final groupMemberListTiletypeValues = EnumValues({"radioListTile": GroupMemberListTiletype.radioListTile, "switchListTile": GroupMemberListTiletype.switchListTile});

@HiveType(typeId: 4)
@JsonSerializable()
class SubLayer {
  @HiveField(1)
  @JsonKey(name: "id")
  final int id;
  @HiveField(3)
  @JsonKey(name: "name")
  final String name;
  @HiveField(5)
  @JsonKey(name: "downloadUrl")
  final dynamic downloadUrl;
  @HiveField(7)
  @JsonKey(name: "path")
  final dynamic path;
  @HiveField(9)
  @JsonKey(name: "subLayers")
  final dynamic subLayers;
  @HiveField(11)
  @JsonKey(name: "url")
  final String url;
  @HiveField(13)
  @JsonKey(name: "type")
  final SubLayerType type;
  @HiveField(15)
  @JsonKey(name: "featureType")
  final SubLayerFeatureType featureType;
  @HiveField(17)
  @JsonKey(name: "geometryType")
  final GeometryType geometryType;
  @HiveField(19)
  @JsonKey(name: "mapIcon")
  final MapIcon? mapIcon;
  @HiveField(21)
  @JsonKey(name: "lineColor")
  final LineColor? lineColor;

  SubLayer({
    required this.id,
    required this.name,
    required this.downloadUrl,
    required this.path,
    required this.subLayers,
    required this.url,
    required this.type,
    required this.featureType,
    required this.geometryType,
    required this.mapIcon,
    required this.lineColor,
  });

  factory SubLayer.fromJson(Map<String, dynamic> json) => _$SubLayerFromJson(json);

  Map<String, dynamic> toJson() => _$SubLayerToJson(this);
}

enum SubLayerFeatureType {
  @JsonValue("bridges")
  bridges,
  @JsonValue("intersections")
  intersections,
  @JsonValue("without_conditions")
  withoutConditions,
  @JsonValue("with_conditions")
  withConditions
}

final subLayerFeatureTypeValues = EnumValues({
  "bridges": SubLayerFeatureType.bridges,
  "intersections": SubLayerFeatureType.intersections,
  "without_conditions": SubLayerFeatureType.withoutConditions,
  "with_conditions": SubLayerFeatureType.withConditions
});

enum LineColor {
  @JsonValue("#be121e")
  be121e,
  @JsonValue("#d55e67")
  d55e67,
  @JsonValue("#2aa198")
  the2aa198
}

final lineColorValues = EnumValues({"#be121e": LineColor.be121e, "#d55e67": LineColor.d55e67, "#2aa198": LineColor.the2aa198});

enum MapIcon {
  @JsonValue("bridge")
  bridge,
  @JsonValue("intersection")
  intersection
}

final mapIconValues = EnumValues({"bridge": MapIcon.bridge, "intersection": MapIcon.intersection});

enum SubLayerType {
  @JsonValue("Feature Layer")
  featureLayer,
  @JsonValue("Layer Group")
  layerGroup
}

final subLayerTypeValues = EnumValues({"Feature Layer": SubLayerType.featureLayer, "Layer Group": SubLayerType.layerGroup});

enum ListMenu {
  @JsonValue("Points of Interest")
  pointsOfInterest,
  @JsonValue("Road Networks")
  roadNetworks
}

final listMenuValues = EnumValues({"Points of Interest": ListMenu.pointsOfInterest, "Road Networks": ListMenu.roadNetworks});

enum LayerListTiletype {
  @JsonValue("header")
  header,
  @JsonValue("radioListTile")
  radioListTile
}

final layerListTiletypeValues = EnumValues({"header": LayerListTiletype.header, "radioListTile": LayerListTiletype.radioListTile});

enum LayerType {
  @JsonValue("Layer Group")
  layerGroup,
  @JsonValue("Menu Group")
  menuGroup
}

final layerTypeValues = EnumValues({"Layer Group": LayerType.layerGroup, "Menu Group": LayerType.menuGroup});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
