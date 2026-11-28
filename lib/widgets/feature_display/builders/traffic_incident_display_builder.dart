import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';

import '../feature_display_helpers.dart';

/// Traffic incident display builder
class TrafficIncidentDisplayBuilder {
  /// Build traffic incident display
  static Widget buildTrafficIncidentDisplay(
      BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    // final colorScheme = Theme.of(context).colorScheme;

    // Handle field name variations (case and field name can vary)
    String location = properties['Location'] ?? properties['LOCATION'] ?? '';
    final String incidentType =
        properties['IncidentTy'] ?? properties['IncidentType'] ?? '';
    final String trafficCondition =
        properties['TrafficCon'] ?? properties['TrafficCondition'] ?? '';
    final String trafficImpact =
        properties['TrafficImp'] ?? properties['TrafficImpact'] ?? '';
    final String road = properties['Road'] ?? '';
    final String region = properties['Region'] ?? '';
    final String suburb = properties['Suburb'] ?? '';
    final String localRoadName = properties['LocalRoadName'] ?? '';
    final String entryDate = properties['EntryDate'] ?? '';
    final String updateDate = properties['UpdateDate'] ?? '';

    // Clean up the location string by removing incident type if it's at the end
    if (location.isNotEmpty && incidentType.isNotEmpty) {
      if (location.endsWith(incidentType)) {
        location =
            location.substring(0, location.length - incidentType.length).trim();
        if (location.endsWith(' -')) {
          location = location.substring(0, location.length - 2).trim();
        }
      }
    }

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Traffic Incident Header
          FeatureDisplayHelpers.buildSubTitle(
            context,
            title,
          ),
          /*  Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.traffic,
                  color: colorScheme.onErrorContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Traffic Incident',
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

          // Incident Details
          Text('Incident Details', style: textTheme.bodyMedium),
          if (incidentType.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(context, 'Type', incidentType),
          if (trafficCondition.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(
                context, 'Traffic Condition', trafficCondition),
          if (trafficImpact.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(
                context, 'Impact', trafficImpact),

          customDivider,

          // Location Information
          Text('Location Information', style: textTheme.bodyMedium),
          if (location.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(context, 'Location', location),
          if (road.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(context, 'Road', road),
          if (localRoadName.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(
                context, 'Local Road', localRoadName),
          if (suburb.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(context, 'Suburb/Town', suburb),
          if (region.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(context, 'Region', region),

          if (entryDate.isNotEmpty || updateDate.isNotEmpty) customDivider,

          // Time Information
          if (entryDate.isNotEmpty || updateDate.isNotEmpty)
            Text('Time Information', style: textTheme.bodyMedium),
          if (entryDate.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(context, 'Reported', entryDate),
          if (updateDate.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(
                context, 'Last Updated', updateDate),
        ],
      );
    });
  }
}
