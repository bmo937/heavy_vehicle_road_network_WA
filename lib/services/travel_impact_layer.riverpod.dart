import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:roads_map/services/dio_provider.dart';
import 'package:roads_map/utils/layer_naming_utilities.dart';
import 'package:roads_map/utils/source_management_utility.dart';

part 'travel_impact_layer.riverpod.g.dart';

final String apiUrlPROD =
    'https://services2.arcgis.com/cHGEnmsJ165IBJRM/arcgis/rest/services/HVS_Travel_Impacts_PROD_-_Active_and_Approved/FeatureServer/0/query?where=1%3D1&geometry=110%2C-40%2C130%2C-10&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelContains&resultType=none&returnGeodetic=true&outFields=*&returnGeometry=true&f=pgeojson&outSR=4326';

// Source and CustomLayer IDs using our naming utility
final String travelImpactSourceId = LayerNamingUtility.getSourceId(
    LayerNamingUtility.CATEGORY_TRAVEL, 'travel_impact');
final String travelImpactLineLayerId = LayerNamingUtility.getLayerId(
    LayerNamingUtility.CATEGORY_TRAVEL,
    'travel_impact',
    LayerNamingUtility.TYPE_LINE);
final String travelImpactSymbolLayerId = LayerNamingUtility.getLayerId(
    LayerNamingUtility.CATEGORY_TRAVEL,
    'travel_impact',
    LayerNamingUtility.TYPE_SYMBOL);

@riverpod
Future<Map<String, dynamic>> fetchGeoJsonData(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(apiUrlPROD);

  if (response.statusCode == 200) {
    return response.data;
  } else {
    throw Exception('Failed to fetch GeoJSON data');
  }
}

// Refactored to create GeoJSON compatible with MapLibre layers
Map<String, dynamic> processGeoJsonData(Map<String, dynamic> params) {
  final Map<String, dynamic> data = params['data'];
  final bool toggleOSOM = params['toggleOSOM'];
  final bool toggleRAV = params['toggleRAV'];

  // Initialize result collections
  final List<Map<String, dynamic>> lineFeatures = [];
  final List<Map<String, dynamic>> symbolFeatures = [];

  if (data['features'] == null || data['features'].isEmpty) {
    debugPrint("No features in the response");
    return {
      'lineFeatures': createGeoJsonFeatureCollection(lineFeatures),
      'symbolFeatures': createGeoJsonFeatureCollection(symbolFeatures)
    };
  }

  for (var feature in data['features']) {
    final geometry = feature['geometry'];
    final geometryType = geometry['type'];
    final restrictionType = feature['properties']['TypeOfRestriction'] ?? '';
    final roadConditions = feature['properties']['RoadConditions'] ?? '';

    bool isOSOM = restrictionType.contains('OSOM');
    bool isRAV = restrictionType.contains('RAV');

    // Skip features that don't match filter criteria
    if ((isOSOM && !toggleOSOM) || (isRAV && !toggleRAV)) {
      continue;
    }

    // Determine line color based on restriction type
    String lineColor = "#FFA500"; // Orange for OSOM by default
    List<dynamic> lineWidth = _getLineWidth();
    List<double>? lineDasharray;

    if (isOSOM && isRAV) {
      lineColor = "#FF0000"; // Red for both OSOM and RAV
    } else if (isRAV) {
      lineColor = "#00C000"; // Green for RAV
    }

    // If No Access, make the line dashed
    if (roadConditions == 'No Access') {
      lineDasharray = [2, 2];
      // lineWidth = 4.0;
    }

    // Create line feature
    Map<String, dynamic> lineFeature = {
      "type": "Feature",
      "id": feature['id'],
      "geometry": geometry,
      "properties": {
        ...feature['properties'],
        "lineColor": lineColor,
        "lineWidth": lineWidth,
        "lineDasharray": lineDasharray,
      }
    };

    lineFeatures.add(lineFeature);

    // Create point feature for symbol
    Map<String, dynamic> symbolFeature =
        createSymbolFeature(feature, geometry, geometryType);
    if (symbolFeature.isNotEmpty) {
      symbolFeatures.add(symbolFeature);
    }
  }

  return {
    'lineFeatures': createGeoJsonFeatureCollection(lineFeatures),
    'symbolFeatures': createGeoJsonFeatureCollection(symbolFeatures)
  };
}

List<dynamic> _getLineWidth() {
  return [
    "interpolate",
    ["linear", 1],
    ["zoom"],
    7,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      3,
      "Local Road",
      0,
      0
    ],
    10,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      4,
      "Local Road",
      3,
      3
    ],
    12,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      4,
      "Local Road",
      3,
      3
    ],
    13,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      7,
      "Local Road",
      5,
      5
    ],
    15,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      8,
      "Local Road",
      7,
      6
    ],
    16,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      9,
      "Local Road",
      8,
      7
    ],
    17,
    [
      "match",
      ["get", "NETWORK_TYPE"],
      "State Road",
      10,
      "Local Road",
      8,
      7
    ]
  ];
}

// Create a symbol feature from a line feature, placing the symbol at the start of the line
Map<String, dynamic> createSymbolFeature(Map<String, dynamic> feature,
    Map<String, dynamic> geometry, String geometryType) {
  // Get coordinates for the first point
  List<dynamic>? firstPoint;

  if (geometryType == 'LineString') {
    final List<dynamic> coordinates = geometry['coordinates'];
    if (coordinates.isNotEmpty) {
      firstPoint = coordinates.first;
    }
  } else if (geometryType == 'MultiLineString') {
    final List<dynamic> lineStrings = geometry['coordinates'];
    if (lineStrings.isNotEmpty && lineStrings.first.isNotEmpty) {
      firstPoint = lineStrings.first.first;
    }
  }

  // If we couldn't get a valid point, return empty
  if (firstPoint == null) return {};
  // Use the first point of the line for the symbol
  String iconImage;
  // Determine icon based on restriction type and conditions
  final restrictionType = feature['properties']['TypeOfRestriction'] ?? '';
  final roadConditions = feature['properties']['RoadConditions'] ?? '';

  if (roadConditions == 'No Access') {
    iconImage = 'noEntry';
  } else if (restrictionType.contains('OSOM')) {
    iconImage =
        'noEntry'; // Use the OSOM icon for OSOM restrictions  } else if (restrictionType.contains('RAV')) {
    iconImage = 'trafficCone'; // Use the RAV icon for RAV restrictions
  } else {
    iconImage = 'trafficCone'; // Default fallback to trafficCone
  }

  return {
    "type": "Feature",
    "id": "${feature['id']}_symbol",
    "geometry": {
      "type": "Point",
      "coordinates": [firstPoint[0], firstPoint[1]] // [longitude, latitude]
    },
    "properties": {
      ...feature['properties'],
      "iconImage": iconImage,
      "textField": feature['properties']['RoadBridgeNameNumber'] ?? '',
    }
  };
}

// Helper to create GeoJSON feature collection
Map<String, dynamic> createGeoJsonFeatureCollection(
    List<Map<String, dynamic>> features) {
  return {"type": "FeatureCollection", "features": features};
}

/* LatLng _calculateCenter(List<LatLng> points) {
  double latitudeSum = 0;
  double longitudeSum = 0;

  for (var point in points) {
    latitudeSum += point.latitude;
    longitudeSum += point.longitude;
  }

  double avgLat = latitudeSum / points.length;
  double avgLng = longitudeSum / points.length;

  return LatLng(avgLat, avgLng);
} */

// Refactored to add GeoJSON sources and layers with separated symbols
Future<void> displayTravelImpactLayer(
    MapLibreMapController mapController, Map<String, dynamic> data) async {
  final lineFeatures = data['lineFeatures'];
  final symbolFeatures = data['symbolFeatures'];
  // Check if sources already exist and remove them if they do
  await removeTravelImpactLayers(mapController);

  // Add line source and layers (split for solid and dashed) using safe source management
  await SourceManagementUtility.safeAddGeoJsonSource(
    mapController,
    "${travelImpactSourceId}_lines",
    lineFeatures,
  );

  // First, add the main lines layer (solid lines)
  await mapController.addLineLayer(
    "${travelImpactSourceId}_lines",
    "${travelImpactLineLayerId}_solid",
    LineLayerProperties(
      lineColor: ['get', 'lineColor'],
      lineWidth: ['get', 'lineWidth'],
      // lineOpacity: 0.8,
      // lineDasharray: [
      //               'literal',
      //               [2, 1]
      //             ],
    ),
    filter: [
      '!=',
      ['get', 'RoadConditions'],
      'No Access'
    ],
    belowLayerId: 'Road labels',
  );

  // Then add a separate layer for dashed lines (No Access roads)
  await mapController.addLineLayer(
    "${travelImpactSourceId}_lines",
    "${travelImpactLineLayerId}_dashed",
    LineLayerProperties(
      lineColor: ['get', 'lineColor'],
      lineWidth: ['get', 'lineWidth'],
      // lineOpacity: 0.8,
      // lineDasharray:[
      //               'literal',
      //               [2, 1]
      //             ]
    ),
    filter: [
      '==',
      ['get', 'RoadConditions'],
      'No Access'
    ],
    belowLayerId: 'Road labels',
  );

  // Split symbol features by type
  final noEntrySymbols = {
    "type": "FeatureCollection",
    "features": symbolFeatures['features']
        .where(
            (feature) => feature['properties']['RoadConditions'] == 'No Access')
        .toList()
  };

  final restrictedSymbols = {
    "type": "FeatureCollection",
    "features": symbolFeatures['features']
        .where(
            (feature) => feature['properties']['RoadConditions'] != 'No Access')
        .toList()
  };
  // Add separate symbol sources for each type using safe source management
  await SourceManagementUtility.safeAddGeoJsonSource(
    mapController,
    "${travelImpactSourceId}_symbols_noEntry",
    noEntrySymbols,
  );

  await SourceManagementUtility.safeAddGeoJsonSource(
    mapController,
    "${travelImpactSourceId}_symbols_restricted",
    restrictedSymbols,
  );

  // Add layer for No Access symbols  await mapController.addSymbolLayer(
  "${travelImpactSourceId}_symbols_noEntry";
  "${travelImpactSymbolLayerId}_noEntry";
  SymbolLayerProperties(
    iconImage: 'noEntry', // Fixed icon for this layer
    iconSize: [
      'interpolate',
      ['linear'],
      ['zoom'],
      // Define size at different zoom levels
      5, 0.8, // At zoom level 5, icon is 80% base size
      10, 1.2, // At zoom level 10, icon is 120% base size
      15, 2.5, // At zoom level 15, icon is 250% base size
      20, 3.5 // At zoom level 20, icon is 350% base size
    ],
    // Enable text labels to help identify the impact
    textField: ['get', 'RoadBridgeNameNumber'],
    textSize: 12,
    textOffset: const [0, 1.5],
    textColor: "#FF0000", // Red text for No Access
    textHaloColor: "#FFFFFF",
    textHaloWidth: 2.0,
    symbolSortKey: 11, // Higher sort key to appear on top
    iconAnchor: "bottom",
    iconAllowOverlap: true, // Allow icons to overlap
  );
  // Add layer for all other symbols (Restricted Access, etc)
  await mapController.addSymbolLayer(
    "${travelImpactSourceId}_symbols_restricted",
    "${travelImpactSymbolLayerId}_restricted",
    SymbolLayerProperties(
      iconImage: 'trafficCone', // Use trafficCone icon for this layer
      iconSize: [
        'interpolate',
        ['linear'],
        ['zoom'],
        // Define size at different zoom levels
        5, 0.5, // At zoom level 5, icon is half its base size
        10, 1.0, // At zoom level 10, icon is base size
        15, 2.0, // At zoom level 15, icon is double size
        20, 3.0 // At zoom level 20, icon is triple size
      ],
      // textField: ['get', 'textField'],
      textSize: 12,
      textOffset: const [0, 1],
      textColor: "#000000",
      textHaloColor: "#FFFFFF",
      textHaloWidth: 1.0,
      symbolSortKey: 10,
      iconAnchor: "bottom",
    ),
  );
}

// Update the remove function to handle the split sources
Future<void> removeTravelImpactLayers(
    MapLibreMapController mapController) async {
  final layerIds = await mapController.getLayerIds();

  // Remove line layers
  if (layerIds.contains("${travelImpactLineLayerId}_solid")) {
    await mapController.removeLayer("${travelImpactLineLayerId}_solid");
  }

  if (layerIds.contains("${travelImpactLineLayerId}_dashed")) {
    await mapController.removeLayer("${travelImpactLineLayerId}_dashed");
  }

  // Remove symbol layers
  if (layerIds.contains("${travelImpactSymbolLayerId}_noEntry")) {
    await mapController.removeLayer("${travelImpactSymbolLayerId}_noEntry");
  }

  if (layerIds.contains("${travelImpactSymbolLayerId}_restricted")) {
    await mapController.removeLayer("${travelImpactSymbolLayerId}_restricted");
  }

  // Remove sources
  final sourceIds = await mapController.getSourceIds();

  if (sourceIds.contains("${travelImpactSourceId}_lines")) {
    await mapController.removeSource("${travelImpactSourceId}_lines");
  }

  if (sourceIds.contains("${travelImpactSourceId}_symbols_noEntry")) {
    await mapController.removeSource("${travelImpactSourceId}_symbols_noEntry");
  }

  if (sourceIds.contains("${travelImpactSourceId}_symbols_restricted")) {
    await mapController
        .removeSource("${travelImpactSourceId}_symbols_restricted");
  }
}

// Update the visibility function to handle the split layers
Future<void> setTravelImpactLayerVisibility(
    MapLibreMapController mapController, bool isVisible) async {
  final layerIds = await mapController.getLayerIds();

  // Update line layers visibility
  if (layerIds.contains("${travelImpactLineLayerId}_solid")) {
    await mapController.setLayerVisibility(
        "${travelImpactLineLayerId}_solid", isVisible);
  }

  if (layerIds.contains("${travelImpactLineLayerId}_dashed")) {
    await mapController.setLayerVisibility(
        "${travelImpactLineLayerId}_dashed", isVisible);
  }

  // Update symbol layers visibility
  if (layerIds.contains("${travelImpactSymbolLayerId}_noEntry")) {
    await mapController.setLayerVisibility(
        "${travelImpactSymbolLayerId}_noEntry", isVisible);
  }

  if (layerIds.contains("${travelImpactSymbolLayerId}_restricted")) {
    await mapController.setLayerVisibility(
        "${travelImpactSymbolLayerId}_restricted", isVisible);
  }
}
