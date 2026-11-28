import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';

import '../feature_display_helpers.dart';

/// Travel impact display builder
class TravelImpactDisplayBuilder {
  /// Build travel impact display
  static Widget buildTravelImpactDisplay(
      BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    // Convert dates from timestamps
    String commencementDate = "N/A";
    String endDate = "N/A";

    if (properties['CommencementDate'] != null) {
      // Convert to int safely from either double or int
      final timestamp = properties['CommencementDate'] is double
          ? (properties['CommencementDate'] as double).toInt()
          : properties['CommencementDate'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      commencementDate = "${date.day}/${date.month}/${date.year}";
    }

    if (properties['EndDate'] != null) {
      // Convert to int safely from either double or int
      final timestamp = properties['EndDate'] is double
          ? (properties['EndDate'] as double).toInt()
          : properties['EndDate'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      endDate = "${date.day}/${date.month}/${date.year}";
    }

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Travel Impact Header
          FeatureDisplayHelpers.buildSubTitle(
            context,
            title,
          ),
          /* Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: colorScheme.onErrorContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Travel Impact',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ), */
          const SizedBox(height: 16),

          // Impact Details
          Text('Impact Details', style: textTheme.bodyMedium),
          if (properties['Description'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Description', properties['Description']),
          if (properties['Type'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Type', properties['Type']),
          if (properties['Severity'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Severity', properties['Severity']),

          customDivider,

          // Duration Information
          Text('Duration', style: textTheme.bodyMedium),
          FeatureDisplayHelpers.buildProperty(
              context, 'Start Date', commencementDate),
          FeatureDisplayHelpers.buildProperty(context, 'End Date', endDate),

          if (properties['Location'] != null ||
              properties['AffectedRoads'] != null)
            customDivider,

          // Location Information
          if (properties['Location'] != null ||
              properties['AffectedRoads'] != null)
            Text('Location Information', style: textTheme.bodyMedium),
          if (properties['Location'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Location', properties['Location']),
          if (properties['AffectedRoads'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Affected Roads', properties['AffectedRoads']),
        ],
      );
    });
  }
}
