import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:roads_map/utils/layer_naming_utilities.dart';
import 'package:roads_map/utils/source_management_utility.dart';

part 'traffic_services.riverpod.g.dart';

// URL for incidents data source
String incidentsUrl = "https://services2.arcgis.com/cHGEnmsJ165IBJRM/ArcGIS/rest/services/WebEoc_RoadIncidents/FeatureServer/1/query?where=1%3D1&outFields=*&f=pgeojson";

// Source and CustomLayer IDs using consistent naming utility
// Incidents (Point)
final String incidentsSourceId = LayerNamingUtility.getSourceId(LayerNamingUtility.CATEGORY_INCIDENT, 'road_incidents');
final String incidentsSymbolLayerId = LayerNamingUtility.getLayerId(LayerNamingUtility.CATEGORY_INCIDENT, 'road_incidents', LayerNamingUtility.TYPE_SYMBOL);

// Track visibility state since we can't query it directly
bool _isIncidentsLayerVisible = false;

// Provider for fetching data
@riverpod
Future<Map<String, dynamic>> fetchIncidentsData(Ref ref) async {
  final dio = Dio();
  final response = await dio.get(incidentsUrl);

  if (response.statusCode == 200) {
    return response.data;
  } else {
    throw Exception('Failed to fetch incidents data');
  }
}

// Process Point data (Incidents)
Map<String, dynamic> processPointData(Map<String, dynamic> data) {
  final List<Map<String, dynamic>> pointFeatures = [];

  if (data['features'] == null || data['features'].isEmpty) {
    debugPrint("No incidents features in the response");
    return createGeoJsonFeatureCollection(pointFeatures);
  }

  for (var feature in data['features']) {
    // Set icon and text field for incidents
    String iconImage = getIncidentIconImage(feature);
    String textFieldValue = getTextField(feature);

    Map<String, dynamic> pointFeature = {
      "type": "Feature",
      "id": feature['id'],
      "geometry": feature['geometry'],
      "properties": {
        ...feature['properties'],
        "iconImage": iconImage,
        "textField": textFieldValue,
      }
    };

    pointFeatures.add(pointFeature);
  }

  return createGeoJsonFeatureCollection(pointFeatures);
}

// Function to map incident types to icon images
String getIncidentIconImage(Map<String, dynamic> feature) {
  final properties = feature['properties'];
  final incidentType = properties['IncidentTy'] ?? '';

  switch (incidentType) {
    case 'Pothole / Road Surface Damage':
      return 'caution';
    case 'Flooding':
      return 'noEntry';
    case 'Break Down / Tow Away':
      return 'alert';
    case 'Road Crash':
      return 'alert';
    case 'Animal / Livestock':
      return 'livestock';
    case 'Debris / Trees / Lost Loads':
      return 'alert';
    case 'Detour':
      return 'detour';
    case 'Roadworks':
      return 'roadworks';
    default:
      return 'trafficConeOther'; // Default fallback icon
  }
}

// Helper function to get text field for incidents
String getTextField(Map<String, dynamic> feature) {
  final properties = feature['properties'];
  final closureType = properties['ClosureTyp'] ?? '';
  final incidentType = properties['IncidentTy'] ?? '';

  // Combine both for more informative label
  return incidentType.isNotEmpty ? '$closureType: $incidentType' : closureType;
}

// Helper to create GeoJSON feature collection
Map<String, dynamic> createGeoJsonFeatureCollection(List<Map<String, dynamic>> features) {
  return {"type": "FeatureCollection", "features": features};
}

// Display function for incidents layer
Future<void> displayIncidentsLayer(MapLibreMapController mapController, Map<String, dynamic> data) async {
  // Remove existing layers
  await removeIncidentsLayers(mapController);
  // Process data for incidents
  final processedData = processPointData(data);

  // Add source using safe source management
  await SourceManagementUtility.safeAddGeoJsonSource(
    mapController,
    incidentsSourceId,
    processedData,
  );

  // Add symbol layer
  await mapController.addSymbolLayer(
    incidentsSourceId,
    incidentsSymbolLayerId,
    SymbolLayerProperties(
      iconHaloColor: "#FFFFFF",
      iconHaloWidth: 5.0,
      iconImage: ['get', 'iconImage'], // Use the iconImage property from the feature
      iconSize: [
        'interpolate',
        ['linear'],
        ['zoom'],
        5,
        0.5,
        10,
        1.0,
        15,
        2.0,
        20,
        3.0
      ], /*
      textField: ['get', 'textField'],
      textSize: 12,
      textOffset: [0, 1.5], // Fixed: Using a List<double> instead of const
      textColor: "#FF4500", // OrangeRed
      textHaloColor: "#FFFFFF",
      textHaloWidth: 5.0,
      iconAnchor: "bottom",
      textFont: [
        "Open Sans Regular",
        "Arial Unicode MS Regular"
      ], */ // Added text-font property
    ),
  );

  // Reset visibility state when adding layer (hidden by default)
  _isIncidentsLayerVisible = false;
  debugPrint('- Incidents layer visibility state initialized: $_isIncidentsLayerVisible');
}

// Function to remove incidents layer
Future<void> removeIncidentsLayers(MapLibreMapController mapController) async {
  final layerIds = await mapController.getLayerIds();
  final sourceIds = await mapController.getSourceIds();
  debugPrint('Removing incidents layers...');

  if (layerIds.contains(incidentsSymbolLayerId)) {
    await mapController.removeLayer(incidentsSymbolLayerId);
    debugPrint('- Removed incidents symbol layer');
  } else {
    debugPrint('- Incidents symbol layer not found');
  }

  if (sourceIds.contains(incidentsSourceId)) {
    await mapController.removeSource(incidentsSourceId);
    debugPrint('- Removed incidents source');
  } else {
    debugPrint('- Incidents source not found');
  }

  // Reset visibility state when removing layer
  _isIncidentsLayerVisible = false;
  debugPrint('- Incidents layer visibility state reset: $_isIncidentsLayerVisible');
}

// Function to toggle visibility
Future<void> setIncidentsLayerVisibility(MapLibreMapController mapController, bool isVisible) async {
  final layerIds = await mapController.getLayerIds();
  debugPrint('Setting incidents layer visibility: $isVisible');

  if (layerIds.contains(incidentsSymbolLayerId)) {
    await mapController.setLayerVisibility(incidentsSymbolLayerId, isVisible);
    debugPrint('- Incidents symbol layer visibility updated');
  } else {
    debugPrint('- Incidents layer not found on map');
  }

  // Update the tracked state
  _isIncidentsLayerVisible = isVisible;
  debugPrint('- Incidents layer visibility state updated: $_isIncidentsLayerVisible');
}

// Helper method to check if incidents layer is currently visible
Future<bool> isIncidentsLayerVisible(MapLibreMapController mapController) async {
  final layerIds = await mapController.getLayerIds();

  // First verify the layer actually exists
  bool incidentsLayerExists = layerIds.contains(incidentsSymbolLayerId);

  // Now check our tracked visibility state, but only if layer exists
  bool isVisible = incidentsLayerExists && _isIncidentsLayerVisible;

  debugPrint('Incidents layer visibility: $isVisible');

  return isVisible;
}

// Helper function to check if incidents layer is loaded
Future<bool> isIncidentsLayerLoaded(MapLibreMapController mapController) async {
  final layerIds = await mapController.getLayerIds();
  final hasIncidents = layerIds.contains(incidentsSymbolLayerId);

  debugPrint('Checking if incidents layer is loaded: $hasIncidents');

  return hasIncidents;
}

// Function to load incidents data
Future<void> loadIncidentsLayer(MapLibreMapController mapController, WidgetRef ref) async {
  debugPrint('=== Loading incidents layer ===');

  try {
    // Load incidents
    final incidentsData = await ref.read(fetchIncidentsDataProvider.future);
    await displayIncidentsLayer(mapController, incidentsData);
    debugPrint('Incidents layer loaded and hidden by default');
  } catch (e) {
    debugPrint('Error loading incidents layer: $e');
  }
}

// Function to toggle incidents layer
Future<void> toggleIncidentsLayer(MapLibreMapController mapController, WidgetRef ref) async {
  debugPrint('=== Toggling incidents layer ===');

  // Toggle the state - flip the current visibility
  final newVisibility = !_isIncidentsLayerVisible;
  debugPrint('- Setting incidents layer to: ${newVisibility ? 'visible' : 'hidden'}');

  try {
    // If showing for the first time, ensure layer is loaded
    if (newVisibility && !(await isIncidentsLayerLoaded(mapController))) {
      debugPrint('- Incidents layer not loaded yet, loading first...');
      await loadIncidentsLayer(mapController, ref);
    }

    // Set the layer to the new visibility
    await setIncidentsLayerVisibility(mapController, newVisibility);
  } catch (e) {
    debugPrint('Error toggling incidents layer: $e');
  }
}
