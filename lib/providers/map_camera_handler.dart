// Camera movement and idle handling for map interactions
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/providers/map_utilities.dart';
import 'package:roads_map/providers/online_layers.dart';

class MapCameraHandler {
  Timer? _cameraIdleDebounceTimer;
  bool _isHandlingCameraIdle = false;
  DateTime _lastUpdateTime = DateTime.now();
  DateTime? _lastStyleLoadTime;

  /// Mark when style was loaded to prevent immediate camera idle triggers
  void markStyleLoaded() {
    _lastStyleLoadTime = DateTime.now();
    debugPrint('Style load time marked: $_lastStyleLoadTime');
  }

  /// Handle camera idle events with debouncing and race condition prevention
  Future<void> onCameraIdle(
    BuildContext context,
    MapLibreMapController? mapController,
    WidgetRef ref,
    bool styleIsLoaded,
    Function(BuildContext?, LatLngBounds) updateVisibleLayers,
  ) async {
    if (mapController == null) return;
    if (!styleIsLoaded) {
      debugPrint('Style not loaded yet, ignoring camera idle event');
      return;
    }
    debugPrint('\n=== MapCameraHandler: onCameraIdle called ===');

    // Check if style was recently loaded (within 2 seconds) to prevent double-loading
    if (_lastStyleLoadTime != null) {
      final currentTime = DateTime.now();
      final timeSinceStyleLoad = currentTime.difference(_lastStyleLoadTime!).inMilliseconds;
      if (timeSinceStyleLoad < 2000) {
        debugPrint('⚠️ Ignoring camera idle - style was loaded ${timeSinceStyleLoad}ms ago, preventing double-load');
        return;
      }
    }

    // Cancel any pending timer
    _cameraIdleDebounceTimer?.cancel();

    // Check if a layer is currently being loaded - prevent race conditions
    final isLayerLoading = ref.read(onlineLayerLoadingProvider);
    if (isLayerLoading) {
      debugPrint('⚠️ Layer is currently loading, skipping camera idle update to prevent race condition');

      // Set a timer to retry after the layer loading completes
      _cameraIdleDebounceTimer =
          Timer(Duration(milliseconds: MapUtilities.updateDelayMilliseconds * 2), () => onCameraIdle(context, mapController, ref, styleIsLoaded, updateVisibleLayers));
      return;
    }

    // Check if we need to enforce cooling period
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastUpdateTime).inMilliseconds;

    if (_isHandlingCameraIdle || timeSinceLastUpdate < MapUtilities.updateDelayMilliseconds) {
      debugPrint('Debouncing camera idle event (last update ${timeSinceLastUpdate}ms ago)');

      // Set a timer to process after the debounce period
      _cameraIdleDebounceTimer =
          Timer(Duration(milliseconds: MapUtilities.updateDelayMilliseconds), () => onCameraIdle(context, mapController, ref, styleIsLoaded, updateVisibleLayers));
      return;
    }

    // We're now handling a camera idle event
    _isHandlingCameraIdle = true;
    _lastUpdateTime = now;

    try {
      // Get current visible bounds
      final visibleBounds = await mapController.getVisibleRegion();
      debugPrint('Visible bounds: ${visibleBounds.southwest} to ${visibleBounds.northeast}');

      // Get active online layer if any
      final activeLayer = ref.read(activeOnlineLayerProvider);

      // Check if we have an active layer that needs updating
      if (activeLayer != null) {
        // Double-check that loading state hasn't changed while we were getting bounds
        final isStillLoading = ref.read(onlineLayerLoadingProvider);
        if (isStillLoading) {
          debugPrint('⚠️ Layer loading detected during bounds check, aborting camera idle update');
          return;
        }

        // Update existing network layer with new bounds
        await updateNetworkLayerWithNewBounds(
          mapController: mapController,
          member: activeLayer,
          visibleBounds: visibleBounds,
          loadingNotifier: ref.read(onlineLayerLoadingProvider.notifier),
          lastBoundsNotifier: ref.read(lastMapBoundsProvider.notifier),
          isLoading: isStillLoading,
        );
      } else {
        // Check if we need to update map data based on selected layers
        await updateVisibleLayers(context, visibleBounds);
      }
    } catch (e) {
      debugPrint('Error in onCameraIdle: $e');
    } finally {
      _isHandlingCameraIdle = false;
      debugPrint('MapCameraHandler: onCameraIdle completed\n');
    }
  }

  /// Handle general map idle events
  void onMapIdle(BuildContext context) {
    debugPrint('\nMapCameraHandler: onMapIdle called');
    // This is a placeholder for future implementation
    // Could handle additional map idle events here
    debugPrint('MapCameraHandler: onMapIdle completed\n');
  }

  /// Clean up resources
  void dispose() {
    _cameraIdleDebounceTimer?.cancel();
  }
}
