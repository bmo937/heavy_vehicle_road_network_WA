import 'package:flutter/material.dart';
import 'package:flutter_decorated_container/flutter_decorated_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';
import 'package:roads_map/utils/text_utils.dart';

import '../feature_display_helpers.dart';

/// Road with conditions display builder
class RoadWithConditionsDisplayBuilder {
  /// Build road with conditions display
  static Widget buildRoadWithConditionsDisplay(
      BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      debugPrint(
          'Building RoadWithConditionsDisplayBuilder with properties: ${properties['CONDITION']}');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Road Header with Warning
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FeatureDisplayHelpers.buildSubTitle(
                    context, properties['ROAD_NAME']),
                /*  Text(
                  properties['ROAD_NAME'],
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ), */
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8), // Intersection Details
          /*  Text('Road Information', style: textTheme.bodyMedium),
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
          if (properties['NETWORK'] != null) FeatureDisplayHelpers.buildProperty(context, 'Network', properties['NETWORK']), */
/* 
          if (properties['FROM_INTERSECTION'] != null || properties['TO_INTERSECTION'] != null) customDivider,

          // Intersection Information
          if (properties['FROM_INTERSECTION'] != null || properties['TO_INTERSECTION'] != null) Text('Intersection Points', style: textTheme.bodyMedium), */
          if (properties['FROM_INTERSECTION'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'From Intersection', properties['FROM_INTERSECTION']),
          if (properties['TO_INTERSECTION'] != null)
            FeatureDisplayHelpers.buildProperty(
                context, 'To Intersection', properties['TO_INTERSECTION']),

          if (properties['CONDITION'] != null || properties['COMMENTS'] != null)
            customDivider,

          // Conditions and Comments
          if (properties['CONDITION'] != null || properties['COMMENTS'] != null)
            Text('Current Conditions', style: textTheme.bodyMedium),
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
                      TextUtils.stripHtmlWithStructure(
                          properties['CONDITION'].toString()),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onError),
                    ),
                  ),
                ),
              ),
            )
        ],
      );
    });
  }
}
