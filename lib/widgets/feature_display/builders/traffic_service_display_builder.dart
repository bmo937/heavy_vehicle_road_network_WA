import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';

import '../feature_display_helpers.dart';

/// Traffic service display builder
class TrafficServiceDisplayBuilder {
  /// Build traffic service display
  static Widget buildTrafficServiceDisplay(
      BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Extract properties with null checks
    final String location = properties['Location'] ?? '';
    final String incidentType = properties['IncidentTy'] ?? '';
    final String closureType = properties['ClosureTyp'] ?? '';
    final String road = properties['Road'] ?? '';
    final String region = properties['Region'] ?? '';
    final String suburb = properties['Suburb'] ?? '';
    final String trafficImpact = properties['TrafficImp'] ?? '';
    final String entryDate = properties['EntryDate'] ?? '';
    final String updateDate = properties['UpdateDate'] ?? '';

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Road Condition Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.report_problem,
                  color: colorScheme.onErrorContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Road Condition',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Incident Details
          Text('Road Condition Details', style: textTheme.bodyMedium),
          if (incidentType.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(
                context, 'Issue Type', incidentType),
          if (closureType.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(
                context, 'Road Status', closureType),
          if (trafficImpact.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(
                context, 'Traffic Impact', trafficImpact),

          customDivider,

          // Location Information
          Text('Location Information', style: textTheme.bodyMedium),
          if (location.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(context, 'Location', location),
          if (road.isNotEmpty)
            FeatureDisplayHelpers.buildProperty(context, 'Road', road),
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

          if (closureType.isNotEmpty &&
              closureType.toLowerCase().contains("caution"))
            customDivider,

          // Warning box for road caution
          if (closureType.isNotEmpty &&
              closureType.toLowerCase().contains("caution"))
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning,
                          color: colorScheme.onErrorContainer,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PROCEED WITH CAUTION',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Road conditions may affect travel',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
