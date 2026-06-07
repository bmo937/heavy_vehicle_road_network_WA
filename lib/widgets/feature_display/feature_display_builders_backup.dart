/* import 'package:flutter/material.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';

// Import all individual builder files
import 'builders/bridge_display_builder.dart';
import 'builders/generic_properties_display_builder.dart';
import 'builders/intersection_display_builder.dart';
import 'builders/rest_area_display_builder.dart';
import 'builders/road_train_assembly_display_builder.dart';
import 'builders/road_with_conditions_display_builder.dart';
import 'builders/road_without_conditions_display_builder.dart';
import 'builders/search_result_display_builder.dart';
import 'builders/traffic_incident_display_builder.dart';
import 'builders/traffic_service_display_builder.dart';
import 'builders/travel_impact_display_builder.dart';

/// Class containing all feature display builders - acts as aggregator/facade
/// Each method delegates to the appropriate individual builder class
class FeatureDisplayBuilders {
  /// Build traffic service display
  static Widget buildTrafficServiceDisplay(BuildContext context, TappedFeature feature) {
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
          if (incidentType.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Issue Type', incidentType),
          if (closureType.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Road Status', closureType),
          if (trafficImpact.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Traffic Impact', trafficImpact),

          customDivider,

          // Location Information
          Text('Location Information', style: textTheme.bodyMedium),
          if (location.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Location', location),
          if (road.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Road', road),
          if (suburb.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Suburb/Town', suburb),
          if (region.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Region', region),

          if (entryDate.isNotEmpty || updateDate.isNotEmpty) customDivider,

          // Time Information
          if (entryDate.isNotEmpty || updateDate.isNotEmpty) Text('Time Information', style: textTheme.bodyMedium),
          if (entryDate.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Reported', entryDate),
          if (updateDate.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Last Updated', updateDate),

          if (closureType.isNotEmpty && closureType.toLowerCase().contains("caution")) customDivider,

          // Warning box for road caution
          if (closureType.isNotEmpty && closureType.toLowerCase().contains("caution"))
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

  /// Build traffic incident display
  static Widget buildTrafficIncidentDisplay(BuildContext context, TappedFeature feature) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Handle field name variations (case and field name can vary)
    String location = properties['Location'] ?? properties['LOCATION'] ?? '';
    final String incidentType = properties['IncidentTy'] ?? properties['IncidentType'] ?? '';
    final String trafficCondition = properties['TrafficCon'] ?? properties['TrafficCondition'] ?? '';
    final String trafficImpact = properties['TrafficImp'] ?? properties['TrafficImpact'] ?? '';
    final String road = properties['Road'] ?? '';
    final String region = properties['Region'] ?? '';
    final String suburb = properties['Suburb'] ?? '';
    final String localRoadName = properties['LocalRoadName'] ?? '';
    final String entryDate = properties['EntryDate'] ?? '';
    final String updateDate = properties['UpdateDate'] ?? '';

    // Clean up the location string by removing incident type if it's at the end
    if (location.isNotEmpty && incidentType.isNotEmpty) {
      if (location.endsWith(incidentType)) {
        location = location.substring(0, location.length - incidentType.length).trim();
        if (location.endsWith(' -')) {
          location = location.substring(0, location.length - 2).trim();
        }
      }
    }

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Traffic Incident Header
          Container(
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
          ),
          const SizedBox(height: 16),

          // Incident Details
          Text('Incident Details', style: textTheme.bodyMedium),
          if (incidentType.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Type', incidentType),
          if (trafficCondition.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Traffic Condition', trafficCondition),
          if (trafficImpact.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Impact', trafficImpact),

          customDivider,

          // Location Information
          Text('Location Information', style: textTheme.bodyMedium),
          if (location.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Location', location),
          if (road.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Road', road),
          if (localRoadName.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Local Road', localRoadName),
          if (suburb.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Suburb/Town', suburb),
          if (region.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Region', region),

          if (entryDate.isNotEmpty || updateDate.isNotEmpty) customDivider,

          // Time Information
          if (entryDate.isNotEmpty || updateDate.isNotEmpty) Text('Time Information', style: textTheme.bodyMedium),
          if (entryDate.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Reported', entryDate),
          if (updateDate.isNotEmpty) FeatureDisplayHelpers.buildProperty(context, 'Last Updated', updateDate),
        ],
      );
    });
  }

  /// Build travel impact display
  static Widget buildTravelImpactDisplay(BuildContext context, TappedFeature feature) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Convert dates from timestamps
    String commencementDate = "N/A";
    String endDate = "N/A";

    if (properties['CommencementDate'] != null) {
      // Convert to int safely from either double or int
      final timestamp = properties['CommencementDate'] is double ? (properties['CommencementDate'] as double).toInt() : properties['CommencementDate'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      commencementDate = "${date.day}/${date.month}/${date.year}";
    }

    if (properties['EndDate'] != null) {
      // Convert to int safely from either double or int
      final timestamp = properties['EndDate'] is double ? (properties['EndDate'] as double).toInt() : properties['EndDate'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      endDate = "${date.day}/${date.month}/${date.year}";
    }

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Travel Impact Header
          Container(
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
          ),
          const SizedBox(height: 16),

          // Impact Details
          Text('Impact Details', style: textTheme.bodyMedium),
          if (properties['Description'] != null) FeatureDisplayHelpers.buildProperty(context, 'Description', properties['Description']),
          if (properties['Type'] != null) FeatureDisplayHelpers.buildProperty(context, 'Type', properties['Type']),
          if (properties['Severity'] != null) FeatureDisplayHelpers.buildProperty(context, 'Severity', properties['Severity']),

          customDivider,

          // Duration Information
          Text('Duration', style: textTheme.bodyMedium),
          FeatureDisplayHelpers.buildProperty(context, 'Start Date', commencementDate),
          FeatureDisplayHelpers.buildProperty(context, 'End Date', endDate),

          if (properties['Location'] != null || properties['AffectedRoads'] != null) customDivider,

          // Location Information
          if (properties['Location'] != null || properties['AffectedRoads'] != null) Text('Location Information', style: textTheme.bodyMedium),
          if (properties['Location'] != null) FeatureDisplayHelpers.buildProperty(context, 'Location', properties['Location']),
          if (properties['AffectedRoads'] != null) FeatureDisplayHelpers.buildProperty(context, 'Affected Roads', properties['AffectedRoads']),
        ],
      );
    });
  }

  /// Build intersection display
  static Widget buildIntersectionDisplay(BuildContext context, TappedFeature feature) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intersection Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.traffic,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Intersection',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Intersection Details
          Text('Intersection Details', style: textTheme.bodyMedium),
          if (properties['NODE_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Node Name', properties['NODE_NAME']),
          if (properties['NODE_DESCR'] != null) FeatureDisplayHelpers.buildProperty(context, 'Description', properties['NODE_DESCR']),
          if (properties['NODE_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Node Type', properties['NODE_TYPE']),
          if (properties['NO_NODE_ID'] != null) FeatureDisplayHelpers.buildProperty(context, 'Node ID', properties['NO_NODE_ID'].toString()),

          if (properties['NETWORK'] != null || properties['CONDITION'] != null) customDivider,

          // Network and Condition Information
          if (properties['NETWORK'] != null || properties['CONDITION'] != null) Text('Network & Condition', style: textTheme.bodyMedium),
          if (properties['NETWORK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network', properties['NETWORK']),
          if (properties['CONDITION'] != null) FeatureDisplayHelpers.buildProperty(context, 'Condition', properties['CONDITION']),
        ],
      );
    });
  }

  /// Build generic properties display for unknown feature types
  static Widget buildGenericPropertiesDisplay(BuildContext context, TappedFeature feature) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Properties',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...feature.properties.entries
            .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
            .map((entry) => FeatureDisplayHelpers.buildProperty(context, entry.key, entry.value)),
      ],
    );
  }

  /// Build bridge display
  static Widget buildBridgeDisplay(BuildContext context, TappedFeature feature) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bridge Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bridge Information',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Bridge Properties
          Text('Basic Information', style: textTheme.bodyMedium),
          if (properties['STR_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Structure Name', properties['STR_NAME']),
          if (properties['CROSSING_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Crossing Name', properties['CROSSING_NAME']),
          if (properties['STR_NO'] != null) FeatureDisplayHelpers.buildProperty(context, 'Structure Number', properties['STR_NO']),

          if (properties['ROAD_NAME'] != null || properties['ROAD'] != null) customDivider,

          // Location Information
          if (properties['ROAD_NAME'] != null || properties['ROAD'] != null) Text('Location Information', style: textTheme.bodyMedium),
          if (properties['ROAD'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road', properties['ROAD']),
          if (properties['ROAD_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road Name', properties['ROAD_NAME']),
          if (properties['COMMON_USAGE_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Common Name', properties['COMMON_USAGE_NAME']),
          if (properties['START_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'SLK', properties['START_SLK'].toString()),
          if (properties['CWY'] != null) FeatureDisplayHelpers.buildProperty(context, 'Carriageway', properties['CWY']),
          if (properties['START_TRUE_DIST'] != null) FeatureDisplayHelpers.buildProperty(context, 'True Distance', '${properties['START_TRUE_DIST']}km'),

          if (properties['RA_NAME'] != null || properties['LG_NAME'] != null) customDivider,

          // Administrative Information
          if (properties['RA_NAME'] != null || properties['LG_NAME'] != null) Text('Administrative Area', style: textTheme.bodyMedium),
          if (properties['RA_NO'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road Authority No.', properties['RA_NO']),
          if (properties['RA_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road Authority', properties['RA_NAME']),
          if (properties['LG_NO'] != null) FeatureDisplayHelpers.buildProperty(context, 'Local Government No.', properties['LG_NO']),
          if (properties['LG_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Local Government', properties['LG_NAME']),

          if (properties['NETWORK_TYPE'] != null || properties['NETWORK'] != null) customDivider,

          // Network and Status Information
          if (properties['NETWORK_TYPE'] != null || properties['NETWORK'] != null) Text('Network Information', style: textTheme.bodyMedium),
          if (properties['NETWORK_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network Type', properties['NETWORK_TYPE']),
          if (properties['NETWORK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network', properties['NETWORK']),

          if (properties['CONDITION'] != null) customDivider,

          // Condition Information
          if (properties['CONDITION'] != null) Text('Condition', style: textTheme.bodyMedium),
          if (properties['CONDITION'] != null) FeatureDisplayHelpers.buildProperty(context, 'Condition', properties['CONDITION']),

          if (properties['LATITUDE'] != null || properties['LONGITUDE'] != null) customDivider,

          // Coordinates
          if (properties['LATITUDE'] != null || properties['LONGITUDE'] != null) Text('Coordinates', style: textTheme.bodyMedium),
          if (properties['LATITUDE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Latitude', properties['LATITUDE'].toString()),
          if (properties['LONGITUDE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Longitude', properties['LONGITUDE'].toString()),
        ],
      );
    });
  }

  /// Build road with conditions display
  static Widget buildRoadWithConditionsDisplay(BuildContext context, TappedFeature feature) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Road Header with Warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: colorScheme.onErrorContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Road with Conditions',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Road Information
          Text('Road Information', style: textTheme.bodyMedium),
          if (properties['ROAD'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road', properties['ROAD']),
          if (properties['ROAD_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road Name', properties['ROAD_NAME']),
          if (properties['COMMON_USAGE_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Common Name', properties['COMMON_USAGE_NAME']),
          if (properties['START_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Start SLK', properties['START_SLK'].toString()),
          if (properties['END_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'End SLK', properties['END_SLK'].toString()),
          if (properties['START_TRUE_DIST'] != null) FeatureDisplayHelpers.buildProperty(context, 'Start Distance', '${properties['START_TRUE_DIST']}km'),
          if (properties['END_TRUE_DIST'] != null) FeatureDisplayHelpers.buildProperty(context, 'End Distance', '${properties['END_TRUE_DIST']}km'),

          customDivider,

          // Network and Administrative Information
          Text('Network Information', style: textTheme.bodyMedium),
          if (properties['NETWORK_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network Type', properties['NETWORK_TYPE']),
          if (properties['LG_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Local Government', properties['LG_NAME']),
          if (properties['ACCESS_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Access Type', properties['ACCESS_TYPE']),
          if (properties['NETWORK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network', properties['NETWORK']),

          if (properties['FROM_INTERSECTION'] != null || properties['TO_INTERSECTION'] != null) customDivider,

          // Intersection Information
          if (properties['FROM_INTERSECTION'] != null || properties['TO_INTERSECTION'] != null) Text('Intersection Points', style: textTheme.bodyMedium),
          if (properties['FROM_INTERSECTION'] != null) FeatureDisplayHelpers.buildProperty(context, 'From Intersection', properties['FROM_INTERSECTION']),
          if (properties['TO_INTERSECTION'] != null) FeatureDisplayHelpers.buildProperty(context, 'To Intersection', properties['TO_INTERSECTION']),

          if (properties['CONDITION'] != null || properties['COMMENTS'] != null) customDivider,

          // Conditions and Comments
          if (properties['CONDITION'] != null || properties['COMMENTS'] != null) Text('Current Conditions', style: textTheme.bodyMedium),
          if (properties['CONDITION'] != null) FeatureDisplayHelpers.buildProperty(context, 'Condition', properties['CONDITION']),
          if (properties['COMMENTS'] != null) FeatureDisplayHelpers.buildProperty(context, 'Comments', properties['COMMENTS']),
          if (properties['PRODUCT'] != null) FeatureDisplayHelpers.buildProperty(context, 'Product Restrictions', properties['PRODUCT']),

          if (properties['MAX_SPEED'] != null || properties['CURFEW'] != null) customDivider,

          // Speed and Time Restrictions
          if (properties['MAX_SPEED'] != null || properties['CURFEW'] != null) Text('Speed & Time Restrictions', style: textTheme.bodyMedium),
          if (properties['MAX_SPEED'] != null) FeatureDisplayHelpers.buildProperty(context, 'Maximum Speed', properties['MAX_SPEED']),
          if (properties['CURFEW'] != null) FeatureDisplayHelpers.buildProperty(context, 'Curfew', properties['CURFEW']),
        ],
      );
    });
  }

  /// Build road without conditions display
  static Widget buildRoadWithoutConditionsDisplay(BuildContext context, TappedFeature feature) {
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

  /// Build rest area display
  static Widget buildRestAreaDisplay(BuildContext context, TappedFeature feature) {
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
          if (properties['REST_AREA_NAME'] != null) FeatureDisplayHelpers.buildSubTitle(context, properties['REST_AREA_NAME']),
          if (properties['REST_AREA_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Rest Area Type', properties['REST_AREA_TYPE']),
          if (properties['ROAD_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road', properties['ROAD_NAME']),
          if (properties['COMMON_USAGE_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Common Name', properties['COMMON_USAGE_NAME']),
          if (properties['LG_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Local Government', properties['LG_NAME']),
          if (properties['START_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Start SLK', properties['START_SLK'].toString()),
          if (properties['END_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'End SLK', properties['END_SLK'].toString()),
          if (properties['CWY'] != null) FeatureDisplayHelpers.buildProperty(context, 'Carriageway', properties['CWY']),

          customDivider,

          // Rest Area Features
          Text('Rest Area Features', style: textTheme.bodyMedium),
          if (properties['OWNERSHIP'] != null) FeatureDisplayHelpers.buildProperty(context, 'Ownership', properties['OWNERSHIP']),
          if (properties['STAY_24_HOUR'] != null) FeatureDisplayHelpers.buildProperty(context, '24 Hour Stay', properties['STAY_24_HOUR']),
          if (properties['SURFACE_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Surface Type', properties['SURFACE_TYPE']),
          if (properties['SURFACE_AREA'] != null) FeatureDisplayHelpers.buildProperty(context, 'Surface Area', '${properties['SURFACE_AREA']} m²'),

          customDivider,

          // Facilities Available
          Text('Available Facilities', style: textTheme.bodyMedium),
          const SizedBox(height: 8),

          // Facility chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (properties['CONSTRUCTED_SHELTER'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Constructed Shelter', true),
              if (properties['NATURAL_SHADE'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Natural Shade', true),
              if (properties['LIGHTING_PRESENT'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Lighting', true),
              if (properties['INFORMATION_BOARD'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Information Board', true),
              if (properties['SCENIC_LOOKOUT'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Scenic Lookout', true),
              if (properties['EFFLUENT_DUMP_SITE'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Effluent Dump', true),
            ],
          ),

          customDivider,

          // Facilities Count Information
          Text('Facility Details', style: textTheme.bodyMedium),
          if (properties['NUMBER_OF_TOILETS'] != null && properties['NUMBER_OF_TOILETS'] > 0)
            FeatureDisplayHelpers.buildProperty(context, 'Number of Toilets', properties['NUMBER_OF_TOILETS'].toString()),
          if (properties['ACCESSIBLE_TOILETS'] == 'Yes') FeatureDisplayHelpers.buildProperty(context, 'Accessible Toilets', 'Available'),
          if (properties['NUMBER_OF_TABLES'] != null && properties['NUMBER_OF_TABLES'] > 0)
            FeatureDisplayHelpers.buildProperty(context, 'Number of Tables', properties['NUMBER_OF_TABLES'].toString()),
          if (properties['ACCESSIBLE_TABLES'] == 'Yes') FeatureDisplayHelpers.buildProperty(context, 'Accessible Tables', 'Available'),
          if (properties['NUMBER_OF_BINS'] != null && properties['NUMBER_OF_BINS'] > 0)
            FeatureDisplayHelpers.buildProperty(context, 'Number of Bins', properties['NUMBER_OF_BINS'].toString()),

          if (properties['COMMEMORATION_WAY'] != null) customDivider,

          // Additional Information
          if (properties['COMMEMORATION_WAY'] != null) Text('Additional Information', style: textTheme.bodyMedium),
          if (properties['COMMEMORATION_WAY'] != null) FeatureDisplayHelpers.buildProperty(context, 'Commemoration Way', properties['COMMEMORATION_WAY']),
          if (properties['NETWORK_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network Type', properties['NETWORK_TYPE']),
        ],
      );
    });
  }

  /// Build road train assembly display
  static Widget buildRoadTrainAssemblyDisplay(BuildContext context, TappedFeature feature) {
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
          if (properties['RA_NAME'] != null) FeatureDisplayHelpers.buildSubTitle(context, properties['RA_NAME']),
          if (properties['RA_NO'] != null) FeatureDisplayHelpers.buildProperty(context, 'Assembly Area Number', properties['RA_NO']),

          customDivider,

          // Location Information
          Text('Location Information', style: textTheme.bodyMedium),
          if (properties['ROAD_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road', properties['ROAD_NAME']),
          if (properties['COMMON_USAGE_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Common Name', properties['COMMON_USAGE_NAME']),
          if (properties['LG_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Local Government', properties['LG_NAME']),
          if (properties['START_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Start SLK', properties['START_SLK'].toString()),
          if (properties['END_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'End SLK', properties['END_SLK'].toString()),
          if (properties['CWY'] != null) FeatureDisplayHelpers.buildProperty(context, 'Carriageway', properties['CWY']),

          customDivider,

          // Infrastructure Type Information
          Text('Infrastructure Information', style: textTheme.bodyMedium),
          if (properties['IIT_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Infrastructure Type', properties['IIT_TYPE']),
          if (properties['IIT_DESC'] != null) FeatureDisplayHelpers.buildProperty(context, 'Description', properties['IIT_DESC']),

          customDivider,

          // Available Facilities
          Text('Available Facilities', style: textTheme.bodyMedium),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (properties['BIN'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Bins', true),
              if (properties['IIT_TABLE'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Tables', true),
              if (properties['BBQ'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'BBQ', true),
              if (properties['TOILET'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Toilets', true),
              if (properties['WATER'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Water', true),
              if (properties['TELEPHONE'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Telephone', true),
              if (properties['SHELTER'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Shelter', true),
              if (properties['DISABLED'] == 'Yes') FeatureDisplayHelpers.buildFacilityChip(context, 'Disabled Access', true),
            ],
          ),

          if (properties['SIGN_PRESENT'] != null || properties['PHONE_SIGNAL'] != null) customDivider,

          // Additional Information
          if (properties['SIGN_PRESENT'] != null || properties['PHONE_SIGNAL'] != null) Text('Additional Information', style: textTheme.bodyMedium),
          if (properties['SIGN_PRESENT'] == 'Yes') FeatureDisplayHelpers.buildProperty(context, 'Signage Present', 'Yes'),
          if (properties['PHONE_SIGNAL'] != null) FeatureDisplayHelpers.buildProperty(context, 'Phone Signal', properties['PHONE_SIGNAL']),
          if (properties['NETWORK_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network Type', properties['NETWORK_TYPE']),

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

  /// Build search result display
  static Widget buildSearchResultDisplay(BuildContext context, TappedFeature feature) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Result Header
          Container(
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
          const SizedBox(height: 16),

          // Main Information
          if (properties['name'] != null || properties['NAME'] != null) FeatureDisplayHelpers.buildSubTitle(context, properties['name'] ?? properties['NAME']),

          if (properties['address'] != null || properties['ADDRESS'] != null)
            FeatureDisplayHelpers.buildProperty(context, 'Address', properties['address'] ?? properties['ADDRESS']),
          if (properties['type'] != null || properties['TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Type', properties['type'] ?? properties['TYPE']),
          if (properties['category'] != null || properties['CATEGORY'] != null)
            FeatureDisplayHelpers.buildProperty(context, 'Category', properties['category'] ?? properties['CATEGORY']),

          customDivider,

          // Location Details
          Text('Location Details', style: textTheme.bodyMedium),
          if (properties['suburb'] != null || properties['SUBURB'] != null) FeatureDisplayHelpers.buildProperty(context, 'Suburb', properties['suburb'] ?? properties['SUBURB']),
          if (properties['city'] != null || properties['CITY'] != null) FeatureDisplayHelpers.buildProperty(context, 'City', properties['city'] ?? properties['CITY']),
          if (properties['state'] != null || properties['STATE'] != null) FeatureDisplayHelpers.buildProperty(context, 'State', properties['state'] ?? properties['STATE']),
          if (properties['postcode'] != null || properties['POSTCODE'] != null)
            FeatureDisplayHelpers.buildProperty(context, 'Postcode', properties['postcode'] ?? properties['POSTCODE']),

          if (properties['coordinates'] != null || properties['COORDINATES'] != null || properties['latitude'] != null || properties['longitude'] != null) customDivider,

          // Coordinates
          if (properties['coordinates'] != null || properties['COORDINATES'] != null || properties['latitude'] != null || properties['longitude'] != null)
            Text('Coordinates', style: textTheme.bodyMedium),
          if (properties['latitude'] != null && properties['longitude'] != null)
            FeatureDisplayHelpers.buildProperty(context, 'Coordinates', '${properties['latitude']}, ${properties['longitude']}'),
          if (properties['coordinates'] != null) FeatureDisplayHelpers.buildProperty(context, 'Coordinates', properties['coordinates']),

          if (properties.containsKey('phone') || properties.containsKey('website') || properties.containsKey('email') || properties.containsKey('opening_hours')) customDivider,

          // Contact Information (if available)
          if (properties.containsKey('phone') || properties.containsKey('website') || properties.containsKey('email') || properties.containsKey('opening_hours'))
            Text('Contact Information', style: textTheme.bodyMedium),
          if (properties['phone'] != null) FeatureDisplayHelpers.buildProperty(context, 'Phone', properties['phone']),
          if (properties['website'] != null) FeatureDisplayHelpers.buildProperty(context, 'Website', properties['website']),
          if (properties['email'] != null) FeatureDisplayHelpers.buildProperty(context, 'Email', properties['email']),
          if (properties['opening_hours'] != null) FeatureDisplayHelpers.buildProperty(context, 'Opening Hours', properties['opening_hours']),

          // Additional Properties (if any unique ones exist)
          if (properties.entries.any((entry) =>
              ![
                'name',
                'NAME',
                'address',
                'ADDRESS',
                'type',
                'TYPE',
                'category',
                'CATEGORY',
                'suburb',
                'SUBURB',
                'city',
                'CITY',
                'state',
                'STATE',
                'postcode',
                'POSTCODE',
                'coordinates',
                'COORDINATES',
                'latitude',
                'longitude',
                'phone',
                'website',
                'email',
                'opening_hours'
              ].contains(entry.key) &&
              entry.value != null &&
              entry.value.toString().isNotEmpty)) ...[
            customDivider,
            Text('Additional Information', style: textTheme.bodyMedium),
            ...properties.entries
                .where((entry) =>
                    ![
                      'name',
                      'NAME',
                      'address',
                      'ADDRESS',
                      'type',
                      'TYPE',
                      'category',
                      'CATEGORY',
                      'suburb',
                      'SUBURB',
                      'city',
                      'CITY',
                      'state',
                      'STATE',
                      'postcode',
                      'POSTCODE',
                      'coordinates',
                      'COORDINATES',
                      'latitude',
                      'longitude',
                      'phone',
                      'website',
                      'email',
                      'opening_hours'
                    ].contains(entry.key) &&
                    entry.value != null &&
                    entry.value.toString().isNotEmpty)
                .map((entry) => FeatureDisplayHelpers.buildProperty(context, entry.key, entry.value)),
          ],

          // Search Context Notice
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This location was found through search',
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
 */