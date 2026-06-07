import 'package:roads_map/models/menu_assets.riverpod.dart';

/// Convert LineColor enum to a valid color string
String getLineColorString(dynamic lineColorValue) {
  if (lineColorValue is String) {
    return lineColorValue;
  } else if (lineColorValue is LineColor) {
    // Convert enum to the actual hex value
    switch (lineColorValue) {
      case LineColor.be121e:
        return "#be121e";
      case LineColor.d55e67:
        return "#d55e67";
      case LineColor.the2aa198:
        return "#2aa198";
    }
  } else {
    return "#2aa198"; // Default teal color
  }
}

/// Get appropriate icon image based on layer name
String getIconImage(String layerName) {
  if (layerName.contains('Road Train Assembly')) return 'rtaa';
  if (layerName.contains('Heavy Vehicle Rest')) return 'heavy';
  if (layerName.contains('Major Rest')) return 'major';
  if (layerName.contains('Minor Rest')) return 'minor';
  if (layerName.contains('Roadhouse')) return 'roadhouse';
  if (layerName.contains('Drive Under')) return 'bridge';
  if (layerName.contains('Drive Over')) return 'bridge';
  if (layerName.contains('Bridge')) return 'bridge';
  if (layerName.contains('Intersection')) return 'intersection';
  return 'alert';
}

/// Get icon size configuration with zoom-based scaling
dynamic getStructuresIconSize(String sourceId) {
  switch (sourceId) {
    case 'drive_over_structures_source':
    case 'drive_under_structures_source':
      return [
        "interpolate",
        ["linear"],
        ["zoom"],
        7,
        0.3,
        10,
        0.5,
        13,
        0.7,
        16,
        1.0
      ];
    default:
      return [
        "interpolate",
        ["linear"],
        ["zoom"],
        7,
        0.2,
        10,
        0.4,
        13,
        0.6,
        16,
        0.8
      ];
  }
}

/// Get line width configuration with zoom-based scaling
List<dynamic> getLineWidth() {
  return [
    "interpolate",
    ["linear", 1],
    ["zoom"],
    7,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      1,
      "Local Road",
      0,
      0
    ],
    10,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      2,
      "Local Road",
      1,
      1
    ],
    12,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      2,
      "Local Road",
      1,
      1
    ],
    13,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      5,
      "Local Road",
      3,
      3
    ],
    15,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      6,
      "Local Road",
      5,
      4
    ],
    16,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      7,
      "Local Road",
      6,
      5
    ],
    17,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      8,
      "Local Road",
      6,
      5
    ]
  ];
}
