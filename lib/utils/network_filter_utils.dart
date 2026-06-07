import 'package:flutter/material.dart';

import '../models/menu_assets.riverpod.dart';

/// ROAD NETWORK FILTER UTILITY
/// Enhanced filtering logic that provides:
/// 1. Support for multiple simultaneous active filters
/// 2. Special handling for AMMS filter combinations with drive types
/// 3. Conditional visibility based on filter combinations
/// 4. Helper methods for getting filter subsets (base filters vs AMMS filters)
/// 5. String-based filtering fallback for networks without explicit filter tags
///
/// Utility class to handle network filtering in the road networks menu
class NetworkFilterUtils {
  /// Check if a network should be shown based on the selected filters
  static bool shouldShowNetwork(String networkName, Set<Filter> filters, {List<Filter>? layerFilters}) {
    // If no filters are selected, show all networks
    if (filters.isEmpty) {
      // Removed excessive logging - only log summary when filters change
      return true;
    } // Reduced debug logging - only log when filters are actually applied
    if (layerFilters != null) {
      // Only log for debugging when needed
      // debugPrint("🏷️ Network has layer filters: ${layerFilters.map((f) => filterValues.reverse[f]).toList()}");
    }

    // If layer filters are provided, check if they contain any of the selected filters
    if (layerFilters != null && layerFilters.isNotEmpty) {
      // Special handling for AMMS filters
      final hasAmmsFilter = filters.contains(Filter.ammsLevel1) || filters.contains(Filter.ammsLevel2) || filters.contains(Filter.ammsLevel3);

      final hasDriveFilter = filters.contains(Filter.tandemDrive) || filters.contains(Filter.triDrive);

      if (hasAmmsFilter && hasDriveFilter) {
        // Must match both an AMMS level AND the drive type
        bool matchesAmms = false;
        bool matchesDrive = false; // Debug
        // debugPrint("🔄 AMMS+Drive combo filter active for network: $networkName");

        // Check if ANY selected AMMS filter matches the layer filters
        for (final filter in filters) {
          if (filter == Filter.ammsLevel1 || filter == Filter.ammsLevel2 || filter == Filter.ammsLevel3) {
            if (layerFilters.contains(filter)) {
              matchesAmms = true;
              // debugPrint("✅ Network matches AMMS filter: ${filterValues.reverse[filter]}");
              break;
            }
          }
        }

        // Check if ANY selected drive filter matches the layer filters
        for (final filter in filters) {
          if (filter == Filter.tandemDrive || filter == Filter.triDrive) {
            if (layerFilters.contains(filter)) {
              matchesDrive = true;
              debugPrint("✅ Network matches drive filter: ${filterValues.reverse[filter]}");
              break;
            }
          }
        }

        // Debug
        if (matchesAmms && matchesDrive) {
          debugPrint("✅ SHOWING network with both AMMS and Drive filters: $networkName");
        } else {
          debugPrint("❌ HIDING network (AMMS match: $matchesAmms, Drive match: $matchesDrive): $networkName");
        }

        return matchesAmms && matchesDrive;
      } else {
        // Normal filter mode - match if any filter matches
        for (final filter in filters) {
          if (layerFilters.contains(filter)) {
            debugPrint("✅ SHOWING network with matching filter ${filterValues.reverse[filter]}: $networkName");
            return true;
          }
        }
        debugPrint("❌ HIDING network (no matching filters): $networkName");
        return false;
      }
    } // Legacy fallback method based on string matching
    // Special handling for AMMS filters when combined with drive type filters
    final hasAmmsFilter = filters.any((f) => f == Filter.ammsLevel1 || f == Filter.ammsLevel2 || f == Filter.ammsLevel3);
    final hasDriveFilter = filters.any((f) => f == Filter.tandemDrive || f == Filter.triDrive);

    // If we have both AMMS and drive filters, handle the combination specifically
    if (hasAmmsFilter && hasDriveFilter) {
      final networkNameLower = networkName.toLowerCase();
      bool matchesAmms = false; // Check if network matches any AMMS filter
      if (filters.contains(Filter.ammsLevel1) &&
          ((networkNameLower.contains('amms') && networkNameLower.contains('level 1')) || (networkNameLower.contains('concessional') && networkNameLower.contains('level 1')))) {
        matchesAmms = true;
      } else if (filters.contains(Filter.ammsLevel2) &&
          ((networkNameLower.contains('amms') && networkNameLower.contains('level 2')) || (networkNameLower.contains('concessional') && networkNameLower.contains('level 2')))) {
        matchesAmms = true;
      } else if (filters.contains(Filter.ammsLevel3) &&
          ((networkNameLower.contains('amms') && networkNameLower.contains('level 3')) || (networkNameLower.contains('concessional') && networkNameLower.contains('level 3')))) {
        matchesAmms = true;
      }

      // If network matches an AMMS filter, check if it also matches drive type
      if (matchesAmms) {
        bool driveMatch = _networkMatchesDriveFilters(networkName, filters);
        if (driveMatch) {
          debugPrint("String matching found combo for: $networkName");
        }
        return driveMatch;
      }

      // If network doesn't match AMMS filters, it shouldn't be shown in this combo mode
      return false;
    }

    // Standard single filter handling
    for (final filter in filters) {
      // Match network name with filter
      switch (filter) {
        case Filter.agricultural:
          if (networkName.toLowerCase().contains('agriculture') || networkName.toLowerCase().contains('agricultural')) {
            return true;
          }
        case Filter.ammsLevel1:
          if ((networkName.toLowerCase().contains('amms') && networkName.toLowerCase().contains('level 1')) ||
              (networkName.toLowerCase().contains('concessional') && networkName.toLowerCase().contains('level 1'))) {
            // If we have drive filters selected, must match both AMMS and drive
            if (hasDriveFilter) {
              return _networkMatchesDriveFilters(networkName, filters);
            }
            // If only AMMS filter is selected, show the network
            return true;
          }
        case Filter.ammsLevel2:
          if ((networkName.toLowerCase().contains('amms') && networkName.toLowerCase().contains('level 2')) ||
              (networkName.toLowerCase().contains('concessional') && networkName.toLowerCase().contains('level 2'))) {
            // If we have drive filters selected, must match both AMMS and drive
            if (hasDriveFilter) {
              return _networkMatchesDriveFilters(networkName, filters);
            }
            // If only AMMS filter is selected, show the network
            return true;
          }
        case Filter.ammsLevel3:
          if ((networkName.toLowerCase().contains('amms') && networkName.toLowerCase().contains('level 3')) ||
              (networkName.toLowerCase().contains('concessional') && networkName.toLowerCase().contains('level 3'))) {
            // If we have drive filters selected, must match both AMMS and drive
            if (hasDriveFilter) {
              return _networkMatchesDriveFilters(networkName, filters);
            }
            // If only AMMS filter is selected, show the network
            return true;
          }
        case Filter.oversizeOvermass:
          if (networkName.toLowerCase().contains('oversize') || networkName.toLowerCase().contains('overmass')) {
            return true;
          }
        case Filter.restArea:
          if (networkName.toLowerCase().contains('rest area') || networkName.toLowerCase().contains('rest stop')) {
            return true;
          }
        case Filter.spv:
          if (networkName.toLowerCase().contains('spv') || networkName.toLowerCase().contains('special purpose vehicle')) {
            return true;
          }
        case Filter.tandemDrive:
          // For tandem drive, don't filter out networks if there's an AMMS filter
          // This allows networks to show when both Tandem Drive and AMMS are selected
          final networkNameLower = networkName.toLowerCase();
          if (networkNameLower.contains('tandem drive') || networkNameLower.contains('tandem') || networkNameLower.startsWith('tandem')) {
            return true;
          }
        case Filter.travelImpact:
          if (networkName.toLowerCase().contains('travel impact') || networkName.toLowerCase().contains('impact')) {
            return true;
          }
        case Filter.triDrive:
          // For tri drive, don't filter out networks if there's an AMMS filter
          // This allows networks to show when both Tri Drive and AMMS are selected
          final networkNameLower = networkName.toLowerCase();
          if (networkNameLower.contains('tri drive') || networkNameLower.contains('tri-drive') || networkNameLower.startsWith('tri')) {
            return true;
          }
        default:
          continue;
      }
    }

    return false;
  }

  /// Helper to check if filters contain an AMMS filter
  static bool _hasAmmsFilter(Set<Filter> filters) {
    return filters.contains(Filter.ammsLevel1) || filters.contains(Filter.ammsLevel2) || filters.contains(Filter.ammsLevel3);
  }

  /// Helper to check if network matches drive filters (for AMMS)
  static bool _networkMatchesDriveFilters(String networkName, Set<Filter> filters) {
    final networkNameLower = networkName.toLowerCase();

    // Check if network name matches any active drive filter
    if (filters.contains(Filter.tandemDrive)) {
      // Look for "tandem drive" or "tandem" in the network name
      if (networkNameLower.contains('tandem drive') || networkNameLower.contains('tandem') || networkNameLower.startsWith('tandem')) {
        return true;
      }
    }

    if (filters.contains(Filter.triDrive)) {
      // Look for "tri drive", "tri-drive" or "tri" in the network name
      if (networkNameLower.contains('tri drive') ||
          networkNameLower.contains('tri-drive') ||
          networkNameLower.startsWith('tri') ||
          (networkNameLower.contains(' tri ') && !networkNameLower.contains('tandem'))) {
        return true;
      }
    }

    return false;
  }

  /// Overload for backward compatibility with single filter - we need a different name to avoid conflict
  static bool shouldShowNetworkWithSingleFilter(String networkName, Filter? filter, {List<Filter>? layerFilters}) {
    if (filter == null) {
      return shouldShowNetwork(networkName, {}, layerFilters: layerFilters);
    } else {
      return shouldShowNetwork(networkName, {filter}, layerFilters: layerFilters);
    }
  }

  /// Get human-readable filter label
  static String getFilterLabel(Filter? filter) {
    if (filter == null) {
      return 'All Networks';
    }
    return filterValues.reverse[filter] ?? 'Unknown';
  }

  /// Get all base filters excluding AMMS filters, "All Networks", "Rest Area", and "Travel Impact"
  static List<Filter> getBaseFilters() {
    return filterValues.map.values
        .where((f) => f != Filter.empty && f != Filter.restArea && f != Filter.travelImpact && f != Filter.ammsLevel1 && f != Filter.ammsLevel2 && f != Filter.ammsLevel3)
        .toList();
  }

  /// Get just the AMMS filters
  static List<Filter> getAmmsFilters() {
    return [
      Filter.ammsLevel1,
      Filter.ammsLevel2,
      Filter.ammsLevel3,
    ];
  }

  /// Get all available filters excluding "All Networks", "Rest Area", and "Travel Impact"
  static List<Filter> getAllFilters() {
    return filterValues.map.values.where((f) => f != Filter.empty && f != Filter.restArea && f != Filter.travelImpact).toList();
  }

  /// Get display name for filter with special handling for null filter
  static String getDisplayName(Filter? filter) {
    if (filter == null) {
      return "All Networks";
    }

    // Special handling for AMMS filters to show "AMMS Level X" in the UI
    switch (filter) {
      case Filter.ammsLevel1:
        return "AMMS Level 1";
      case Filter.ammsLevel2:
        return "AMMS Level 2";
      case Filter.ammsLevel3:
        return "AMMS Level 3";
      case Filter.oversizeOvermass:
        return "OSOM";
      default:
        return filterValues.reverse[filter] ?? "Unknown";
    }
  }
}
