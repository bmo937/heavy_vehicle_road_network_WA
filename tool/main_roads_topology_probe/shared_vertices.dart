import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

import 'geo.dart';

/// One occurrence of an exact coordinate in a source LineString.
class VertexAppearance {
  const VertexAppearance(this.feature, this.vertex, this.isEndpoint);

  /// Index into the analysed segment list.
  final int feature;

  /// Vertex index within that feature's coordinate list.
  final int vertex;

  /// True for the first and last vertex of the LineString.
  final bool isEndpoint;
}

/// Every exact coordinate (compared with `==` on the source doubles) mapped to
/// all of its appearances. No snapping or rounding is performed.
class CoordinateIndex {
  CoordinateIndex._(this.segments, this.groups);

  factory CoordinateIndex.build(List<MainRoadsNetworkSegment> segments) {
    final groups = <CoordKey, List<VertexAppearance>>{};
    for (var f = 0; f < segments.length; f++) {
      final g = segments[f].geometry;
      if (g.length < 2) {
        throw ArgumentError('feature ${segments[f].globalId} has fewer than 2 vertices');
      }
      for (var v = 0; v < g.length; v++) {
        final isEnd = v == 0 || v == g.length - 1;
        (groups[(g[v].longitude, g[v].latitude)] ??= []).add(VertexAppearance(f, v, isEnd));
      }
    }
    return CoordinateIndex._(segments, groups);
  }

  final List<MainRoadsNetworkSegment> segments;
  final Map<CoordKey, List<VertexAppearance>> groups;

  /// True when both features have a source vertex at exactly [key].
  bool bothFeaturesHaveVertexAt(CoordKey key, int a, int b) {
    final apps = groups[key];
    if (apps == null) return false;
    var hasA = false, hasB = false;
    for (final x in apps) {
      if (x.feature == a) hasA = true;
      if (x.feature == b) hasB = true;
    }
    return hasA && hasB;
  }
}

/// Route-continuity category of a pair of features meeting at a shared
/// endpoint. Diagnostic only: it implies nothing about turns or merging.
String continuityCategory(MainRoadsNetworkSegment a, MainRoadsNetworkSegment b) {
  final sameRoad = a.road == b.road;
  final sameRoute = a.routeNeId == b.routeNeId;
  if (sameRoad && sameRoute) return 'A: same ROAD + same ROUTE_NE_ID';
  if (sameRoad) return 'B: same ROAD + different ROUTE_NE_ID';
  if (sameRoute) return 'C: different ROAD + same ROUTE_NE_ID';
  return 'D: different ROAD + different ROUTE_NE_ID';
}

class SharedVertexAnalysis {
  SharedVertexAnalysis({
    required this.features,
    required this.totalVertices,
    required this.distinctCoordinates,
    required this.endpointAppearances,
    required this.distinctEndpointCoordinates,
    required this.closedLoopFeatures,
    required this.endpointsCoincidingWithOtherFeatureEndpoint,
    required this.endpointGroupSizeHistogram,
    required this.endpointGroupsSharedByMultipleFeatures,
    required this.endpointsOnOtherFeatureInternalVertex,
    required this.endpointInternalVertexGroups,
    required this.internalVertexAppearances,
    required this.internalVertexAppearancesSharedWithOtherFeature,
    required this.internalInternalGroups,
    required this.selfRepeatedInternalVertexGroups,
    required this.sharedGroupsByKind,
    required this.sharedGroupsByFeatureCount,
    required this.sharedGroupsByDistinctRoads,
    required this.sharedGroupsByDistinctRoutes,
    required this.continuityPairs,
    required this.continuityGroups,
    required this.sharedGroupDetails,
    required this.sharedGroupDetailsTruncated,
  });

  final int features;
  final int totalVertices;
  final int distinctCoordinates;
  final int endpointAppearances;
  final int distinctEndpointCoordinates;

  /// Features whose first and last vertex are the same coordinate.
  final int closedLoopFeatures;

  /// Endpoint appearances with an endpoint of a DIFFERENT feature at the exact
  /// same coordinate.
  final int endpointsCoincidingWithOtherFeatureEndpoint;

  /// endpoint-appearance count in a coordinate group -> number of groups.
  final Map<int, int> endpointGroupSizeHistogram;
  final int endpointGroupsSharedByMultipleFeatures;

  final int endpointsOnOtherFeatureInternalVertex;
  final int endpointInternalVertexGroups;

  final int internalVertexAppearances;

  /// Internal-vertex appearances whose exact coordinate is also used by any
  /// other feature (endpoint or internal).
  final int internalVertexAppearancesSharedWithOtherFeature;

  /// Coordinate groups where internal vertices of >= 2 different features meet.
  final int internalInternalGroups;

  /// Groups where one feature repeats a coordinate at an internal vertex.
  final int selfRepeatedInternalVertexGroups;

  final Map<String, int> sharedGroupsByKind;
  final Map<int, int> sharedGroupsByFeatureCount;
  final Map<int, int> sharedGroupsByDistinctRoads;
  final Map<int, int> sharedGroupsByDistinctRoutes;

  /// Category -> number of feature pairs meeting at an exact shared endpoint.
  final Map<String, int> continuityPairs;

  /// Sorted category set of a shared-endpoint group (e.g. "A+D") -> groups.
  final Map<String, int> continuityGroups;

  final List<Map<String, dynamic>> sharedGroupDetails;
  final bool sharedGroupDetailsTruncated;

  int get endpointGroupsWithOneEndpoint => endpointGroupSizeHistogram[1] ?? 0;
  int get endpointGroupsWithTwoEndpoints => endpointGroupSizeHistogram[2] ?? 0;
  int get endpointGroupsWithThreeOrMoreEndpoints => endpointGroupSizeHistogram.entries
      .where((e) => e.key >= 3)
      .fold(0, (s, e) => s + e.value);

  Map<String, dynamic> toJson() => {
        'features': features,
        'totalVertices': totalVertices,
        'distinctCoordinates': distinctCoordinates,
        'endpointAppearances': endpointAppearances,
        'distinctEndpointCoordinates': distinctEndpointCoordinates,
        'closedLoopFeatures': closedLoopFeatures,
        'endpointsCoincidingWithOtherFeatureEndpoint': endpointsCoincidingWithOtherFeatureEndpoint,
        'endpointGroupSizeDistribution': {
          'oneEndpoint': endpointGroupsWithOneEndpoint,
          'twoEndpoints': endpointGroupsWithTwoEndpoints,
          'threeOrMoreEndpoints': endpointGroupsWithThreeOrMoreEndpoints,
        },
        'endpointGroupSizeHistogram': _stringKeys(endpointGroupSizeHistogram),
        'endpointGroupsSharedByMultipleFeatures': endpointGroupsSharedByMultipleFeatures,
        'endpointsOnOtherFeatureInternalVertex': endpointsOnOtherFeatureInternalVertex,
        'endpointInternalVertexGroups': endpointInternalVertexGroups,
        'internalVertexAppearances': internalVertexAppearances,
        'internalVertexAppearancesSharedWithOtherFeature': internalVertexAppearancesSharedWithOtherFeature,
        'internalInternalGroups': internalInternalGroups,
        'selfRepeatedInternalVertexGroups': selfRepeatedInternalVertexGroups,
        'sharedGroupsByKind': sharedGroupsByKind,
        'sharedGroupsByFeatureCount': _stringKeys(sharedGroupsByFeatureCount),
        'sharedGroupsByDistinctRoads': _stringKeys(sharedGroupsByDistinctRoads),
        'sharedGroupsByDistinctRoutes': _stringKeys(sharedGroupsByDistinctRoutes),
        'continuityPairs': continuityPairs,
        'continuityGroups': continuityGroups,
        'sharedGroupDetails': sharedGroupDetails,
        'sharedGroupDetailsTruncated': sharedGroupDetailsTruncated,
      };
}

Map<String, int> _stringKeys(Map<int, int> m) =>
    {for (final k in (m.keys.toList()..sort())) '$k': m[k]!};

void _inc<K>(Map<K, int> m, K k) => m[k] = (m[k] ?? 0) + 1;

/// Measures exact-coordinate sharing between features. Pure and deterministic.
SharedVertexAnalysis analyzeSharedVertices(
  CoordinateIndex index, {
  int detailLimit = 20000,
}) {
  final segs = index.segments;
  var totalVertices = 0;
  for (final s in segs) {
    totalVertices += s.geometry.length;
  }

  var closed = 0;
  for (final s in segs) {
    final a = s.geometry.first, b = s.geometry.last;
    if (a.latitude == b.latitude && a.longitude == b.longitude) closed++;
  }

  var endpointAppearances = 0;
  var distinctEndpointCoords = 0;
  var endpointsCoincide = 0;
  final sizeHist = <int, int>{};
  var endpointGroupsMulti = 0;
  var endpointsOnInternal = 0;
  var endpointInternalGroups = 0;
  var internalApps = 0;
  var internalShared = 0;
  var internalInternalGroups = 0;
  var selfRepeated = 0;
  final byKind = <String, int>{};
  final byFeatureCount = <int, int>{};
  final byRoads = <int, int>{};
  final byRoutes = <int, int>{};
  final contPairs = <String, int>{};
  final contGroups = <String, int>{};
  final details = <Map<String, dynamic>>[];
  var truncated = false;

  for (final entry in index.groups.entries) {
    final apps = entry.value;
    final endpointApps = apps.where((a) => a.isEndpoint).toList();
    final internalAppsHere = apps.where((a) => !a.isEndpoint).toList();
    final features = apps.map((a) => a.feature).toSet();
    final endpointFeatures = endpointApps.map((a) => a.feature).toSet();
    final internalFeatures = internalAppsHere.map((a) => a.feature).toSet();

    endpointAppearances += endpointApps.length;
    internalApps += internalAppsHere.length;

    if (endpointApps.isNotEmpty) {
      distinctEndpointCoords++;
      _inc(sizeHist, endpointApps.length);
      if (endpointFeatures.length > 1) endpointGroupsMulti++;
      for (final e in endpointApps) {
        if (endpointApps.any((o) => o.feature != e.feature)) endpointsCoincide++;
        if (internalAppsHere.any((o) => o.feature != e.feature)) endpointsOnInternal++;
      }
      if (endpointApps.any((e) => internalAppsHere.any((o) => o.feature != e.feature))) {
        endpointInternalGroups++;
      }
    }
    for (final i in internalAppsHere) {
      if (features.any((f) => f != i.feature)) internalShared++;
    }
    if (internalFeatures.length > 1) internalInternalGroups++;
    // Same feature occupying the same coordinate more than once, at least once internally.
    if (internalAppsHere.any((i) => apps.where((o) => o.feature == i.feature).length > 1)) {
      selfRepeated++;
    }

    if (features.length < 2) continue;

    final kind = internalAppsHere.isEmpty
        ? 'endpointsOnly'
        : endpointApps.isEmpty
            ? 'internalOnly'
            : 'endpointAndInternal';
    final roads = features.map((f) => segs[f].road).toSet();
    final routes = features.map((f) => segs[f].routeNeId).toSet();
    _inc(byKind, kind);
    _inc(byFeatureCount, features.length);
    _inc(byRoads, roads.length);
    _inc(byRoutes, routes.length);

    if (endpointFeatures.length > 1) {
      final fl = endpointFeatures.toList()..sort();
      final cats = <String>{};
      for (var i = 0; i < fl.length; i++) {
        for (var j = i + 1; j < fl.length; j++) {
          final c = continuityCategory(segs[fl[i]], segs[fl[j]]);
          _inc(contPairs, c);
          cats.add(c.substring(0, 1));
        }
      }
      _inc(contGroups, (cats.toList()..sort()).join('+'));
    }

    if (details.length < detailLimit) {
      final fl = features.toList()..sort();
      details.add({
        'longitude': entry.key.$1,
        'latitude': entry.key.$2,
        'kind': kind,
        'featureCount': features.length,
        'endpointAppearances': endpointApps.length,
        'internalAppearances': internalAppsHere.length,
        'distinctRoads': (roads.toList()..sort()),
        'distinctRouteNeIds': (routes.toList()..sort()),
        'globalIds': fl.take(10).map((f) => segs[f].globalId).toList(),
      });
    } else {
      truncated = true;
    }
  }

  return SharedVertexAnalysis(
    features: segs.length,
    totalVertices: totalVertices,
    distinctCoordinates: index.groups.length,
    endpointAppearances: endpointAppearances,
    distinctEndpointCoordinates: distinctEndpointCoords,
    closedLoopFeatures: closed,
    endpointsCoincidingWithOtherFeatureEndpoint: endpointsCoincide,
    endpointGroupSizeHistogram: sizeHist,
    endpointGroupsSharedByMultipleFeatures: endpointGroupsMulti,
    endpointsOnOtherFeatureInternalVertex: endpointsOnInternal,
    endpointInternalVertexGroups: endpointInternalGroups,
    internalVertexAppearances: internalApps,
    internalVertexAppearancesSharedWithOtherFeature: internalShared,
    internalInternalGroups: internalInternalGroups,
    selfRepeatedInternalVertexGroups: selfRepeated,
    sharedGroupsByKind: byKind,
    sharedGroupsByFeatureCount: byFeatureCount,
    sharedGroupsByDistinctRoads: byRoads,
    sharedGroupsByDistinctRoutes: byRoutes,
    continuityPairs: contPairs,
    continuityGroups: contGroups,
    sharedGroupDetails: details,
    sharedGroupDetailsTruncated: truncated,
  );
}
