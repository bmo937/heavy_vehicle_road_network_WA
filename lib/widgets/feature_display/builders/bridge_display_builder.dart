import 'package:material_ui/material_ui.dart';
import 'package:flutter_decorated_container/flutter_decorated_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';
import 'package:roads_map/widgets/feature_display/feature_display_helpers.dart';

/// Bridge display builder
class BridgeDisplayBuilder {
  /// Build bridge display
  static Widget buildBridgeDisplay(
      BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bridge Details
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FeatureDisplayHelpers.buildSubTitle(
                    context, "${properties['CROSSING_NAME']} $title"),
                /*  Text(
                  "${properties['CROSSING_NAME']} $title",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ) */
                Text(
                  properties['ROAD_NAME'],
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          /*  Text('Basic Information', style: textTheme.bodyMedium),
          if (properties['STR_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Structure Name', properties['STR_NAME']),
          if (properties['CROSSING_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Crossing Name', properties['CROSSING_NAME']),

          if (properties['ROAD_NAME'] != null || properties['ROAD'] != null) customDivider,

          // Location Information
          if (properties['ROAD_NAME'] != null || properties['ROAD'] != null) Text('Location Information', style: textTheme.bodyMedium), */
          if (properties['STR_NO'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'Structure Id', properties['STR_NO']),
          /*
          if (properties['ROAD'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road Id', properties['ROAD']),
          if (properties['ROAD_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road Name', properties['ROAD_NAME']),
          // if (properties['COMMON_USAGE_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Common Name', properties['COMMON_USAGE_NAME']),
          // if (properties['START_SLK'] != null) FeatureDisplayHelpers.buildProperty(context, 'SLK', properties['START_SLK'].toString()),
          if (properties['CWY'] != null) FeatureDisplayHelpers.buildProperty(context, 'Carriageway', properties['CWY']),
          // if (properties['START_TRUE_DIST'] != null) FeatureDisplayHelpers.buildProperty(context, 'True Distance', '${properties['START_TRUE_DIST']}km'),

          if (properties['RA_NAME'] != null || properties['LG_NAME'] != null) customDivider,

          // Administrative Information
          if (properties['RA_NAME'] != null || properties['LG_NAME'] != null) Text('Administrative Area', style: textTheme.bodyMedium),
          // if (properties['RA_NO'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road Authority No.', properties['RA_NO']),
          if (properties['RA_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Road Authority', properties['RA_NAME']),
          // if (properties['LG_NO'] != null) FeatureDisplayHelpers.buildProperty(context, 'Local Government No.', properties['LG_NO']),
          if (properties['LG_NAME'] != null) FeatureDisplayHelpers.buildProperty(context, 'Local Government', properties['LG_NAME']), */
/* 
          if (properties['NETWORK_TYPE'] != null || properties['NETWORK'] != null) customDivider,

          // Network and Status Information
          if (properties['NETWORK_TYPE'] != null || properties['NETWORK'] != null) Text('Network Information', style: textTheme.bodyMedium),
          if (properties['NETWORK_TYPE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network Type', properties['NETWORK_TYPE']),
          if (properties['NETWORK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network', properties['NETWORK']), */

          if (properties['CONDITION'] != null) customDivider,

          // Condition Information
          if (properties['CONDITION'] != null)
            Text('Condition', style: textTheme.bodyMedium),
          if (properties['CONDITION'] != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 10,
                child: DecoratedContainer(
                  strokeColor: colorScheme.onErrorContainer,
                  strokeWidth: 2,
                  backgroundColor: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      properties['CONDITION'].toString(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onError),
                    ),
                  ),
                ),
              ),
            )
          /*  if (properties['LATITUDE'] != null || properties['LONGITUDE'] != null) customDivider,

          // Coordinates
          if (properties['LATITUDE'] != null || properties['LONGITUDE'] != null) Text('Coordinates', style: textTheme.bodyMedium),
          if (properties['LATITUDE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Latitude', properties['LATITUDE'].toString()),
          if (properties['LONGITUDE'] != null) FeatureDisplayHelpers.buildProperty(context, 'Longitude', properties['LONGITUDE'].toString()), */
        ],
      );
    });
  }
}
