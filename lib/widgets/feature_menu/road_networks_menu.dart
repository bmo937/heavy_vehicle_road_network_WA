/// ROAD NETWORK MENU WITH ENHANCED FILTERING
/// This menu provides an improved filtering experience:
/// 1. Category headers only display when their children match the current filters
/// 2. Group headers only show when at least one network in the group is visible
/// 3. Proper handling of combined AMMS + drive type filters
/// 4. Responsive layout for different screen sizes
/// 5. Clear visual feedback on filter state
library;

import 'package:roads_map/hive_boxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';
import 'package:roads_map/models/menu_helpers.dart';
import 'package:roads_map/providers/network_selection_provider.riverpod.dart';
import 'package:roads_map/utils/network_filter_utils.dart';
import 'package:roads_map/widgets/feature_menu/road_network_filter_buttons.dart';
import 'package:roads_map/widgets/navigation_widget/navigation_widget.dart';

/// Updated RoadNetworksMenu with filter buttons and improved layer handling
class RoadNetworksMenu extends ConsumerWidget {
  const RoadNetworksMenu({super.key, required this.menuAssets, this.showOnlyDownloaded = false});

  final MenuAssets menuAssets;
  final bool showOnlyDownloaded;

  // Constants for Hive storage
  static const String roadNetworksBoxName = HiveBoxes.roadNetworks;
  static const String visibilityKey = 'layer_visibility';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current filters
    final selectedFilters = ref.watch(roadNetworkFilterProvider);

    // Filter for Road Network layers
    final roadNetworkLayers = menuAssets.layers.where((layer) => layer.listMenu == ListMenu.roadNetworks).toList();

    // Group networks by their category for organization
    final networksByCategory = _groupNetworksByCategory(roadNetworkLayers);

    // Get currently selected network
    final selectedNetwork = ref.watch(networkLayerSelectionProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight.isFinite) {
          // Reduced logging - only log when debugging layout issues
          // debugPrint('Using Column for finite height');
          // If we have a finite height, use Column for better performance
          // and to avoid unnecessary scrolling
          _debugPrintFilterState(selectedFilters); // Debugging filter state
          // Show the filter buttons and networks list
          // Only log when there are significant changes
          // debugPrint('Building RoadNetworksMenu with ${networksByCategory.length} categories and ${roadNetworkLayers.length} total layers');
          return Column(
            children: [
              // Filter buttons at the top
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: RoadNetworkFilterButtons(),
              ),
              const Divider(height: 1, thickness: 1),
              // Networks list
              Expanded(
                child: roadNetworkLayers.isEmpty
                    ? const Center(child: Text('No road networks available'))
                    : _buildNetworksList(context, ref, networksByCategory, selectedFilters, selectedNetwork),
              ),
            ],
          );
        } else {
          // Reduced logging - only log when debugging layout issues
          // debugPrint('Using SingleChildScrollView for infinite height');
          // If we have infinite height, use SingleChildScrollView for scrolling
          _debugPrintFilterState(selectedFilters); // Debugging filter state
          // Show the filter buttons and networks list
          // Only log when there are significant changes
          // debugPrint('Building RoadNetworksMenu with ${networksByCategory.length} categories and ${roadNetworkLayers.length} total layers');
          // Wrap the entire content in a SingleChildScrollView
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter buttons at the top
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: RoadNetworkFilterButtons(),
                ),
                const Divider(height: 1, thickness: 1),
                // Networks list
                if (roadNetworkLayers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No road networks available'),
                  ),
                // Each category section
                for (final entry in networksByCategory.entries) _buildCategorySection(context, ref, entry.key, entry.value, selectedFilters, selectedNetwork),
              ],
            ),
          );
        }
      },
    );
  }

  // Group networks by filter type
  Map<String, List<Layer>> _groupNetworksByCategory(List<Layer> layers) {
    final result = <String, List<Layer>>{};

    for (final layer in layers) {
      // Default to 'Other' if no filters or empty filter
      String category = 'Other';

      // Use the first filter that's not empty as the category, if any
      if (layer.filters.isNotEmpty) {
        final firstFilter = layer.filters.first;
        if (firstFilter != Filter.empty) {
          category = filterValues.reverse[firstFilter] ?? 'Other';
        }
      }

      result.putIfAbsent(category, () => []);
      result[category]!.add(layer);
    }

    return result;
  }

  // Build a scrollable list of networks
  Widget _buildNetworksList(BuildContext context, WidgetRef ref, Map<String, List<Layer>> networksByCategory, Set<Filter> filters, String? selectedNetwork) {
    // If no filters are selected, show everything
    final bool filtersActive = filters.isNotEmpty;

    return CustomScrollView(
      slivers: [
        for (final entry in networksByCategory.entries) ...[
          // First check if any items in this category will be visible with the current filter
          if (!filtersActive || _anyCategoryItemsVisible(entry.value, filters)) ...[
            // Category title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            // Networks in this category
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildNetworkItem(context, ref, entry.value[index], filters, selectedNetwork);
                },
                childCount: entry.value.length,
              ),
            ),
          ],
        ],
      ],
    );
  }

  // Build a category section
  Widget _buildCategorySection(BuildContext context, WidgetRef ref, String category, List<Layer> layers, Set<Filter> filters, String? selectedNetwork) {
    // If filters are active and no items in this category match the filter, return empty container
    if (filters.isNotEmpty && !_anyCategoryItemsVisible(layers, filters)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(category, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final layer in layers) _buildNetworkItem(context, ref, layer, filters, selectedNetwork),
      ],
    );
  }

  // Build a network item with its group members
  Widget _buildNetworkItem(BuildContext context, WidgetRef ref, Layer layer, Set<Filter> filters, String? selectedNetwork) {
    // Skip if this layer has no group members
    if (layer.groupMembers == null || layer.groupMembers!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter members based on current filters
    final filteredMembers = layer.groupMembers!
        .where((member) => NetworkFilterUtils.shouldShowNetwork(
              member.name,
              filters,
              layerFilters: member.filters,
            ))
        .toList();

    // Skip if no members match the filter - hide the entire item including its header
    if (filteredMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (layer.groupLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(layer.groupLabel!, style: Theme.of(context).textTheme.titleSmall),
          ),
        for (final member in filteredMembers) _buildNetworkRadioTile(context, ref, member, selectedNetwork),
      ],
    );
  }

  // Build a radio tile for a network
  Widget _buildNetworkRadioTile(BuildContext context, WidgetRef ref, GroupMember member, String? selectedNetwork) {
    final boxController = ref.watch(boxControllerProvider);
    return Card(
      elevation: 0,
      child: RadioGroup<String>(
        groupValue: selectedNetwork,
        onChanged: (value) {
          if (value != null) {
            _selectNetwork(context, ref, member, value);
            boxController.closeBox();
          }
        },
        child: RadioListTile<String>(
          title: Text(member.name),
          value: member.name,
        ),
      ),
    );
  }

  // Handle network selection
  void _selectNetwork(BuildContext context, WidgetRef ref, GroupMember network, String value) {
    final controller = ref.read(boxControllerProvider);
    debugPrint('\n🎯 === Network Selection Started ===');
    debugPrint('🏗️ Selected network: ${network.name} (value: $value)');

    // Update both network selection providers for compatibility
    debugPrint('🔄 Updating networkLayerSelectionProvider...');
    ref.read(networkLayerSelectionProvider.notifier).selectLayer(value);

    debugPrint('🔄 Updating roadNetworkSelectionNotifierProvider...');
    ref.read(roadNetworkSelectionNotifierProvider.notifier).selectNetwork(value);

    // Save to Hive
    debugPrint('💾 Saving to Hive...');
    Hive.openBox(roadNetworksBoxName).then((box) {
      box.put(visibilityKey, value);
      debugPrint('✅ Saved to Hive: $visibilityKey = $value');
    });

    // Note: Layer updates now happen automatically via MapPage listeners
    // No need to manually call onCameraIdle anymore
    debugPrint('⏳ Waiting for MapPage listeners to trigger layer update...');
    if (controller.isBoxOpen) {
      controller.closeBox();
    }
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected network: ${network.name}')),
    );
  }

  // Helper method to check if any items in a category will be visible with current filters
  bool _anyCategoryItemsVisible(List<Layer> layers, Set<Filter> filters) {
    // If no filters are active, all categories are visible
    if (filters.isEmpty) {
      return true;
    }

    // Check each layer in the category
    for (final layer in layers) {
      // Skip if this layer has no group members
      if (layer.groupMembers == null || layer.groupMembers!.isEmpty) {
        continue;
      }

      // Check if any members in this layer match the filter
      final hasVisibleMembers = layer.groupMembers!.any((member) {
        // Use the utility function to determine if this network should show
        final shouldShow = NetworkFilterUtils.shouldShowNetwork(
          member.name,
          filters,
          layerFilters: member.filters,
        );

        return shouldShow;
      });

      // If at least one member is visible, the category is visible
      if (hasVisibleMembers) {
        return true;
      }
    }

    // If we get here, no items in this category are visible with the current filters
    return false;
  }

  // Debug helper to print current filter state - reduced logging to prevent spam
  void _debugPrintFilterState(Set<Filter> filters) {
    // Only log filter state changes when debugging is specifically needed
    // Commenting out to reduce log noise
    /*
    if (filters.isEmpty) {
      debugPrint('Filters: None (showing all networks)');
      return;
    }

    final filterNames = filters.map((f) => NetworkFilterUtils.getDisplayName(f)).join(', ');
    debugPrint('Active filters: $filterNames');

    final hasAmms = filters.any((f) => f == Filter.ammsLevel1 || f == Filter.ammsLevel2 || f == Filter.ammsLevel3);
    final hasDrive = filters.any((f) => f == Filter.tandemDrive || f == Filter.triDrive);

    if (hasAmms && hasDrive) {
      debugPrint('Special AMMS+Drive combination active');
    }
    */
  }
}
