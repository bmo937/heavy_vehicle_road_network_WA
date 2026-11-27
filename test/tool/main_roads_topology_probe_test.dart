import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

import '../../tool/main_roads_topology_probe/crossings.dart';
import '../../tool/main_roads_topology_probe/endpoint_proximity.dart';
import '../../tool/main_roads_topology_probe/fetch.dart';
import '../../tool/main_roads_topology_probe/geo.dart';
import '../../tool/main_roads_topology_probe/geometry_quality.dart';
import '../../tool/main_roads_topology_probe/report.dart';
import '../../tool/main_roads_topology_probe/shared_vertices.dart';
import '../../tool/main_roads_topology_probe/summary.dart';

// Tiny fixtures: coordinates are [lng, lat] on a 0.001 degree lattice
// (~100 m) around (115, -32), so "1,2" below means (115.001, -31.998).
const _lng0 = 115.0, _lat0 = -32.0;

MainRoadsNetworkSegment seg(String id, List<List<num>> pts, {String road = 'R1', int route = 1}) =>
    MainRoadsNetworkSegment(
      globalId: id,
      objectId: null,
      road: road,
      roadName: null,
      routeNeId: route,
      startSlk: 0,
      endSlk: 1,
      startTrueDist: 0,
      endTrueDist: 1,
      networkType: null,
      networkCategory: null,
      maxNetwork: 1,
      geometry: [for (final p in pts) SourceCoordinate(longitude: _lng0 + p[0] * 0.001, latitude: _lat0 + p[1] * 0.001)],
    );

SharedVertexAnalysis shared(List<MainRoadsNetworkSegment> s) => analyzeSharedVertices(CoordinateIndex.build(s));
CrossingAnalysis crossings(List<MainRoadsNetworkSegment> s) => analyzeCrossings(CoordinateIndex.build(s));

Map<String, dynamic> geoFeature(String id, Object? coords, {int objectId = 1}) => {
      'type': 'Feature',
      'properties': {
        'GlobalID': id,
        'OBJECTID': objectId,
        'ROAD': 'H001',
        'ROUTE_NE_ID': 5,
        'START_SLK': 0.0,
        'END_SLK': 1.0,
        'START_TRUE_DIST': 0.0,
        'END_TRUE_DIST': 1.0,
        'MAX_NETWORK': 3,
      },
      'geometry': {'type': 'LineString', 'coordinates': coords},
    };

List<List<double>> goodCoords(int i) => [
      [115.0 + i * 0.001, -32.0],
      [115.0 + i * 0.001, -31.999],
    ];

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  final List<Uri> requests = [];
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add(o.uri);
    return handler(o);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object o) => ResponseBody.fromString(jsonEncode(o), 200,
    headers: {Headers.contentTypeHeader: ['application/json']});

/// Fake layer service with [total] features, [pageCap] per page and a flag policy.
Dio _service({
  required int total,
  int serviceCount = -1,
  int pageCap = 2,
  bool flagLastPage = false,
  bool failOnSecondPage = false,
}) {
  final adapter = _Adapter((o) {
    final q = o.uri.queryParameters;
    if (q['returnCountOnly'] == 'true') return _json({'count': serviceCount >= 0 ? serviceCount : total});
    if (q['f'] == 'json') return _json({'maxRecordCount': pageCap});
    final offset = int.parse(q['resultOffset']!);
    if (failOnSecondPage && offset > 0) return ResponseBody.fromString('boom', 500);
    final end = (offset + pageCap).clamp(0, total);
    return _json({
      'type': 'FeatureCollection',
      'features': [for (var i = offset; i < end; i++) geoFeature('g$i', goodCoords(i), objectId: i)],
      if (end < total || flagLastPage) 'exceededTransferLimit': true,
    });
  });
  return Dio(BaseOptions(responseType: ResponseType.plain))..httpClientAdapter = adapter;
}

void main() {
  group('shared vertices', () {
    test('exact shared endpoints and unshared endpoints', () {
      final r = shared([
        seg('a', [[0, 0], [1, 0]]),
        seg('b', [[1, 0], [2, 0]]),
        seg('c', [[5, 5], [6, 5]]),
      ]);
      expect(r.features, 3);
      expect(r.totalVertices, 6);
      expect(r.distinctCoordinates, 5);
      expect(r.endpointAppearances, 6);
      expect(r.endpointsCoincidingWithOtherFeatureEndpoint, 2);
      expect(r.endpointGroupsWithTwoEndpoints, 1);
      expect(r.endpointGroupsWithOneEndpoint, 4);
      expect(r.endpointGroupsWithThreeOrMoreEndpoints, 0);
    });

    test('three-way endpoint group', () {
      final r = shared([
        seg('a', [[0, 0], [1, 0]]),
        seg('b', [[1, 0], [2, 0]]),
        seg('c', [[1, 0], [1, 1]]),
      ]);
      expect(r.endpointGroupsWithThreeOrMoreEndpoints, 1);
    });

    test('endpoint matching another line\'s internal vertex', () {
      final r = shared([
        seg('a', [[0, 0], [1, 0], [2, 0]]),
        seg('b', [[1, 0], [1, 1]]),
      ]);
      expect(r.endpointsOnOtherFeatureInternalVertex, 1);
      expect(r.endpointInternalVertexGroups, 1);
      expect(r.sharedGroupsByKind, {'endpointAndInternal': 1});
      expect(r.internalInternalGroups, 0);
    });

    test('internal vertices shared by different features', () {
      final r = shared([
        seg('a', [[0, 0], [1, 0], [2, 0]]),
        seg('b', [[1, -1], [1, 0], [1, 1]]),
      ]);
      expect(r.internalInternalGroups, 1);
      expect(r.internalVertexAppearancesSharedWithOtherFeature, 2);
      expect(r.endpointsOnOtherFeatureInternalVertex, 0);
      expect(r.sharedGroupsByKind, {'internalOnly': 1});
    });

    test('continuity categories A-D at exact shared endpoints', () {
      final r = shared([
        seg('a', [[0, 0], [1, 0]], road: 'R1', route: 1),
        seg('b', [[1, 0], [2, 0]], road: 'R1', route: 1), // A with a
        seg('c', [[10, 0], [11, 0]], road: 'R1', route: 1),
        seg('d', [[11, 0], [12, 0]], road: 'R1', route: 2), // B
        seg('e', [[20, 0], [21, 0]], road: 'R1', route: 1),
        seg('f', [[21, 0], [22, 0]], road: 'R2', route: 1), // C
        seg('g', [[30, 0], [31, 0]], road: 'R1', route: 1),
        seg('h', [[31, 0], [32, 0]], road: 'R2', route: 2), // D
      ]);
      expect(r.continuityPairs, {
        'A: same ROAD + same ROUTE_NE_ID': 1,
        'B: same ROAD + different ROUTE_NE_ID': 1,
        'C: different ROAD + same ROUTE_NE_ID': 1,
        'D: different ROAD + different ROUTE_NE_ID': 1,
      });
      expect(r.continuityGroups, {'A': 1, 'B': 1, 'C': 1, 'D': 1});
    });
  });

  group('distance buckets', () {
    test('boundaries are upper-inclusive and exact is separate', () {
      DistanceBucket b(double m) => bucketForDistance(m, exact: false);
      expect(bucketForDistance(0, exact: true), DistanceBucket.exact);
      expect(b(0), DistanceBucket.upTo0_1);
      expect(b(0.1), DistanceBucket.upTo0_1);
      expect(b(0.1000001), DistanceBucket.upTo0_5);
      expect(b(0.5), DistanceBucket.upTo0_5);
      expect(b(1), DistanceBucket.upTo1);
      expect(b(1.01), DistanceBucket.upTo2);
      expect(b(2), DistanceBucket.upTo2);
      expect(b(5), DistanceBucket.upTo5);
      expect(b(10), DistanceBucket.upTo10);
      expect(b(10.01), DistanceBucket.over10);
      expect(() => b(-1), throwsArgumentError);
    });

    test('haversine uses metres, not degrees', () {
      expect(haversineMetres(-32, 115, -31, 115), closeTo(111195, 5));
      // One degree of longitude at -32 is shorter than one of latitude.
      expect(haversineMetres(-32, 115, -32, 116), closeTo(111195 * 0.848, 200));
    });
  });

  group('endpoint proximity', () {
    test('counts exact, near and far endpoints per bucket', () {
      // lat offset 0.00001 deg ~= 1.11 m; 0.00005 ~= 5.56 m.
      SourceCoordinate c(double lng, double lat) => SourceCoordinate(longitude: lng, latitude: lat);
      MainRoadsNetworkSegment s(String id, SourceCoordinate a, SourceCoordinate b) => MainRoadsNetworkSegment(
            globalId: id,
            objectId: null,
            road: 'R',
            roadName: null,
            routeNeId: 1,
            startSlk: 0,
            endSlk: 1,
            startTrueDist: 0,
            endTrueDist: 1,
            networkType: null,
            networkCategory: null,
            maxNetwork: 1,
            geometry: [a, b],
          );
      final r = analyzeEndpointProximity([
        s('a', c(115.0, -32.0), c(115.0, -31.99)),
        s('b', c(115.0, -32.0), c(115.01, -31.99)), // exact with a's start
        s('c', c(115.2, -32.0), c(115.3, -32.0)),
        s('d', c(115.2, -32.00001), c(115.4, -32.0)), // ~1.11 m from c's start
        s('e', c(115.3, -32.00005), c(115.5, -32.0)), // ~5.56 m from c's end
      ]);
      expect(r.endpointCount, 10);
      expect(r.nearestOther['exact same coordinate'], 2);
      expect(r.nearestOther['>1 to 2 m'], 2); // c-start and d-start
      expect(r.nearestOther['>5 to 10 m'], 2); // c-end and e-start
      expect(r.nearestOther['>10 m'], 4);
      expect(r.nearestOther.values.fold<int>(0, (a, b) => a + b), r.endpointCount);
    });

    test('same-feature endpoints are not each other\'s neighbours', () {
      final r = analyzeEndpointProximity([
        seg('a', [[0, 0], [0.0001, 0]]), // ~0.01 m long: both ends only near each other
      ]);
      expect(r.nearestOther['>10 m'], 2);
    });
  });

  group('crossings', () {
    test('simple crossing without a shared vertex is reported, not a junction', () {
      final r = crossings([
        seg('a', [[0, 0], [2, 2]]),
        seg('b', [[0, 2], [2, 0]]),
      ]);
      expect(r.crossings, 1);
      expect(r.byKind, {'proper': 1});
      expect(r.details.single['roleA'], 'segmentInterior');
      expect(r.details.single['atEndpoint'], isFalse);
      expect(r.details.single['longitude'], closeTo(115.001, 1e-9));
      expect(r.details.single['latitude'], closeTo(-31.999, 1e-9));
    });

    test('crossing at an existing shared vertex is not unrepresented', () {
      final r = crossings([
        seg('a', [[0, 0], [1, 1], [2, 2]]),
        seg('b', [[0, 2], [1, 1], [2, 0]]),
      ]);
      expect(r.crossings, 0);
    });

    test('endpoint sitting on another segment interior is a touch', () {
      final r = crossings([
        seg('a', [[0, 0], [2, 0]]),
        seg('b', [[1, 0], [1, 1]]),
      ]);
      expect(r.byKind, {'touch': 1});
      expect(r.crossingsInvolvingEndpoint, 1);
      expect(r.details.single['roleB'], 'endpoint');
      expect(r.details.single['roleA'], 'segmentInterior');
    });

    test('parallel and disjoint lines do not cross', () {
      expect(crossings([
        seg('a', [[0, 0], [2, 0]]),
        seg('b', [[0, 1], [2, 1]]),
        seg('c', [[5, 0], [6, 1]]),
      ]).crossings, 0);
    });

    test('collinear overlap is reported unless both ends are shared vertices', () {
      final partial = crossings([
        seg('a', [[0, 0], [2, 0]]),
        seg('b', [[1, 0], [3, 0]]),
      ]);
      expect(partial.byKind, {'overlap': 1});
      final identical = crossings([
        seg('a', [[0, 0], [2, 0]]),
        seg('b', [[0, 0], [2, 0]]),
      ]);
      expect(identical.crossings, 0);
    });

    test('grid filter prunes distant segments', () {
      final r = crossings([
        for (var i = 0; i < 30; i++) seg('f$i', [[i * 100.0, 0], [i * 100.0 + 1, 1]]),
      ]);
      expect(r.crossings, 0);
      expect(r.candidatePairs, lessThan(r.naiveSegmentPairs));
      expect(r.candidatePairs, 0);
    });

    test('intersectSegments handles proper, miss and collinear cases', () {
      expect(intersectSegments(0, 0, 2, 2, 0, 2, 2, 0)!.kind, HitKind.proper);
      expect(intersectSegments(0, 0, 1, 1, 2, 2, 3, 3), isNull);
      expect(intersectSegments(0, 0, 1, 0, 1, 0, 2, 0)!.kind, HitKind.touch);
    });
  });

  group('geometry quality', () {
    test('identical duplicate geometry', () {
      final r = analyzeGeometryQuality([
        seg('a', [[0, 0], [1, 1]], road: 'R1', route: 1),
        seg('b', [[0, 0], [1, 1]], road: 'R1', route: 2),
      ]);
      expect(r.exactDuplicatePairs, 1);
      expect(r.reversedDuplicatePairs, 0);
      expect(r.duplicatePairsByRelation, {'exact: same ROAD, different ROUTE_NE_ID': 1});
    });

    test('reversed duplicate geometry', () {
      final r = analyzeGeometryQuality([
        seg('a', [[0, 0], [1, 1], [2, 0]], road: 'R1', route: 1),
        seg('b', [[2, 0], [1, 1], [0, 0]], road: 'R2', route: 1),
      ]);
      expect(r.reversedDuplicatePairs, 1);
      expect(r.exactDuplicatePairs, 0);
      expect(r.duplicatePairsByRelation, {'reversed: different ROAD, same ROUTE_NE_ID': 1});
    });

    test('zero-length consecutive vertices in an otherwise valid line', () {
      final r = analyzeGeometryQuality([
        seg('a', [[0, 0], [1, 0], [1, 0], [2, 0]]),
        seg('ok', [[5, 0], [6, 0]]),
      ]);
      expect(r.zeroLengthPairs, 1);
      expect(r.featuresWithZeroLengthPairs, 1);
      expect(r.degenerateFeatures, 0);
      expect(r.segmentLengthBuckets['exact same coordinate'], 1);
    });

    test('tiny segments are flagged by length in metres', () {
      // 0.000005 deg lat ~= 0.56 m
      final r = analyzeGeometryQuality([
        MainRoadsNetworkSegment(
          globalId: 't',
          objectId: null,
          road: 'R',
          roadName: null,
          routeNeId: 1,
          startSlk: 0,
          endSlk: 1,
          startTrueDist: 0,
          endTrueDist: 1,
          networkType: null,
          networkCategory: null,
          maxNetwork: 1,
          geometry: const [
            SourceCoordinate(longitude: 115, latitude: -32),
            SourceCoordinate(longitude: 115, latitude: -31.999995),
            SourceCoordinate(longitude: 115, latitude: -31.99),
          ],
        ),
      ]);
      expect(r.tinySegments, 1);
      expect(r.featuresWithTinySegments, 1);
      expect(r.segmentLengthBuckets['>0.5 to 1 m'], 1);
    });
  });

  group('retrieval and parsing', () {
    test('complete pagination yields COMPLETE with every page merged', () async {
      final f = await fetchLayerGeoJson(_service(total: 5), delay: Duration.zero);
      expect(f.complete, isTrue);
      expect(f.retrieved, 5);
      expect(f.pages, 3);
      final s = buildTopologySummary(f, generatedAt: 'now');
      expect(s['status'], 'COMPLETE');
      expect(s['recordCount'], 5);
      expect(s['analysis'], isNotNull);
      expect(renderTopologyReport(s), contains('Status: COMPLETE'));
    });

    test('maxPages reached is INCOMPLETE and produces no analysis', () async {
      final f = await fetchLayerGeoJson(_service(total: 10), maxPages: 2, delay: Duration.zero);
      expect(f.complete, isFalse);
      final s = buildTopologySummary(f, generatedAt: 'now');
      expect(s['status'], 'INCOMPLETE');
      expect(s.containsKey('analysis'), isFalse);
      expect(renderTopologyReport(s), contains('Status: INCOMPLETE'));
    });

    test('failed page is INCOMPLETE', () async {
      final f = await fetchLayerGeoJson(_service(total: 6, failOnSecondPage: true), delay: Duration.zero);
      expect(f.complete, isFalse);
      expect(f.incompleteReasons, isNotEmpty);
      expect(buildTopologySummary(f, generatedAt: 'now')['status'], 'INCOMPLETE');
    });

    test('count mismatch with the service total is INCOMPLETE', () async {
      final f = await fetchLayerGeoJson(_service(total: 4, serviceCount: 9), delay: Duration.zero);
      expect(f.complete, isFalse);
      expect(f.incompleteReasons.join(), contains('service reports 9'));
    });

    test('service still flagging exceededTransferLimit is INCOMPLETE', () async {
      final f = await fetchLayerGeoJson(_service(total: 4, serviceCount: 6, flagLastPage: true), delay: Duration.zero);
      expect(f.complete, isFalse);
    });

    test('malformed geometry fails the run rather than being skipped', () {
      final outcome = GeoJsonFetchOutcome(
        collection: {
          'type': 'FeatureCollection',
          'features': [
            geoFeature('g1', goodCoords(0)),
            geoFeature('g2', [[115.0, -32.0]]), // one vertex only
          ],
        },
        complete: true,
        pages: 1,
        expectedCount: 2,
        incompleteReasons: const [],
      );
      final s = buildTopologySummary(outcome, generatedAt: 'now');
      expect(s['status'], 'INCOMPLETE');
      expect((s['incompleteReasons'] as List).join(), contains('parser rejected'));
      expect(s.containsKey('analysis'), isFalse);
    });

    test('duplicate GlobalIDs across pages are rejected', () {
      final outcome = GeoJsonFetchOutcome(
        collection: {
          'type': 'FeatureCollection',
          'features': [geoFeature('dup', goodCoords(0)), geoFeature('dup', goodCoords(1))],
        },
        complete: true,
        pages: 2,
        expectedCount: 2,
        incompleteReasons: const [],
      );
      expect(buildTopologySummary(outcome, generatedAt: 'now')['status'], 'INCOMPLETE');
    });

    test('analysis rejects degenerate input instead of ignoring it', () {
      expect(() => CoordinateIndex.build([seg('x', [[0, 0]])]), throwsArgumentError);
    });
  });
}
