import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/menu_assets.riverpod.dart';
import '../../utils/network_filter_utils.dart';

/// ROAD NETWORK FILTER SYSTEM
/// This enhanced filter system provides:
/// 1. Streamlined filter selection - only shows selected filter to save space
/// 2. Conditional display of AMMS filters only when a drive type (Tandem/Tri) is selected
/// 3. Special combined filtering for AMMS + drive type selections
/// 4. Category headers that hide when no child items match the selected filters

/// Provider to manage road network filter selection
final roadNetworkFilterProvider = StateNotifierProvider<RoadNetworkFilterNotifier, Set<Filter>>((ref) {
  return RoadNetworkFilterNotifier();
});

/// Notifier to manage road network filter state with support for multiple filters
class RoadNetworkFilterNotifier extends StateNotifier<Set<Filter>> {
  RoadNetworkFilterNotifier() : super({}); // Empty set means show all networks  /// Toggle a filter on/off
  void toggleFilter(Filter filter) {
    if (state.contains(filter)) {
      // Create a new state without the toggled filter
      final newState = {...state}..remove(filter);

      // Check if we're removing a drive filter (Tandem or Tri Drive)
      final isDriveFilter = filter == Filter.tandemDrive || filter == Filter.triDrive;

      // Check if we're removing an AMMS filter
      final isAmmsFilter = filter == Filter.ammsLevel1 || filter == Filter.ammsLevel2 || filter == Filter.ammsLevel3;

      // Check if there are AMMS filters in the state
      final hasAmmsFilter = newState.any((f) => f == Filter.ammsLevel1 || f == Filter.ammsLevel2 || f == Filter.ammsLevel3);

      // Check if there are drive filters in the state
      final hasDriveFilter = newState.any((f) => f == Filter.tandemDrive || f == Filter.triDrive);

      // If we're removing a drive filter and have AMMS filters, remove all filters
      if (isDriveFilter && hasAmmsFilter) {
        // Clear all filters instead of switching to another drive type
        state = {}; // Empty set means show all networks
        return;
      }

      // If we're removing the last AMMS filter and have a drive filter, remove all filters
      if (isAmmsFilter && !hasAmmsFilter && hasDriveFilter) {
        // Clear all filters
        state = {};
        return;
      }

      state = newState;
    } else {
      // Add filter and handle special cases
      final newState = {...state, filter};

      // Check if it's an AMMS filter
      final isAmmsFilter = filter == Filter.ammsLevel1 || filter == Filter.ammsLevel2 || filter == Filter.ammsLevel3;

      // If it's an AMMS filter, make sure we have a drive type
      if (isAmmsFilter) {
        // If no drive type is selected, add Tandem Drive by default
        if (!newState.contains(Filter.tandemDrive) && !newState.contains(Filter.triDrive)) {
          newState.add(Filter.tandemDrive);
        }
      }

      // If selecting a drive type, and another drive type is already selected
      // replace it to avoid having both Tandem and Tri drive selected at once
      if ((filter == Filter.tandemDrive && newState.contains(Filter.triDrive)) || (filter == Filter.triDrive && newState.contains(Filter.tandemDrive))) {
        newState.remove(filter == Filter.tandemDrive ? Filter.triDrive : Filter.tandemDrive);
      }
      state = newState;
    }
  }

  /// Check if any filters are active
  bool get hasActiveFilters => state.isNotEmpty;

  /// Get the active drive filter (Tandem or Tri)
  Filter? get activeDriveFilter => state.contains(Filter.tandemDrive)
      ? Filter.tandemDrive
      : state.contains(Filter.triDrive)
          ? Filter.triDrive
          : null;
}

/// Widget to display filter buttons at the top of the road networks menu
class RoadNetworkFilterButtons extends ConsumerWidget {
  const RoadNetworkFilterButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the current filter state
    final selectedFilters = ref.watch(roadNetworkFilterProvider);

    // Get base filters (non-AMMS)
    final baseFilters = NetworkFilterUtils.getBaseFilters();

    // Check if we should show AMMS filters
    final showAmmsFilters = selectedFilters.contains(Filter.tandemDrive) || selectedFilters.contains(Filter.triDrive);

    // Get AMMS filters if needed
    final ammsFilters = showAmmsFilters ? NetworkFilterUtils.getAmmsFilters() : <Filter>[];

    // Check if we have any non-AMMS filters selected
    final hasSelectedBaseFilter = baseFilters.any((filter) => selectedFilters.contains(filter));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Base filter chips - either show all filters when nothing is selected,
        // or show only the selected filter when one is picked
        Wrap(
          spacing: 4,
          alignment: WrapAlignment.center,
          children: baseFilters.where((filter) => !hasSelectedBaseFilter || selectedFilters.contains(filter)).map((filter) {
            return _buildFilterChip(context, ref, filter, selectedFilters);
          }).toList(),
        ),

        // AMMS filters (only shown when Tandem/Tri Drive is selected)
        if (showAmmsFilters) ...[
          /* const SizedBox(height: 2), */
          Wrap(
            spacing: 4,
            alignment: WrapAlignment.center,
            children: ammsFilters.map((filter) {
              return _buildFilterChip(context, ref, filter, selectedFilters);
            }).toList(),
          ),
        ],
      ],
    );
  }

  // Build individual filter chip
  Widget _buildFilterChip(BuildContext context, WidgetRef ref, Filter filter, Set<Filter> selectedFilters) {
    final isSelected = selectedFilters.contains(filter);

    // Check if this filter is an AMMS filter
    final isAmmsFilter = filter == Filter.ammsLevel1 || filter == Filter.ammsLevel2 || filter == Filter.ammsLevel3;

    // Check if this filter is a drive type filter
    final isDriveFilter = filter == Filter.tandemDrive || filter == Filter.triDrive;

    // Style differently to highlight combinations
    final hasAmmsSelected = selectedFilters.any((f) => f == Filter.ammsLevel1 || f == Filter.ammsLevel2 || f == Filter.ammsLevel3);
    final hasDriveSelected = selectedFilters.any((f) => f == Filter.tandemDrive || f == Filter.triDrive);

    // Enhanced styling for combination filters
    Color? chipColor = isSelected ? Theme.of(context).colorScheme.secondaryContainer : null;

    // Highlight drive filters when AMMS is selected and vice versa
    if (isSelected && ((isDriveFilter && hasAmmsSelected) || (isAmmsFilter && hasDriveSelected))) {
      chipColor = Theme.of(context).colorScheme.secondaryContainer;
    }

    return FilterChip(
      label: Text(NetworkFilterUtils.getDisplayName(filter)),
      selected: isSelected,
      visualDensity: VisualDensity.compact,
      onSelected: (selected) {
        ref.read(roadNetworkFilterProvider.notifier).toggleFilter(filter);
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: chipColor,
      checkmarkColor: Theme.of(context).colorScheme.primary,
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,
        width: 1.0,
      ),
      // Add tooltip for AMMS filters explaining they require a drive type
      tooltip: isAmmsFilter ? 'Requires selecting either Tandem Drive or Tri Drive' : null,
    );
  }
}
