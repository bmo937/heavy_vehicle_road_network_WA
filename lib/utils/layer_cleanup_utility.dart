// Function to remove any existing network layers before adding new ones
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/utils/layer_naming_utilities.dart';

Future<void> removeExistingNetworkLayers(
    MapLibreMapController mapController) async {
  try {
    debugPrint('\n🗑️ === REMOVING EXISTING NETWORK LAYERS ===');

    // Get current layer IDs
    final layerIds = await mapController.getLayerIds();
    final sourceIds = await mapController.getSourceIds();

    debugPrint(
        '🗂️ Current map state: ${layerIds.length} layers, ${sourceIds.length} sources');
    debugPrint('📋 Current layers: ${layerIds.join(", ")}');
    debugPrint(
        '📋 Current sources: ${sourceIds.join(", ")}'); // Use the new featureType-based naming utility to get all network layer IDs
    final networkLayerIds = LayerNamingUtility.getAllNetworkLayerIds();
    final networkSourceIds = LayerNamingUtility.getAllNetworkSourceIds();

    // Get travel impact layer IDs for cleanup (but exclude POI layers - they're pre-loaded and visibility-toggled)
    final travelImpactLayerIds =
        LayerNamingUtility.getAllTravelImpactLayerIds();
    final travelImpactSourceIds =
        LayerNamingUtility.getAllTravelImpactSourceIds();

    final allLayerIds = [...networkLayerIds, ...travelImpactLayerIds];
    final allSourceIds = [...networkSourceIds, ...travelImpactSourceIds];

    debugPrint(
        '🎯 Network + Travel Impact layers to check: ${allLayerIds.join(", ")}');
    debugPrint(
        '🎯 Network + Travel Impact sources to check: ${allSourceIds.join(", ")}');
    debugPrint(
        'ℹ️ NOTE: POI layers are excluded from cleanup (pre-loaded with visibility control)'); // Remove all layers using new naming convention
    int removedLayers = 0;
    for (var layerId in allLayerIds) {
      if (layerIds.contains(layerId)) {
        await mapController.removeLayer(layerId);
        debugPrint('✅ Removed layer: $layerId');
        removedLayers++;
      }
    }

    // Remove all sources using new naming convention
    int removedSources = 0;
    for (var sourceId in allSourceIds) {
      if (sourceIds.contains(sourceId)) {
        await mapController.removeSource(sourceId);
        debugPrint('✅ Removed source: $sourceId');
        removedSources++;
      }
    } // Also clean up legacy naming patterns for backward compatibility (excluding POI patterns)
    final legacyNetworkPatterns = [
      'layer-network-', // Old standardized naming
      'source-network-', // Old standardized naming
      'layer_', // Legacy sublayer IDs
      'source_', // Legacy sublayer sources
    ];

    debugPrint('🔍 Checking for legacy patterns (excluding POI layers)...');
    int removedLegacyLayers = 0;
    int removedLegacySources = 0;

    // Remove legacy layers (but skip POI-related ones)
    for (var pattern in legacyNetworkPatterns) {
      if (pattern.startsWith('layer')) {
        final legacyLayers = layerIds
            .where((id) =>
                    (id.startsWith(pattern) || id.contains(pattern)) &&
                    !id.contains('poi') && // Exclude POI layers
                    !id.contains('-poi-') // Exclude new standardized POI layers
                )
            .toList();
        for (var layerId in legacyLayers) {
          try {
            await mapController.removeLayer(layerId);
            debugPrint('✅ Removed legacy network layer: $layerId');
            removedLegacyLayers++;
          } catch (e) {
            debugPrint(
                '⚠️ Warning: Could not remove legacy layer $layerId: $e');
          }
        }
      } else if (pattern.startsWith('source')) {
        final legacySources = sourceIds
            .where((id) =>
                    (id.startsWith(pattern) || id.contains(pattern)) &&
                    !id.contains('poi') && // Exclude POI sources
                    !id.contains(
                        '-poi-') // Exclude new standardized POI sources
                )
            .toList();
        for (var sourceId in legacySources) {
          try {
            await mapController.removeSource(sourceId);
            debugPrint('✅ Removed legacy network source: $sourceId');
            removedLegacySources++;
          } catch (e) {
            debugPrint(
                '⚠️ Warning: Could not remove legacy source $sourceId: $e');
          }
        }
      }
    }
    debugPrint(
        '📊 Cleanup summary: $removedLayers layers + $removedLegacyLayers legacy layers, $removedSources sources + $removedLegacySources legacy sources removed');
    debugPrint('ℹ️ POI layers preserved for visibility control (not removed)');
    debugPrint('=== FINISHED REMOVING EXISTING NETWORK LAYERS ===\n');
  } catch (e) {
    debugPrint('💥 Error removing existing network layers: $e');
  }
}
