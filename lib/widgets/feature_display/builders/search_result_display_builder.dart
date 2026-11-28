import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';

import '../feature_display_helpers.dart';

/// Search result display builder
class SearchResultDisplayBuilder {
  /// Build search result display
  static Widget buildSearchResultDisplay(
      BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    // final TextTheme textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Result Header
          /* Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: colorScheme.onSurface,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search Result',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), */ // Main Information
          if (properties['name'] != null || properties['NAME'] != null)
            Center(
                child: FeatureDisplayHelpers.buildSubTitle(
                    context, properties['name'] ?? properties['NAME'])),

          customDivider,

          if (properties['formatted_address'] != null)
            FeatureDisplayHelpers.buildSearchProperty(
                context, properties['formatted_address'],
                propertyType: 'formatted_address'),
          if (properties['vicinity'] != null)
            FeatureDisplayHelpers.buildSearchProperty(
                context, properties['vicinity'],
                propertyType: 'vicinity'),
          if (properties['opening_hours'] != null)
            FeatureDisplayHelpers.buildSearchProperty(
                context, properties['opening_hours'],
                propertyType: 'opening_hours'),
          if (properties['formatted_phone_number'] != null)
            FeatureDisplayHelpers.buildSearchProperty(
                context, properties['formatted_phone_number'],
                propertyType: 'formatted_phone_number'),
          if (properties['website'] != null)
            FeatureDisplayHelpers.buildSearchProperty(
                context, properties['website'],
                propertyType: 'website'),
        ],
      );
    });
  }
}
