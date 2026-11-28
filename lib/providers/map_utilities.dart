// Map utility functions and helper methods
import 'package:maplibre_gl/maplibre_gl.dart';

class MapUtilities {
  static const int updateDelayMilliseconds =
      500; // Minimum delay between updates

  /// Get the initial camera position for the map
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(-31.95, 115.86),
    zoom: 10,
  );

  /// Get icon size configuration for structures
  static dynamic structuresIconSize(String sourceId) {
    switch (sourceId) {
      case 'drive_over_structures_source':
      case 'drive_under_structures_source':
        return [
          'interpolate',
          ['linear'],
          ['zoom'],
          5,
          0.1,
          10,
          0.4,
          15,
          1.3,
          20,
          2
        ];
      default:
        return [
          'interpolate',
          ['linear'],
          ['zoom'],
          5,
          0.3,
          10,
          0.7,
          15,
          1.7,
          20,
          2.5
        ];
    }
  }

  /// Get the appropriate icon image for a layer
  static String getIconImage(String layerName) {
    if (layerName.contains('Road Train Assembly')) return 'rtaa';
    if (layerName.contains('Heavy Vehicle Rest')) return 'heavy';
    if (layerName.contains('Major Rest')) return 'major';
    if (layerName.contains('Minor Rest')) return 'minor';
    if (layerName.contains('Roadhouse')) return 'roadhouse';
    if (layerName.contains('Drive Under')) {
      return 'bridge'; // Use bridge icon for drive under structures
    }
    if (layerName.contains('Drive Over')) {
      return 'bridge'; // Use bridge icon for drive over structures
    }
    if (layerName.contains('Bridge')) return 'bridge';
    if (layerName.contains('Intersection')) return 'intersection';
    if (layerName.contains('Rav')) return 'trafficCone';
    if (layerName.contains('OSOM')) return 'noEntry';
    if (layerName.contains('Incidents')) return 'caution';
    if (layerName.contains('Inspection')) return 'inspection';
    return 'alert';
  }

  /// Helper method to determine if a layer is a custom layer (not a base map layer)
  static bool isCustomLayer(String layerId) {
    // Base map layers that should have lower priority
    const baseMapLayers = [
      'Background',
      'Residential',
      'Landcover',
      'Hillshade',
      'River',
      'Water shadow',
      'Water',
      'Aeroway',
      'Tunnel path',
      'Tunnel',
      'Railway tunnel',
      'Railway tunnel dash',
      'Land outline',
      'Pier',
      'Pier road',
      'Bridge',
      'Road network',
      'Path minor',
      'Path',
      'Railway',
      'Railway dash',
      'Building',
      'Other border',
      'Other border dash',
      'Disputed border',
      'Country border',
      'Ocean labels',
      'Sea labels',
      'Lakeline labels',
      'Road labels',
      'Place labels',
      'Village labels',
      'Town labels',
      'State labels',
      'City labels',
      'Country labels',
      'Continent labels'
    ];

    // Check if this is a base map layer
    if (baseMapLayers.contains(layerId)) {
      return false;
    }

    // Check if this is an annotation layer
    if (layerId.contains('org.maplibre.annotations') || layerId.length == 10) {
      // MapLibre generated layer IDs are typically 10 chars
      return false;
    }

    // Everything else is considered a custom layer
    return true;
  }
}
