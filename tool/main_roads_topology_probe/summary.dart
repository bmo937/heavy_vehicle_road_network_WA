import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_parser.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

import '../main_roads_probe/arcgis_client.dart';
import 'crossings.dart';
import 'endpoint_proximity.dart';
import 'endpoint_segment_proximity.dart';
import 'fetch.dart';
import 'geometry_quality.dart';
import 'shared_vertices.dart';

const String layerName = 'Tandem Drive 1-10 All Networks';

/// Runs the full topology analysis over parsed segments. Pure; no I/O.
Map<String, dynamic> analyzeSegments(
  List<MainRoadsNetworkSegment> segments, {
  int detailLimit = 20000,
  double cellSizeDegrees = 0.01,
}) {
  final index = CoordinateIndex.build(segments);
  return {
    'geometryAndSharing': analyzeSharedVertices(index, detailLimit: detailLimit).toJson(),
    'endpointProximity': analyzeEndpointProximity(segments).toJson(),
    'endpointSegmentProximity': analyzeEndpointSegmentProximity(
      segments,
      detailLimit: detailLimit,
    ).toJson(),
    'crossings': analyzeCrossings(index, cellSizeDegrees: cellSizeDegrees, detailLimit: detailLimit).toJson(),
    'geometryQuality': analyzeGeometryQuality(segments, detailLimit: detailLimit).toJson(),
  };
}

/// Builds the machine-readable summary. The run is COMPLETE only when
/// retrieval was complete AND the production parser accepted every feature.
/// If anything is missing no analysis is produced: absence of features must
/// never be read as absence of connectivity.
Map<String, dynamic> buildTopologySummary(
  GeoJsonFetchOutcome fetch, {
  required String generatedAt,
  int detailLimit = 20000,
  double cellSizeDegrees = 0.01,
}) {
  final reasons = [...fetch.incompleteReasons];
  List<MainRoadsNetworkSegment>? segments;
  try {
    segments = const MainRoadsNetworkParser().parseFeatureCollection(fetch.collection);
    if (segments.isEmpty && reasons.isEmpty) reasons.add('layer returned zero features');
  } on MainRoadsParseException catch (e) {
    reasons.add('parser rejected the data: $e');
  }

  final complete = reasons.isEmpty && segments != null;
  return {
    'generatedAt': generatedAt,
    'status': complete ? 'COMPLETE' : 'INCOMPLETE',
    'incompleteReasons': reasons,
    'source': {
      'service': investigationBaseUrl,
      'layerId': topologyLayerId,
      'layerName': layerName,
      'query': 'where=1=1&outFields=*&returnGeometry=true&outSR=4326&f=geojson (paginated, OBJECTID order)',
    },
    'retrieval': {
      'pages': fetch.pages,
      'retrievedFeatures': fetch.retrieved,
      'serviceReportedCount': fetch.expectedCount,
    },
    'recordCount': segments?.length,
    'partCount': segments?.fold<int>(0, (n, s) => n + s.parts.length),
    'scope': 'Physical geometry topology only. MAX_NETWORK, network eligibility, restrictions and '
        'Tandem Drive Network 1 semantics are deliberately not interpreted. No RoadGraph was built, '
        'no coordinate was snapped and no feature was merged or removed.',
    if (complete) 'analysis': analyzeSegments(segments, detailLimit: detailLimit, cellSizeDegrees: cellSizeDegrees),
  };
}
