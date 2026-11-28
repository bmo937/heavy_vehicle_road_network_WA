import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

import '../../tool/main_roads_topology_probe/endpoint_segment_proximity.dart';

MainRoadsNetworkSegment feature(String id, List<List<List<double>>> parts,
        {String road = 'R', int route = 1}) =>
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
      parts: [
        for (final part in parts)
          [
            for (final p in part)
              SourceCoordinate(longitude: 115 + p[0], latitude: -32 + p[1]),
          ],
      ],
    );

void main() {
  test('finds an endpoint near another feature segment interior', () {
    final r = analyzeEndpointSegmentProximity([
      feature('source', [
        [
          [0, 0.00001],
          [0, 0.001]
        ],
      ]),
      feature('target', [
        [
          [-0.001, 0],
          [0.001, 0]
        ],
      ]),
    ]);
    expect(r.eligibleEndpointCount, 4);
    final d = r.details.firstWhere((x) => x['sourceGlobalId'] == 'source');
    expect(d['targetLocation'], 'segmentInterior');
    expect(d['distanceMetres'], closeTo(1.11, 0.1));
  });

  test('finds long diagonal segments through piecewise grid registration', () {
    final r = analyzeEndpointSegmentProximity([
      feature('source', [
        [
          [0.0375, 0.03201],
          [0.0375, 0.033],
        ],
      ]),
      feature('long-target', [
        [
          [0, 0],
          [0.075, 0.064],
        ],
      ]),
    ]);

    final d = r.details.firstWhere((x) => x['sourceGlobalId'] == 'source');
    expect(d['targetGlobalId'], 'long-target');
    expect(d['targetLocation'], 'segmentInterior');
    expect(d['distanceMetres'], closeTo(0.784, 0.01));
  });

  test('finds an oversized segment interior through the fallback', () {
    final r = analyzeEndpointSegmentProximity([
      feature('source', [
        [
          [15, 0.00001],
          [15, 0.001]
        ],
      ]),
      feature('long-target', [
        [
          [0, 0],
          [30, 0]
        ],
      ]),
    ]);

    final d = r.details.firstWhere((x) => x['sourceGlobalId'] == 'source');
    expect(d['targetGlobalId'], 'long-target');
    expect(d['targetLocation'], 'segmentInterior');
    expect(d['distanceMetres'], closeTo(1.11, 0.1));
  });

  test('falls back when unique cells exceed the budget before pieces do', () {
    final r = analyzeEndpointSegmentProximity([
      feature('long-target', [
        [
          [0, 0],
          [4, 4]
        ],
      ]),
      feature('short-target', [
        [
          [1.999, 2],
          [2.001, 2]
        ],
      ]),
      feature('source', [
        [
          [2, 2],
          [2, 2.001]
        ],
      ]),
    ]);

    final d = r.details.firstWhere(
      (x) => x['sourceGlobalId'] == 'source' && x['sourceEndpoint'] == 'start',
    );
    expect(d['targetGlobalId'], 'short-target');
    expect(d['targetLocation'], 'segmentInterior');
    expect(d['distanceMetres'], 0);

    final fallback = analyzeEndpointSegmentProximity([
      feature('long-target', [
        [
          [0, 0],
          [4, 4]
        ],
      ]),
      feature('source', [
        [
          [3, 3],
          [3, 3.001]
        ],
      ]),
    ]);
    final fallbackMatch = fallback.details.firstWhere(
      (x) => x['sourceGlobalId'] == 'source' && x['sourceEndpoint'] == 'start',
    );
    expect(fallbackMatch['targetGlobalId'], 'long-target');
    expect(fallbackMatch['targetLocation'], 'segmentInterior');
    expect(fallbackMatch['distanceMetres'], closeTo(0, 0.000001));
  });

  test('requires a finite search radius of at least 10 metres', () {
    final features = [
      feature('a', [
        [
          [0, 0],
          [0, 0.001],
        ],
      ]),
    ];

    for (final radius in [2.0, 9.99, double.nan, double.infinity]) {
      expect(
        () => analyzeEndpointSegmentProximity(features, radiusMetres: radius),
        throwsArgumentError,
      );
    }
  });

  test('excludes exact endpoint partners from eligible population', () {
    final r = analyzeEndpointSegmentProximity([
      feature('a', [
        [
          [0, 0],
          [0, 0.001]
        ],
      ]),
      feature('b', [
        [
          [0, 0],
          [0.001, 0]
        ],
      ]),
    ]);
    expect(r.eligibleEndpointCount, 2);
  });

  test('excludes other parts of the same source feature', () {
    final r = analyzeEndpointSegmentProximity([
      feature('multipart', [
        [
          [0, 0.00001],
          [0, 0.001]
        ],
        [
          [-0.001, 0],
          [0.001, 0]
        ],
      ]),
    ]);
    expect(r.withinRadiusCount, 0);
  });

  test('classifies a target endpoint separately from segment interior', () {
    final r = analyzeEndpointSegmentProximity([
      feature('source', [
        [
          [0.00001, 0],
          [0, 0.001]
        ],
      ]),
      feature('target', [
        [
          [0, 0],
          [-0.001, 0]
        ],
      ]),
    ]);
    final d = r.details.firstWhere((x) => x['sourceGlobalId'] == 'source');
    expect(d['targetLocation'], 'segmentStart');
  });

  test('retains aggregate counts when detail is truncated', () {
    final features = [
      feature('target', [
        [
          [-0.001, 0],
          [0.001, 0]
        ],
      ]),
      feature('a', [
        [
          [0, 0.00001],
          [0, 0.001]
        ],
      ]),
      feature('b', [
        [
          [0.0001, 0.00001],
          [0.0001, 0.001]
        ],
      ]),
    ];
    final full = analyzeEndpointSegmentProximity(features, detailLimit: 100);
    final cut = analyzeEndpointSegmentProximity(features, detailLimit: 1);
    expect(cut.withinRadiusCount, full.withinRadiusCount);
    expect(
        cut.nearestSegmentDistanceBuckets, full.nearestSegmentDistanceBuckets);
    expect(cut.detailsTruncated, isTrue);
  });
}
