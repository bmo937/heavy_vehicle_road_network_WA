import 'package:roads_map/hive_boxes.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';
import 'package:roads_map/models/menu_helpers.dart';
import 'package:roads_map/providers/map_page_notifier.riverpod.dart';
import 'package:roads_map/providers/network_selection_provider.riverpod.dart';
import 'package:roads_map/utils/layer_naming_utilities.dart';
import 'package:roads_map/utils/marker_utilities.riverpod.dart';

class PointsOfInterestMenu extends ConsumerWidget {
  const PointsOfInterestMenu({super.key, required this.menuAssets, this.showOnlyDownloaded = false});

  final MenuAssets menuAssets;
  final bool showOnlyDownloaded;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter for Points of Interest layers
    final poiLayers = menuAssets.layers.where((layer) => layer.listMenu == ListMenu.pointsOfInterest).toList();

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxHeight.isFinite) {
        return Column(
          children: [
            Expanded(
              child: poiLayers.isEmpty ? const Center(child: Text('No points of interest available')) : _buildPoiList(context, ref, poiLayers),
            ),
          ],
        );
      } else {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (poiLayers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No points of interest available'),
                ),
              ...poiLayers.map((layer) => _buildMenuGroup(context, ref, layer)),
            ],
          ),
        );
      }
    });
  }

  // Build the list of POI layers
  Widget _buildPoiList(BuildContext context, WidgetRef ref, List<Layer> layers) {
    return CustomScrollView(
      slivers: [
        for (final layer in layers) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(layer.groupLabel ?? layer.name, style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (layer.groupMembers == null || layer.groupMembers!.isEmpty) {
                  return null;
                }
                return _buildPoiSwitch(context, ref, layer.groupMembers![index]);
              },
              childCount: layer.groupMembers?.length ?? 0,
            ),
          ),
        ],
      ],
    );
  }

  // Build a menu group (e.g., "Stopping Places" or "Travel Impacts")
  Widget _buildMenuGroup(BuildContext context, WidgetRef ref, Layer layer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(layer.groupLabel ?? layer.name, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (layer.groupMembers != null) ...layer.groupMembers!.map((member) => _buildPoiSwitch(context, ref, member)),
      ],
    );
  }

  // Build switch list tile for POI items
  Widget _buildPoiSwitch(BuildContext context, WidgetRef ref, GroupMember member) {
    // Use key-specific watch to ensure reactivity
    final selections = ref.watch(pointsOfInterestSelectionNotifierProvider);
    final isSelected = selections[member.name] ?? false;
    debugPrint('Building switch for ${member.name}: isSelected=$isSelected');
    final markerImagesAsync = ref.watch(markerImagesProvider);
    String getIconImage(String layerName) {
      if (layerName.contains('Road Train Assembly')) return 'rtaa';
      if (layerName.contains('Heavy Vehicle Rest')) return 'heavy';
      if (layerName.contains('Major')) return 'major';
      if (layerName.contains('Minor')) return 'minor';
      if (layerName.contains('Roadhouse')) return 'roadhouse';
      if (layerName.contains('Inspection')) return 'inspection';
      if (layerName.contains('Rav')) return 'trafficCone';
      if (layerName.contains('OSOM')) return 'noEntry';
      if (layerName.contains('Incidents')) return 'caution';
      return 'alert';
    }

    return Card(
      elevation: 0,
      child: SwitchListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(member.name),
            ),
            markerImagesAsync.when(
              data: (images) {
                // Try to find image by layer name or a related identifier
                final imageKey = getIconImage(member.name);

                // Add debugging
                debugPrint('Looking for image with key: $imageKey');

                // Try each lookup method separately to isolate the issue
                Uint8List? imageBytes;

                // First try direct lookup from images map
                if (images.containsKey(imageKey)) {
                  imageBytes = images[imageKey];
                  debugPrint('Found image via direct key lookup');
                }
                // Then try without underscores
                else if (images.containsKey(imageKey.replaceAll('_', ''))) {
                  imageBytes = images[imageKey.replaceAll('_', '')];
                  debugPrint('Found image via key without underscores');
                }
                // Then try by layer name
                else if (images.containsKey(member.name)) {
                  imageBytes = images[member.name];
                  debugPrint('Found image via layer name');
                }
                // Finally try the utility method
                else {
                  imageBytes = MarkerUtilities.getImageById(imageKey);
                  if (imageBytes != null) {
                    debugPrint('Found image via MarkerUtilities.getImageById()');
                  } else {
                    debugPrint('Image not found with key: $imageKey');
                  }
                }

                if (imageBytes != null && imageBytes.isNotEmpty) {
                  return Image.memory(
                    imageBytes,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  );
                } else {
                  // Log which fallback icon is being used
                  debugPrint('Using fallback icon for: ${member.name} (key: $imageKey)');
                  return Icon(
                    Icons.broken_image,
                    size: 36,
                    color: Colors.red,
                  );
                }
              },
              // Rest of the code remains the same
              error: (_, __) => Icon(
                Icons.broken_image,
                size: 36,
                color: Colors.red,
              ),
              loading: () => SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
        value: isSelected,
        onChanged: (value) async {
          await _togglePointOfInterest(ref, member, value);
        },
      ),
    );
  } // Toggle point of interest and save to Hive

  Future<void> _togglePointOfInterest(WidgetRef ref, GroupMember member, bool value) async {
    // Open both Hive boxes for maximum compatibility
    final pointsOfInterestBox = await Hive.openBox(pointsOfInterestBoxName);
    final selectedPoiLayerBox = Hive.isBoxOpen(HiveBoxes.selectedPoiLayer) ? Hive.box(HiveBoxes.selectedPoiLayer) : await Hive.openBox(HiveBoxes.selectedPoiLayer);

    // Update both provider states for consistent layer selection
    await ref.read(pointsOfInterestSelectionNotifierProvider.notifier).toggleLayer(member.name, value);
    await ref.read(poiLayerSelectionProvider.notifier).toggleLayer(member.name, value);

    // Save to both Hive boxes to ensure consistency
    await pointsOfInterestBox.put('${member.name}_$visibilityKey', value);
    await selectedPoiLayerBox.put(member.name, value);

    debugPrint('Saved POI state to Hive: ${member.name} = $value');

    // If turning off a layer, store it for potential restoration
    if (!value) {
      ref.read(previouslyVisiblePOIProvider.notifier).addLayer(member.name);
    }

    // Update master toggle if needed
    final allLayers = ref.read(pointsOfInterestSelectionNotifierProvider);
    final anyLayerVisible = allLayers.values.any((isVisible) => isVisible);

    if (ref.read(pointsOfInterestMasterToggleProvider) != anyLayerVisible) {
      ref.read(pointsOfInterestMasterToggleProvider.notifier).toggle(anyLayerVisible);
    }

    // Apply changes to map if possible
    final mapPageNotifier = ref.read(mapPageNotifierProvider.notifier);
    if (mapPageNotifier.mapController != null) {
      final controller = mapPageNotifier.mapController!; // Handle special case for RAV and OSOM Impact layers which need
      // polyline rendering with markers at the start of each line
      if (member.name == "Rav Impacts" || member.name == "OSOM Impacts") {
        return;
      }
      // Handle Road Incidents layer
      else if (member.name == "Road Incidents") {
        return;
      } // Handle standard point layers (stopping places, etc.)
      else {
        // Use standardized layer naming for POI members
        final layerId = LayerNamingUtility.getPoiMemberLayerId(member.name);

        try {
          debugPrint('Setting POI layer visibility: ${member.name} -> $value');
          debugPrint('Using standardized layer ID: $layerId');

          // Simply toggle visibility of the pre-loaded layer
          await controller.setLayerVisibility(layerId, value);

          debugPrint('✅ POI layer visibility updated: ${member.name} = $value');
        } catch (e) {
          debugPrint('❌ Error updating POI layer visibility: $e');
          debugPrint('   Layer ID: $layerId');
          debugPrint('   Member: ${member.name}');
        }
      }
    } else {
      debugPrint('Map controller not available yet');
    }
  }

}
