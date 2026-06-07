import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';
import 'package:roads_map/utils/layer_naming_utilities.dart';
import 'package:roads_map/utils/source_management_utility.dart';

import 'layer_styling_utils.dart';
import 'map_bounds.dart';
import 'network_data_service.dart';
import 'online_layer_providers.dart';

/// Load network layer data within visible bounds
Future<void> loadNetworkLayerData({
  required MapLibreMapController mapController,
  required GroupMember member,
  required LatLngBounds visibleBounds,
  required ActiveOnlineLayerNotifier activeLayerNotifier,
  required OnlineLayerLoadingNotifier loadingNotifier,
  required LastMapBoundsNotifier lastBoundsNotifier,
}) async {
  debugPrint('\n🔄 === LOADING NETWORK LAYER: ${member.name} ===');
  debugPrint('📍 Member ID: ${member.id}');
  debugPrint('📍 Has SubLayers: ${member.subLayers?.isNotEmpty ?? false}');
  debugPrint('📍 Has URL: ${member.url?.isNotEmpty ?? false}');
  debugPrint('📍 Bounds: ${visibleBounds.southwest} to ${visibleBounds.northeast}');

  // Always remove existing network layers before adding new ones
  // This ensures we don't have multiple networks visible at once
  debugPrint('🗑️ Removing existing network layers...');
  await SourceManagementUtility.cleanupNetworkLayers(mapController);
  debugPrint('✅ Existing layers removed');

  // Convert current bounds to our MapBounds class
  final currentBounds = MapBounds(southwest: visibleBounds.southwest, northeast: visibleBounds.northeast);

  // Check if we need to fetch new data
  final shouldFetchNew = lastBoundsNotifier.shouldFetchNewData(currentBounds);

  if (!shouldFetchNew) {
    debugPrint('⚠️ BOUNDS CHECK: Skipping fetch - bounds are similar enough');
    return;
  }

  loadingNotifier.setLoading(true);
  activeLayerNotifier.setActiveLayer(member);
  debugPrint('📝 Set active layer and loading state');

  try {
    // Update the last bounds now that we're fetching new data
    lastBoundsNotifier.setLastBounds(currentBounds);
    debugPrint('📍 Updated last bounds');

    if (member.subLayers != null && member.subLayers!.isNotEmpty) {
      for (final subLayer in member.subLayers!) {
        await _loadSingleLayer(
          mapController: mapController,
          subLayer: subLayer,
          visibleBounds: visibleBounds,
          memberName: member.name,
        );
      }
      debugPrint('✅ All sublayers processed');
    } else if (member.url != null && member.url!.isNotEmpty) {
      await _loadSingleLayerFromMember(
        mapController: mapController,
        member: member,
        visibleBounds: visibleBounds,
      );
      debugPrint('✅ Single layer loaded');
    } else {
      debugPrint('⚠️ No sublayers or URL found for member: ${member.name}');
    }

    debugPrint('🎉 Successfully loaded layer: ${member.name}');
  } catch (e, stackTrace) {
    debugPrint('💥 Error loading network layer: $e');
    if (e is Error) {
      debugPrint('Stack trace: $stackTrace');
    }
  } finally {
    loadingNotifier.setLoading(false);
    debugPrint('✅ Loading state cleared');
    debugPrint('=== END LOADING NETWORK LAYER ===\n');
  }
}

/// Load a single layer from a group member
Future<void> _loadSingleLayerFromMember({
  required MapLibreMapController mapController,
  required GroupMember member,
  required LatLngBounds visibleBounds,
}) async {
  debugPrint('\n🔗 === LOADING SINGLE LAYER FROM MEMBER: ${member.name} ===');
  debugPrint('📍 Member ID: ${member.id}');
  debugPrint('📍 Member URL: ${member.url}');
  debugPrint('📍 Geometry Type: ${member.geometryType}');

  // For layers where subLayers = null && member.url != null
  // Use new featureType-based naming if available, otherwise fall back to 'single'
  String featureTypeString = 'single'; // Default fallback
  if (member.featureType != null) {
    featureTypeString = member.featureType.toString().split('.').last;
    debugPrint('🏷️ GroupMember featureType conversion: ${member.featureType} -> $featureTypeString');
  }

  final sourceId = LayerNamingUtility.getNetworkSourceId(featureTypeString);
  final layerId = LayerNamingUtility.getNetworkLayerId(featureTypeString);
  debugPrint('🏷️ GroupMember naming result: sourceId=$sourceId, layerId=$layerId');

  try {
    // Fetch data if we have a URL
    if (member.url != null && member.url!.isNotEmpty) {
      final boundsString = '${visibleBounds.southwest.longitude},${visibleBounds.southwest.latitude},${visibleBounds.northeast.longitude},${visibleBounds.northeast.latitude}';
      final url = constructUrlWithBounds(member.url!, boundsString);

      final dio = Dio();
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        dynamic jsonData;
        if (response.data is String) {
          jsonData = jsonDecode(response.data);
        } else {
          jsonData = response.data;
        }
        await SourceManagementUtility.safeAddGeoJsonSource(
          mapController,
          sourceId,
          jsonData,
        );

        // Add appropriate layer based on geometry type
        if (member.geometryType == GeometryType.point) {
          final symbolProperties = SymbolLayerProperties(
            iconImage: getIconImage(member.name),
            iconSize: [
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
            ],
          );
          await SourceManagementUtility.safeAddLayer(
            mapController,
            sourceId,
            layerId,
            symbolProperties,
            belowLayerId: 'Continent labels',
          );
        } else if (member.geometryType == GeometryType.polyline) {
          final lineProperties = LineLayerProperties(
            lineColor: getLineColorString(member.lineColor),
            lineWidth: getLineWidth(),
          );
          await SourceManagementUtility.safeAddLayer(
            mapController,
            sourceId,
            layerId,
            lineProperties,
            belowLayerId: 'Road labels',
          );
        }
      }
    } else {
      debugPrint('⚠️ No URL provided for member: ${member.name}');
    }
    debugPrint('=== END LOADING SINGLE LAYER FROM MEMBER ===\n');
  } catch (e) {
    debugPrint('💥 Error loading single layer from member: $e');
    debugPrint('=== END LOADING SINGLE LAYER FROM MEMBER (ERROR) ===\n');
  }
}

/// Load a single sublayer
Future<void> _loadSingleLayer({
  required MapLibreMapController mapController,
  required SubLayer subLayer,
  required LatLngBounds visibleBounds,
  required String memberName,
}) async {
  final subLayerId = subLayer.id;
  debugPrint('\n    🔗 === LOADING SUBLAYER: ${subLayer.name} ===');
  debugPrint('    📍 SubLayer ID: $subLayerId');
  debugPrint('    📍 Feature Type: ${subLayer.featureType}');
  debugPrint('    📍 Geometry Type: ${subLayer.geometryType}');
  debugPrint('    📍 URL: ${subLayer.url}');

  // Use new featureType-based naming convention
  final featureTypeString = subLayer.featureType.toString().split('.').last;
  debugPrint('    🏷️ SubLayer featureType conversion: ${subLayer.featureType} -> $featureTypeString');
  final sourceId = LayerNamingUtility.getNetworkSourceId(featureTypeString);
  final layerId = LayerNamingUtility.getNetworkLayerId(featureTypeString);
  debugPrint('    🏷️ SubLayer naming result: sourceId=$sourceId, layerId=$layerId');

  try {
    debugPrint('    📡 Preparing to fetch data...');

    // Format: minLng,minLat,maxLng,maxLat
    final boundsString = '${visibleBounds.southwest.longitude},${visibleBounds.southwest.latitude},${visibleBounds.northeast.longitude},${visibleBounds.northeast.latitude}';
    debugPrint('    📍 Bounds string: $boundsString');

    // Use the URL from menu_assets.json if available
    String url = '';
    if (subLayer.url.isNotEmpty) {
      url = constructUrlWithBounds(subLayer.url, boundsString);
      debugPrint('    🔗 Using provided URL: $url');
    }

    // If we still don't have a valid URL, generate one
    if (url.isEmpty) {
      url = 'https://gisservices.mainroads.wa.gov.au/arcgis/rest/services/OpenData/HVS_Networks_2_DataPortal/MapServer/$subLayerId'
          '/query?where=1%3D1&geometry=$boundsString&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=*&returnGeometry=true&geometryPrecision=6&outSR=4326'
          '&f=geojson';
      debugPrint('    🔗 Generated fallback URL: $url');
    }

    // Fetch data with visible bounds
    debugPrint('    📡 Fetching data from server...');
    final dio = Dio();
    final response = await dio.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
    debugPrint('    ✅ Data fetched successfully (${response.statusCode})');

    // Parse response
    dynamic jsonData;
    if (response.data is String) {
      jsonData = jsonDecode(response.data);
    } else {
      jsonData = response.data;
    }

    // Count features
    int featureCount = 0;
    if (jsonData is Map<String, dynamic> && jsonData.containsKey('features')) {
      featureCount = (jsonData['features'] as List).length;
    }
    debugPrint('    📊 Parsed GeoJSON with $featureCount features');

    // Get existing sources and layers
    final sourceIds = await mapController.getSourceIds();
    final layerIds = await mapController.getLayerIds();
    debugPrint('    🗂️ Map has ${sourceIds.length} sources and ${layerIds.length} layers');

    // Use safe source management to prevent race conditions
    await SourceManagementUtility.safeAddGeoJsonSource(
      mapController,
      sourceId,
      jsonData,
    ); // Add appropriate layer based on feature type and geometry type
    if (!layerIds.contains(layerId)) {
      debugPrint('    ➕ Adding new layer: $layerId (geometry: ${subLayer.geometryType})');
      if (subLayer.geometryType == GeometryType.point) {
        final symbolProperties = SymbolLayerProperties(
          iconImage: getIconImage(subLayer.name),
          iconSize: [
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
          ],
        );
        await SourceManagementUtility.safeAddLayer(
          mapController,
          sourceId,
          layerId,
          symbolProperties,
          belowLayerId: 'Continent labels',
        );
        debugPrint('    ✅ Symbol layer added: $layerId');
      } else if (subLayer.geometryType == GeometryType.polyline) {
        final lineProperties = LineLayerProperties(
          lineColor: getLineColorString(subLayer.lineColor),
          lineWidth: getLineWidth(),
        );
        await SourceManagementUtility.safeAddLayer(
          mapController,
          sourceId,
          layerId,
          lineProperties,
          belowLayerId: 'Road labels',
        );
        debugPrint('    ✅ Line layer added: $layerId');
      } else {
        debugPrint('    ⚠️ Unknown geometry type: ${subLayer.geometryType}');
      }
    } else {
      debugPrint('    ⚠️ Layer already exists: $layerId');
    }
    debugPrint('    === END LOADING SUBLAYER: ${subLayer.name} ===\n');
  } catch (e) {
    debugPrint('    💥 Error loading sublayer: $e');
    debugPrint('    === END LOADING SUBLAYER (ERROR): ${subLayer.name} ===\n');
  }
}

/// Update the currently displayed layer with new map bounds
Future<void> updateNetworkLayerWithNewBounds({
  required MapLibreMapController mapController,
  required GroupMember member,
  required LatLngBounds visibleBounds,
  required OnlineLayerLoadingNotifier loadingNotifier,
  required LastMapBoundsNotifier lastBoundsNotifier,
  required bool isLoading, // Added isLoading parameter
}) async {
  debugPrint('\n=== Checking if network layer bounds update needed ===');

  // Convert current bounds to our MapBounds class
  final currentBounds = MapBounds(southwest: visibleBounds.southwest, northeast: visibleBounds.northeast);

  // Check if we need to fetch new data
  final shouldFetchNew = lastBoundsNotifier.shouldFetchNewData(currentBounds);

  if (!shouldFetchNew) {
    debugPrint('⚠️ BOUNDS CHECK: Skipping update - bounds are similar enough');
    return;
  }

  debugPrint('Updating bounds for layer: ${member.name}');
  debugPrint('Bounds: ${visibleBounds.southwest} to ${visibleBounds.northeast}');

  // Check if another loading operation is in progress
  if (isLoading) {
    debugPrint('⚠️ Another loading operation in progress, skipping bounds update');
    return;
  }

  loadingNotifier.setLoading(true);

  // Update the last bounds now that we're fetching new data
  lastBoundsNotifier.setLastBounds(currentBounds);
  int updatedSources = 0;

  try {
    if (member.subLayers != null && member.subLayers!.isNotEmpty) {
      // Process each sublayer using featureType-based naming
      for (final subLayer in member.subLayers!) {
        // Use new featureType-based naming
        final featureTypeString = subLayer.featureType.toString().split('.').last;
        final sourceId = LayerNamingUtility.getNetworkSourceId(featureTypeString);

        // Format bounds string for query parameters
        final boundsString = '${visibleBounds.southwest.longitude},${visibleBounds.southwest.latitude},${visibleBounds.northeast.longitude},${visibleBounds.northeast.latitude}';

        // Prepare URL with bounds using helper method
        String url = constructUrlWithBounds(subLayer.url, boundsString);

        try {
          // Get existing sources with timeout protection
          final sourceIds = await mapController.getSourceIds();
          if (sourceIds.contains(sourceId)) {
            debugPrint('📡 Updating source: $sourceId');

            // Fetch updated data
            final dio = Dio();
            final response = await dio.get(url);

            if (response.statusCode == 200) {
              dynamic jsonData;
              if (response.data is String) {
                jsonData = jsonDecode(response.data);
              } else {
                jsonData = response.data;
              }

              // Update the source with new data using safe method
              await SourceManagementUtility.safeUpdateGeoJsonSource(
                mapController,
                sourceId,
                jsonData,
              );
              updatedSources++;
              debugPrint('✅ Updated source: $sourceId');
            }
          } else {
            debugPrint('⚠️ Source not found for update: $sourceId');
          }
        } catch (e) {
          debugPrint('❌ Error updating sublayer ${subLayer.name}: $e');
          // Continue with other sublayers instead of failing completely
        }
      }
    } else if (member.url != null && member.url!.isNotEmpty) {
      // Single layer case - use featureType-based naming with fallback to 'single'
      final featureTypeString = member.featureType?.toString().split('.').last ?? 'single';
      final sourceId = LayerNamingUtility.getNetworkSourceId(featureTypeString);

      // Format bounds string for query parameters
      final boundsString = '${visibleBounds.southwest.longitude},${visibleBounds.southwest.latitude},${visibleBounds.northeast.longitude},${visibleBounds.northeast.latitude}';

      // Prepare URL with bounds using helper method
      String url = constructUrlWithBounds(member.url!, boundsString);

      try {
        // Get existing sources with timeout protection
        final sourceIds = await mapController.getSourceIds();
        if (sourceIds.contains(sourceId)) {
          debugPrint('📡 Updating source: $sourceId');

          // Fetch updated data
          final dio = Dio();
          final response = await dio.get(url);

          if (response.statusCode == 200) {
            dynamic jsonData;
            if (response.data is String) {
              jsonData = jsonDecode(response.data);
            } else {
              jsonData = response.data;
            }

            // Update the source with new data using safe method
            await SourceManagementUtility.safeUpdateGeoJsonSource(
              mapController,
              sourceId,
              jsonData,
            );
            updatedSources++;
            debugPrint('✅ Updated source: $sourceId');
          }
        } else {
          debugPrint('⚠️ Source not found for update: $sourceId');
        }
      } catch (e) {
        debugPrint('❌ Error updating single layer ${member.name}: $e');
      }
    }

    debugPrint('Updated $updatedSources sources for layer ${member.name}');
  } catch (e, stackTrace) {
    debugPrint('Error updating network layer: $e');
    if (e is Error) {
      debugPrint('Stack trace: $stackTrace');
    }
  } finally {
    loadingNotifier.setLoading(false);
    debugPrint('=== Network layer bounds update complete ===\n');
  }
}

/// Remove a network layer
Future<void> removeNetworkLayer({
  required MapLibreMapController mapController,
  required GroupMember member,
  required ActiveOnlineLayerNotifier activeLayerNotifier,
}) async {
  try {
    if (member.subLayers != null && member.subLayers!.isNotEmpty) {
      for (final subLayer in member.subLayers!) {
        // Use new featureType-based naming
        final featureTypeString = subLayer.featureType.toString().split('.').last;
        final sourceId = LayerNamingUtility.getNetworkSourceId(featureTypeString);
        final layerId = LayerNamingUtility.getNetworkLayerId(featureTypeString);

        // Use safe removal to prevent race conditions
        await SourceManagementUtility.safeRemoveSource(
          mapController,
          sourceId,
          layerId,
        );
      }
    } else {
      // Remove single layer case - use featureType-based naming
      String featureTypeString = 'single'; // Default fallback
      if (member.featureType != null) {
        featureTypeString = member.featureType.toString().split('.').last;
      }

      final sourceId = LayerNamingUtility.getNetworkSourceId(featureTypeString);
      final layerId = LayerNamingUtility.getNetworkLayerId(featureTypeString);

      // Use safe removal to prevent race conditions
      await SourceManagementUtility.safeRemoveSource(
        mapController,
        sourceId,
        layerId,
      );
    }

    activeLayerNotifier.setActiveLayer(null);
    debugPrint('Removed network layer: ${member.name}');
  } catch (e) {
    debugPrint('Error removing network layer: $e');
  }
}
