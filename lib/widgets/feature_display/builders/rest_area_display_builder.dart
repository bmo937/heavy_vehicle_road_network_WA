import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';

import '../feature_display_helpers.dart';

/// Rest area display builder
class RestAreaDisplayBuilder {
  /// Build rest area display
  static Widget buildRestAreaDisplay(
      BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rest Area Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_parking,
                  color: colorScheme.onTertiaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rest Area',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Basic Information
          Text('Basic Information', style: textTheme.bodyMedium),
          if (properties['REST_AREA_NAME'] != null)
            FeatureDisplayHelpers.buildSubTitle(
                context, properties['REST_AREA_NAME']),
          if (properties['REST_AREA_TYPE'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Rest Area Type', properties['REST_AREA_TYPE']),
          if (properties['ROAD_NAME'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Road', properties['ROAD_NAME']),
          if (properties['COMMON_USAGE_NAME'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Common Name', properties['COMMON_USAGE_NAME']),
          if (properties['LG_NAME'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Local Government', properties['LG_NAME']),
          if (properties['START_SLK'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Start SLK', properties['START_SLK'].toString()),
          if (properties['END_SLK'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'End SLK', properties['END_SLK'].toString()),
          if (properties['CWY'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Carriageway', properties['CWY']),

          customDivider,

          // Rest Area Features
          Text('Rest Area Features', style: textTheme.bodyMedium),
          if (properties['OWNERSHIP'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Ownership', properties['OWNERSHIP']),
          if (properties['STAY_24_HOUR'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, '24 Hour Stay', properties['STAY_24_HOUR']),
          if (properties['SURFACE_TYPE'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Surface Type', properties['SURFACE_TYPE']),
          if (properties['SURFACE_AREA'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Surface Area', '${properties['SURFACE_AREA']} m²'),

          customDivider,

          // Facilities Available
          Text('Available Facilities', style: textTheme.bodyMedium),
          const SizedBox(height: 8),

          // Facility chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (properties['CONSTRUCTED_SHELTER'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Constructed Shelter', true),
              if (properties['NATURAL_SHADE'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Natural Shade', true),
              if (properties['LIGHTING_PRESENT'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Lighting', true),
              if (properties['INFORMATION_BOARD'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Information Board', true),
              if (properties['SCENIC_LOOKOUT'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Scenic Lookout', true),
              if (properties['EFFLUENT_DUMP_SITE'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Effluent Dump', true),
            ],
          ),

          customDivider,

          // Facilities Count Information
          Text('Facility Details', style: textTheme.bodyMedium),
          if (properties['NUMBER_OF_TOILETS'] != null &&
              properties['NUMBER_OF_TOILETS'] > 0)
            FeatureDisplayHelpers.buildProperty(context, 'Number of Toilets',
                properties['NUMBER_OF_TOILETS'].toString()),
          if (properties['ACCESSIBLE_TOILETS'] == 'Yes')
            FeatureDisplayHelpers.buildProperty(
                context, 'Accessible Toilets', 'Available'),
          if (properties['NUMBER_OF_TABLES'] != null &&
              properties['NUMBER_OF_TABLES'] > 0)
            FeatureDisplayHelpers.buildProperty(context, 'Number of Tables',
                properties['NUMBER_OF_TABLES'].toString()),
          if (properties['ACCESSIBLE_TABLES'] == 'Yes')
            FeatureDisplayHelpers.buildProperty(
                context, 'Accessible Tables', 'Available'),
          if (properties['NUMBER_OF_BINS'] != null &&
              properties['NUMBER_OF_BINS'] > 0)
            FeatureDisplayHelpers.buildProperty(context, 'Number of Bins',
                properties['NUMBER_OF_BINS'].toString()),

          if (properties['COMMEMORATION_WAY'] != null) customDivider,

          // Additional Information
          if (properties['COMMEMORATION_WAY'] != null)
            Text('Additional Information', style: textTheme.bodyMedium),
          if (properties['COMMEMORATION_WAY'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Commemoration Way', properties['COMMEMORATION_WAY']),
          if (properties['NETWORK_TYPE'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Network Type', properties['NETWORK_TYPE']),
        ],
      );
    });
  }
}
