// This file extends the MapPageNotifier with better network layer selection handling

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';
import 'package:roads_map/providers/map_page_notifier.riverpod.dart';
import 'package:roads_map/utils/network_filter_utils.dart';

extension MapPageNotifierLayerExtension on MapPageNotifier {
  /// Helper method to handle network layer changes
  void handleNetworkLayerChange(
      BuildContext context, String layerName, WidgetRef ref) {
    debugPrint(
        'MapPageNotifierLayerExtension: Handling network layer change: $layerName');

    // If we have a controller, run the camera idle update process
    if (mapController != null) {
      onCameraIdle(context, ref);
    } else {
      debugPrint(
          'MapPageNotifierLayerExtension: Map controller is null, cannot update layer');
    }
  }

  /// Helper method to filter networks based on selected filters
  bool shouldShowNetwork(String networkName, dynamic filter,
      {List<Filter>? layerFilters}) {
    if (filter is Filter?) {
      // Handle backward compatibility
      return NetworkFilterUtils.shouldShowNetworkWithSingleFilter(
          networkName, filter,
          layerFilters: layerFilters);
    } else if (filter is Set<Filter>) {
      // Handle new multi-filter system
      return NetworkFilterUtils.shouldShowNetwork(networkName, filter,
          layerFilters: layerFilters);
    }
    // Default
    return true;
  }
}
