import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Utility class for safe source and layer management to prevent race conditions
class SourceManagementUtility {
  /// Safely add a GeoJSON source, handling potential race conditions
  static Future<void> safeAddGeoJsonSource(
    MapLibreMapController mapController,
    String sourceId,
    dynamic geoJsonData, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
  }) async {
    debugPrint('🔧 SafeAddGeoJsonSource: $sourceId');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Check if source already exists
        final sourceIds = await mapController.getSourceIds();

        if (sourceIds.contains(sourceId)) {
          debugPrint('⚠️ Source already exists: $sourceId (attempt $attempt)');

          // Try to remove it first
          try {
            await mapController.removeSource(sourceId);
            debugPrint('✅ Removed existing source: $sourceId'); // Small delay to ensure cleanup completes
            await Future.delayed(const Duration(milliseconds: 150));
          } catch (removeError) {
            debugPrint('⚠️ Warning removing existing source: $removeError');

            // If we can't remove it, try updating instead
            try {
              await mapController.setGeoJsonSource(sourceId, geoJsonData);
              debugPrint('✅ Updated existing source: $sourceId');
              return; // Success via update
            } catch (updateError) {
              debugPrint('❌ Failed to update source: $updateError');
              // If updating also fails, skip this source to prevent crash
              if (attempt == maxRetries) {
                debugPrint('💥 Skipping source $sourceId to prevent crash after $maxRetries attempts');
                return; // Return instead of throwing to prevent crash
              }
              await Future.delayed(retryDelay);
              continue; // Try again
            }
          }
        }

        // Add the source
        await mapController.addGeoJsonSource(sourceId, geoJsonData);
        debugPrint('✅ Added source: $sourceId (attempt $attempt)');
        return; // Success
      } catch (e) {
        debugPrint('❌ Error adding source $sourceId (attempt $attempt): $e');

        if (attempt == maxRetries) {
          debugPrint('💥 Failed to add source $sourceId after $maxRetries attempts - skipping to prevent crash');
          return; // Return instead of throwing to prevent crash
        }

        // Wait before retrying
        await Future.delayed(retryDelay);
      }
    }
  }

  /// Safely add a layer, handling potential race conditions
  static Future<void> safeAddLayer(
    MapLibreMapController mapController,
    String sourceId,
    String layerId,
    LayerProperties layerProperties, {
    String? belowLayerId,
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
  }) async {
    debugPrint('🔧 SafeAddLayer: $layerId');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Check if layer already exists
        final layerIds = await mapController.getLayerIds();

        if (layerIds.contains(layerId)) {
          debugPrint('⚠️ Layer already exists: $layerId (attempt $attempt)');

          // Try to remove it first
          try {
            await mapController.removeLayer(layerId);
            debugPrint('✅ Removed existing layer: $layerId');

            // Small delay to ensure cleanup completes
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (removeError) {
            debugPrint('⚠️ Warning removing existing layer: $removeError');
            if (attempt == maxRetries) {
              debugPrint('💥 Layer $layerId already exists and cannot be removed - skipping to prevent crash');
              return; // Return instead of throwing to prevent crash
            }
            await Future.delayed(retryDelay);
            continue; // Try again
          }
        }

        // Add the layer based on type
        if (layerProperties is SymbolLayerProperties) {
          await mapController.addSymbolLayer(
            sourceId,
            layerId,
            layerProperties,
            belowLayerId: belowLayerId,
          );
        } else if (layerProperties is LineLayerProperties) {
          await mapController.addLineLayer(
            sourceId,
            layerId,
            layerProperties,
            belowLayerId: belowLayerId,
          );
        } else {
          await mapController.addLayer(
            sourceId,
            layerId,
            layerProperties,
            belowLayerId: belowLayerId,
          );
        }

        debugPrint('✅ Added layer: $layerId (attempt $attempt)');
        return; // Success
      } catch (e) {
        debugPrint('❌ Error adding layer $layerId (attempt $attempt): $e');
        if (attempt == maxRetries) {
          debugPrint('💥 Failed to add layer $layerId after $maxRetries attempts - skipping to prevent crash');
          return; // Return instead of throwing to prevent crash
        }

        // Wait before retrying
        await Future.delayed(retryDelay);
      }
    }
  }

  /// Safely remove a source and all its associated layers
  static Future<void> safeRemoveSource(
    MapLibreMapController mapController,
    String sourceId,
    String layerId, {
    List<String>? associatedLayers,
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 50),
  }) async {
    debugPrint('🔧 SafeRemoveSource: $sourceId');

    try {
      final sourceIds = await mapController.getSourceIds();
      final layerIds = await mapController.getLayerIds();

      if (!sourceIds.contains(sourceId)) {
        debugPrint('ℹ️ Source does not exist: $sourceId');
        return; // Already removed or never existed
      }

      // Remove the primary layer first
      if (layerIds.contains(layerId)) {
        await _safeRemoveLayer(mapController, layerId, maxRetries, retryDelay);
      }

      // Remove additional associated layers
      if (associatedLayers != null) {
        for (String additionalLayerId in associatedLayers) {
          if (layerIds.contains(additionalLayerId)) {
            await _safeRemoveLayer(mapController, additionalLayerId, maxRetries, retryDelay);
          }
        }
      }

      // Remove the source
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          await mapController.removeSource(sourceId);
          debugPrint('✅ Removed source: $sourceId');
          return;
        } catch (e) {
          debugPrint('❌ Error removing source $sourceId (attempt $attempt): $e');
          if (attempt == maxRetries) {
            debugPrint('💥 Failed to remove source $sourceId after $maxRetries attempts');
            throw Exception('Failed to remove source $sourceId: $e');
          }
          await Future.delayed(retryDelay);
        }
      }
    } catch (e) {
      debugPrint('💥 Error in safeRemoveSource: $e');
      rethrow;
    }
  }

  /// Safely remove a layer
  static Future<void> _safeRemoveLayer(
    MapLibreMapController mapController,
    String layerId,
    int maxRetries,
    Duration retryDelay,
  ) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await mapController.removeLayer(layerId);
        debugPrint('✅ Removed layer: $layerId');
        return;
      } catch (e) {
        debugPrint('❌ Error removing layer $layerId (attempt $attempt): $e');
        if (attempt == maxRetries) {
          debugPrint('💥 Failed to remove layer $layerId after $maxRetries attempts');
          throw Exception('Failed to remove layer $layerId: $e');
        }
        await Future.delayed(retryDelay);
      }
    }
  }

  /// Safely update a GeoJSON source, handling potential race conditions
  static Future<void> safeUpdateGeoJsonSource(
    MapLibreMapController mapController,
    String sourceId,
    dynamic geoJsonData, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
  }) async {
    debugPrint('🔧 SafeUpdateGeoJsonSource: $sourceId');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Check if source exists first
        final sourceIds = await mapController.getSourceIds();

        if (!sourceIds.contains(sourceId)) {
          debugPrint('⚠️ Source does not exist: $sourceId - adding instead');
          await safeAddGeoJsonSource(mapController, sourceId, geoJsonData);
          return;
        }

        // Update the existing source
        await mapController.setGeoJsonSource(sourceId, geoJsonData);
        debugPrint('✅ Updated source: $sourceId (attempt $attempt)');
        return; // Success
      } catch (e) {
        debugPrint('❌ Error updating source $sourceId (attempt $attempt): $e');

        if (attempt == maxRetries) {
          debugPrint('💥 Failed to update source $sourceId after $maxRetries attempts - skipping to prevent crash');
          return; // Return instead of throwing to prevent crash
        }

        // Wait before retrying
        await Future.delayed(retryDelay);
      }
    }
  }

  /// Comprehensive cleanup method to remove all network-related sources and layers
  /// This helps prevent "already exists" errors by ensuring clean state
  static Future<void> cleanupNetworkLayers(
    MapLibreMapController mapController, {
    bool removeAllSources = false,
  }) async {
    debugPrint('🧹 CleanupNetworkLayers: Starting comprehensive cleanup');

    try {
      final sourceIds = await mapController.getSourceIds();
      final layerIds = await mapController.getLayerIds();

      // Network-related patterns to clean up
      final networkPatterns = [
        'bridgesSource', 'bridgesLayer',
        'intersectionsSource', 'intersectionsLayer',
        'withConditionsSource', 'withConditionsLayer',
        'withoutConditionsSource', 'withoutConditionsLayer',
        'singleSource', 'singleLayer',
        'layer_', 'source_', // Legacy patterns
      ];

      // Remove layers first (layers depend on sources)
      int removedLayers = 0;
      for (String layerId in layerIds) {
        bool shouldRemove = networkPatterns.any((pattern) => layerId.contains(pattern) || layerId.startsWith(pattern));

        if (shouldRemove) {
          try {
            await mapController.removeLayer(layerId);
            debugPrint('🗑️ Removed layer: $layerId');
            removedLayers++;
          } catch (e) {
            debugPrint('⚠️ Warning removing layer $layerId: $e');
          }
        }
      }

      // Small delay to ensure layer cleanup completes
      if (removedLayers > 0) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // Remove sources
      int removedSources = 0;
      for (String sourceId in sourceIds) {
        bool shouldRemove = networkPatterns.any((pattern) => sourceId.contains(pattern) || sourceId.startsWith(pattern));

        if (shouldRemove || removeAllSources) {
          try {
            await mapController.removeSource(sourceId);
            debugPrint('🗑️ Removed source: $sourceId');
            removedSources++;
          } catch (e) {
            debugPrint('⚠️ Warning removing source $sourceId: $e');
          }
        }
      }

      debugPrint('✅ Cleanup complete: removed $removedLayers layers and $removedSources sources');
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
    }
  }
}
