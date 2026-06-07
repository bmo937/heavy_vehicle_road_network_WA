import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';

import 'feature_display.dart';

class FeatureTappedDisplay extends ConsumerWidget {
  const FeatureTappedDisplay({super.key});

  // Empty state when no feature is selected
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap on a feature to view details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  // Build the appropriate feature details widget based on feature type
  Widget _buildFeatureDetails(BuildContext context, WidgetRef ref, TappedFeature feature, String featureType, String title) {
    debugPrint('DEBUG: Building feature details for type: $featureType');

    switch (featureType) {
      case 'traffic_service':
        debugPrint('DEBUG: Building traffic service display');
        return FeatureDisplayBuilders.buildTrafficServiceDisplay(context, feature, title);
      case 'traffic_incident':
        debugPrint('DEBUG: Building traffic incident display');
        return FeatureDisplayBuilders.buildTrafficIncidentDisplay(context, feature, title);
      case 'travel_impact':
        debugPrint('DEBUG: Building travel impact display');
        return FeatureDisplayBuilders.buildTravelImpactDisplay(context, feature, title);
      case 'intersection':
        debugPrint('DEBUG: Building intersection display');
        return FeatureDisplayBuilders.buildIntersectionDisplay(context, feature, title);
      /* case 'drive_under_structure':
        debugPrint('DEBUG: Building drive under structure display');
        return FeatureDisplayBuilders.buildDriveUnderStructureDisplay(context, feature, title); */
      case 'bridge':
        debugPrint('DEBUG: Building bridge display');
        return FeatureDisplayBuilders.buildBridgeDisplay(context, feature, title);
      case 'road_with_conditions':
        debugPrint('DEBUG: Building road with conditions display');
        return FeatureDisplayBuilders.buildRoadWithConditionsDisplay(context, feature, title);
      /*  case 'road_without_conditions':
        debugPrint('DEBUG: Building road without conditions display');
        return FeatureDisplayBuilders.buildRoadWithoutConditionsDisplay(context, feature, title); */
      case 'rest_area':
        debugPrint('DEBUG: Building rest area display');
        return FeatureDisplayBuilders.buildRestAreaDisplay(context, feature, title);
      case 'road_train_assembly':
        debugPrint('DEBUG: Building road train assembly display');
        return FeatureDisplayBuilders.buildRoadTrainAssemblyDisplay(context, feature, title);
      /* case 'drive_over_structure':
        debugPrint('DEBUG: Building drive over structure display');
        return FeatureDisplayBuilders.buildDriveOverStructureDisplay(context, feature, title); */
      case 'search_result':
        debugPrint('DEBUG: Building search result display');
        return FeatureDisplayBuilders.buildSearchResultDisplay(context, feature, title);
      default:
        debugPrint('DEBUG: Building generic properties display');
        return FeatureDisplayBuilders.buildGenericPropertiesDisplay(context, feature, title);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tappedFeature = ref.watch(featureTapStateProvider);
    final showDetails = ref.watch(showFeatureDetailsProvider);

    debugPrint('FeatureTappedDisplay.build called');
    debugPrint('tappedFeature: ${tappedFeature != null}');
    debugPrint('showFeatureDetails: $showDetails');

    // If no feature or details should not be shown, return empty state
    if (tappedFeature == null) {
      return _buildEmptyState(context);
    }

    // Get feature type and determine title
    String featureType = FeatureTypeDetector.determineFeatureType(tappedFeature);
    debugPrint('Feature type determined: $featureType');

    String title = '';
    switch (featureType) {
      case 'traffic_service':
        title = 'Road Condition';
        break;
      case 'traffic_incident':
        title = 'Traffic Incident';
        break;
      case 'travel_impact':
        title = 'Travel Impact';
        break;
      case 'intersection':
        title = 'Intersection';
        break;
      case 'bridge':
        title = 'Bridge';
        break;
      case 'road_with_conditions':
        title = 'CONDITIONAL';
        break;
      case 'road_without_conditions':
        title = 'Road Segment';
        break;
      case 'rest_area':
        title = 'Rest Area';
        break;
      case 'road_train_assembly':
        title = 'Road Train Assembly Area';
        break;
      case 'drive_over_structure':
        title = 'Drive Over Structure';
        break;
      case 'drive_under_structure':
        title = 'Drive Under Structure';
        break;
      case 'search_result':
        title = 'Search Result';
        break;
      default:
        title = 'Feature Details';
        break;
    }

    // Return the feature details display
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /*  // Header with title
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16), */

          // Feature details content
          _buildFeatureDetails(context, ref, tappedFeature, featureType, title),

          // const SizedBox(height: 16),
          // Footer with additional information or actions
          /* customDivider,
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => boxController.closeBox(),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ) */
        ],
      ),
    );
  }
}
