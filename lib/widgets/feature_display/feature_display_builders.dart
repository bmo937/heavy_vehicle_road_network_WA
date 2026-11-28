import 'package:flutter/material.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';

// Import all individual builder files
import 'builders/bridge_display_builder.dart';
import 'builders/generic_properties_display_builder.dart';
import 'builders/intersection_display_builder.dart';
import 'builders/rest_area_display_builder.dart';
import 'builders/road_train_assembly_display_builder.dart';
import 'builders/road_with_conditions_display_builder.dart';
import 'builders/search_result_display_builder.dart';
import 'builders/traffic_incident_display_builder.dart';
import 'builders/traffic_service_display_builder.dart';
import 'builders/travel_impact_display_builder.dart';

/// Class containing all feature display builders - acts as aggregator/facade
/// Each method delegates to the appropriate individual builder class
class FeatureDisplayBuilders {
  /// Build traffic service display
  static Widget buildTrafficServiceDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return TrafficServiceDisplayBuilder.buildTrafficServiceDisplay(
        context, feature, title);
  }

  /// Build traffic incident display
  static Widget buildTrafficIncidentDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return TrafficIncidentDisplayBuilder.buildTrafficIncidentDisplay(
        context, feature, title);
  }

  /// Build travel impact display
  static Widget buildTravelImpactDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return TravelImpactDisplayBuilder.buildTravelImpactDisplay(
        context, feature, title);
  }

  /// Build intersection display
  static Widget buildIntersectionDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return IntersectionDisplayBuilder.buildIntersectionDisplay(
        context, feature, title);
  }

  /// Build generic properties display
  static Widget buildGenericPropertiesDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return GenericPropertiesDisplayBuilder.buildGenericPropertiesDisplay(
        context, feature, title);
  }

  /// Build bridge display
  static Widget buildBridgeDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return BridgeDisplayBuilder.buildBridgeDisplay(context, feature, title);
  }

  /// Build road with conditions display
  static Widget buildRoadWithConditionsDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return RoadWithConditionsDisplayBuilder.buildRoadWithConditionsDisplay(
        context, feature, title);
  }

  /* /// Build road without conditions display
  static Widget buildRoadWithoutConditionsDisplay(BuildContext context, TappedFeature feature, String title) {
    return RoadWithoutConditionsDisplayBuilder.buildRoadWithoutConditionsDisplay(context, feature, title);
  } */

  /// Build rest area display
  static Widget buildRestAreaDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return RestAreaDisplayBuilder.buildRestAreaDisplay(context, feature, title);
  }

  /// Build road train assembly display
  static Widget buildRoadTrainAssemblyDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return RoadTrainAssemblyDisplayBuilder.buildRoadTrainAssemblyDisplay(
        context, feature, title);
  }

  /// Build search result display
  static Widget buildSearchResultDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return SearchResultDisplayBuilder.buildSearchResultDisplay(
        context, feature, title);
  }
}
