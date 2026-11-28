/* import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';

import '../feature_display_helpers.dart';

/// Road without conditions display builder
class RoadWithoutConditionsDisplayBuilder {
  /// Build road without conditions display
  static Widget buildRoadWithoutConditionsDisplay(BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Road Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.route,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Road Information',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Basic Road Information
          Text('Basic Information', style: textTheme.bodyMedium),
          if (properties['ROAD'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road', properties['ROAD']),
          if (properties['ROAD_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road Name', properties['ROAD_NAME']),
          if (properties['COMMON_USAGE_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Common Name', properties['COMMON_USAGE_NAME']),
          if (properties['START_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Start SLK', properties['START_SLK'].toString()),
          if (properties['END_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'End SLK', properties['END_SLK'].toString()),
          if (properties['START_TRUE_DIST'] != null) FeatureDisplayHelpers.buildProperty(context, 'Start Distance', '${properties['START_TRUE_DIST']}km'),
          if (properties['END_TRUE_DIST'] != null) FeatureDisplayHelpers.buildProperty(context, 'End Distance', '${properties['END_TRUE_DIST']}km'),

          if (properties['NETWORK_TYPE'] != null || properties['LG_NAME'] != null) customDivider,

          // Network and Administrative Information
          if (properties['NETWORK_TYPE'] != null || properties['LG_NAME'] != null) Text('Network Information', style: textTheme.bodyMedium),
          if (properties['NETWORK_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network Type', properties['NETWORK_TYPE']),
          if (properties['LG_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Local Government', properties['LG_NAME']),
          if (properties['ACCESS_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Access Type', properties['ACCESS_TYPE']),
          if (properties['NETWORK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network', properties['NETWORK']),

          if (properties['FROM_INTERSECTION'] != null || properties['TO_INTERSECTION'] != null) customDivider,

          // Intersection Information
          if (properties['FROM_INTERSECTION'] != null || properties['TO_INTERSECTION'] != null) Text('Intersection Points', style: textTheme.bodyMedium),
          if (properties['FROM_INTERSECTION'] != null) FeatureDisplayHelpers.buildProperty(context, 'From Intersection', properties['FROM_INTERSECTION']),
          if (properties['TO_INTERSECTION'] != null) FeatureDisplayHelpers.buildProperty(context, 'To Intersection', properties['TO_INTERSECTION']),

          if (properties['MAX_SPEED'] != null || properties['CURFEW'] != null) customDivider,

          // Speed and Time Information
          if (properties['MAX_SPEED'] != null || properties['CURFEW'] != null) Text('Speed & Time Information', style: textTheme.bodyMedium),
          if (properties['MAX_SPEED'] != null) FeatureDisplayHelpers.buildProperty(context, 'Maximum Speed', properties['MAX_SPEED']),
          if (properties['CURFEW'] != null) FeatureDisplayHelpers.buildProperty(context, 'Curfew', properties['CURFEW']),
          if (properties['COMMENTS'] != null) FeatureDisplayHelpers.buildProperty(context, 'Comments', properties['COMMENTS']),

          // Status Indicator
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Road is clear with no reported conditions',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
 */
