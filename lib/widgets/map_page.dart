import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:roads_map/providers/map_page_notifier.riverpod.dart';
import 'package:roads_map/providers/network_selection_provider.riverpod.dart';
import 'package:roads_map/utils/app_themes.riverpod.dart';
import 'package:roads_map/utils/map_style_service.riverpod.dart';

class MapPage extends HookConsumerWidget {
  const MapPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapPageProvider = ref.read(mapPageNotifierProvider.notifier);
    final currentStyleUrl = ref.watch(
        mapThemeProvider); // Listen for theme changes and trigger map rebuild
    ref.listen<String>(mapThemeProvider, (previous, next) {
      if (previous != null && previous != next) {
        debugPrint('🎨 MAP THEME CHANGED: $previous -> $next');
        debugPrint('🚀 Style change detected, map will rebuild with new style');
        // Invalidate old-style work before the replacement map is created.
        mapPageProvider.onStyleChangeBegan();
      }
    });

    // Listen for network layer selection changes and force layer updates
    ref.listen<String?>(networkLayerSelectionProvider, (previous, next) {
      if (previous != next) {
        debugPrint('🔄 NETWORK LAYER SELECTION CHANGED: $previous -> $next');
        debugPrint('🚀 Calling forceLayerUpdate() from MapPage listener...');
        // Force layer update when selection changes
        if (mapPageProvider.mapController != null) {
          mapPageProvider.forceLayerUpdate(mapPageProvider.mapController!, ref);
        }
      }
    });

    // Listen for POI layer selection changes and force layer updates
    ref.listen<Map<String, bool>>(poiLayerSelectionProvider, (previous, next) {
      if (previous != next) {
        debugPrint('🔄 POI LAYER SELECTION CHANGED');
        debugPrint('🚀 Calling forceLayerUpdate() from MapPage listener...');
        // Force layer update when selection changes
        if (mapPageProvider.mapController != null) {
          mapPageProvider.forceLayerUpdate(mapPageProvider.mapController!, ref);
        }
      }
    });
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: false,
      backgroundColor: ref.watch(primaryColorProvider),
      body: Stack(
        children: [
          MapLibreMap(
            key: ValueKey(currentStyleUrl), // Force rebuild when style changes
            styleString: currentStyleUrl,
            onMapCreated: (controller) =>
                mapPageProvider.onMapCreated(controller, ref, context),
            onStyleLoadedCallback: () async {
              mapPageProvider.onStyleLoaded(context, ref);
            },
            onCameraIdle: () {
              mapPageProvider.onCameraIdle(context, ref);
            },
            initialCameraPosition: mapPageProvider.initialCameraPosition,
            compassViewPosition: CompassViewPosition.topRight,
            compassViewMargins: Point(15, 50),
            cameraTargetBounds: CameraTargetBounds(LatLngBounds(
              southwest: const LatLng(-35.135060, 112.920394),
              northeast: const LatLng(-13.741018, 129.003317),
            )),
            minMaxZoomPreference: const MinMaxZoomPreference(5, 18),
            trackCameraPosition: true,
          ),
        ],
      ),
    );
  }
}
