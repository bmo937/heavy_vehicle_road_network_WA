import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';
import 'package:roads_map/models/menu_assets_notifier.riverpod.dart';

// This provider adapts MenuAssets to provide POI (Points of Interest) layers
final poiLayersProvider = Provider<List<Layer>>((ref) {
  final menuAssetsAsync = ref.watch(menuAssetsNotifierProvider);

  return menuAssetsAsync.when(
    data: (menuAssets) {
      // Filter layers that are Points of Interest
      return menuAssets.layers
          .where((layer) => layer.listMenu == ListMenu.pointsOfInterest)
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// This provider adapts MenuAssets to provide Road Network layers
final roadNetworkLayersProvider = Provider<List<Layer>>((ref) {
  final menuAssetsAsync = ref.watch(menuAssetsNotifierProvider);

  return menuAssetsAsync.when(
    data: (menuAssets) {
      // Filter layers that are Road Networks
      return menuAssets.layers
          .where((layer) => layer.listMenu == ListMenu.roadNetworks)
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Helper extension methods for Layer to provide compatibility with old CustomLayer usage patterns
extension LayerHelpers on Layer {
  // Properties that match the old CustomLayer format
  String get layerName => name;
  int get layerId => id;
  String get parentLayer => listMenu?.toString() ?? '';
  String get childLayer => groupLabel ?? '';

  // Check if the layer has any downloaded content (compatibility with old structure)
  bool get hasDownloadedContent =>
      false; // Default implementation, customize as needed

  // Check if the layer is available online
  bool get isOnlineAvailable => url != null && url!.isNotEmpty;

  // Helper to get group members as a flat list
  List<Layer> get allGroupMembers {
    if (groupMembers == null || groupMembers!.isEmpty) return [];
    return groupMembers!
        .map((member) => Layer(
              id: member.id,
              name: member.name,
              downloadUrl: member.downloadUrl,
              path: member.path,
              url: member.url,
              listTiletype: null,
              listMenu: null,
              filters: member.filters,
              type: LayerType.layerGroup,
            ))
        .toList();
  }

  // Debug helper
  void printDetails() {
    debugPrint('Layer: $name (ID: $id)');
    debugPrint('Type: ${type.toString()}');
    debugPrint('Menu: ${listMenu.toString()}');
    if (url != null) debugPrint('URL: $url');
    if (groupLabel != null) debugPrint('Group Label: $groupLabel');
    if (groupMembers != null) {
      debugPrint('Group Members: ${groupMembers!.length}');
      for (var member in groupMembers!) {
        debugPrint('  - ${member.name} (ID: ${member.id})');
      }
    }
    if (subLayers != null) {
      debugPrint('Sub Layers: ${subLayers!.length}');
      for (var subLayer in subLayers!) {
        debugPrint('  - ${subLayer.name} (ID: ${subLayer.id})');
      }
    }
  }
}
