import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';

import '../feature_display_helpers.dart';

/// Road train assembly display builder
class RoadTrainAssemblyDisplayBuilder {
  /// Build road train assembly display
  static Widget buildRoadTrainAssemblyDisplay(
      BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Road Train Assembly Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: colorScheme.onSecondaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Road Train Assembly Area',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Assembly Area Name and Identification
          if (properties['RA_NAME'] != null)
            FeatureDisplayHelpers.buildSubTitle(context, properties['RA_NAME']),
          if (properties['RA_NO'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Assembly Area Number', properties['RA_NO']),

          customDivider,

          // Location Information
          Text('Location Information', style: textTheme.bodyMedium),
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

          // Infrastructure Type Information
          Text('Infrastructure Information', style: textTheme.bodyMedium),
          if (properties['IIT_TYPE'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Infrastructure Type', properties['IIT_TYPE']),
          if (properties['IIT_DESC'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Description', properties['IIT_DESC']),

          customDivider,

          // Available Facilities
          Text('Available Facilities', style: textTheme.bodyMedium),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (properties['BIN'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(context, 'Bins', true),
              if (properties['IIT_TABLE'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Tables', true),
              if (properties['BBQ'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(context, 'BBQ', true),
              if (properties['TOILET'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Toilets', true),
              if (properties['WATER'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(context, 'Water', true),
              if (properties['TELEPHONE'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Telephone', true),
              if (properties['SHELTER'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Shelter', true),
              if (properties['DISABLED'] == 'Yes')
                FeatureDisplayHelpers.buildFacilityChip(
                    context, 'Disabled Access', true),
            ],
          ),

          if (properties['SIGN_PRESENT'] != null ||
              properties['PHONE_SIGNAL'] != null)
            customDivider,

          // Additional Information
          if (properties['SIGN_PRESENT'] != null ||
              properties['PHONE_SIGNAL'] != null)
            Text('Additional Information', style: textTheme.bodyMedium),
          if (properties['SIGN_PRESENT'] == 'Yes')
            FeatureDisplayHelpers.buildProperty(
                context, 'Signage Present', 'Yes'),
          if (properties['PHONE_SIGNAL'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Phone Signal', properties['PHONE_SIGNAL']),
          if (properties['NETWORK_TYPE'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Network Type', properties['NETWORK_TYPE']),

          // Important Notice
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Road train assembly areas are designated for coupling/uncoupling trailers. Check local regulations before use.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
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
