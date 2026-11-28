import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/features/navigation/domain/main_roads_edge_source.dart';
import 'package:roads_map/features/navigation/domain/road_graph.dart';
import 'package:roads_map/features/navigation/domain/road_node.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_edge_builder.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_parser.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

const coordinates = [
  SourceCoordinate(latitude: -31.0, longitude: 115.0),
  SourceCoordinate(latitude: -31.1, longitude: 115.1),
  SourceCoordinate(latitude: -31.2, longitude: 115.2),
  SourceCoordinate(latitude: -31.3, longitude: 115.3),
  SourceCoordinate(latitude: -31.4, longitude: 115.4),
];

MainRoadsNetworkSegment parseSegment({bool nullable = false}) {
  return const MainRoadsNetworkParser().parseFeatureCollection({
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': {
          'GlobalID': 'original-feature',
          'OBJECTID': nullable ? null : 42,
          'ROAD': 'H001',
          'ROAD_NAME': nullable ? null : 'Highway',
          'ROUTE_NE_ID': 23,
          'START_SLK': 1.0,
          'END_SLK': 9.0,
          'START_TRUE_DIST': 1.2,
          'END_TRUE_DIST': 9.2,
          'NETWORK_TYPE': nullable ? null : 'Tandem Drive',
          'NETWORK_CATEGORY': nullable ? null : 'Network 1',
          'MAX_NETWORK': 1,
        },
        'geometry': {
          'type': 'MultiLineString',
          'coordinates': [
            [
              for (final c in coordinates) [c.longitude, c.latitude]
            ],
            [
              [116.0, -32.0],
              [116.1, -32.1],
            ],
          ],
        },
      },
    ],
  }).single;
}

RoadNode node(String id, SourceCoordinate c) =>
    RoadNode(id: id, latitude: c.latitude, longitude: c.longitude);

void main() {
  test('validates geometry length and reports the source part and range', () {
    final provenance = mainRoadsEdgeFromSegment(
      segment: parseSegment(),
      partIndex: 0,
      startVertex: 0,
      endVertex: 1,
      id: 'edge',
      fromNodeId: 'a',
      toNodeId: 'b',
      lengthMetres: 1,
    ).mainRoadsSource!.provenance;

    for (final (part, start, end, geometry) in [
      (2, 0, 10, coordinates.sublist(0, 2)),
      (3, 1, 2, coordinates.sublist(0, 3)),
      (4, 1, 2, coordinates.sublist(0, 1)),
      (-1, 0, 1, coordinates.sublist(0, 2)),
      (5, -1, 1, coordinates.sublist(0, 3)),
      (6, 2, 2, coordinates.sublist(0, 1)),
    ]) {
      expect(
        () => MainRoadsEdgeSource(
          provenance: provenance,
          partIndex: part,
          startVertexIndex: start,
          endVertexIndex: end,
          geometry: geometry,
          isReversed: false,
        ),
        throwsA(
          isA<ArgumentError>()
              .having(
                  (error) => error.message, 'message', contains('part $part'))
              .having((error) => error.message, 'message',
                  contains('$start..$end')),
        ),
      );
    }

    final source = MainRoadsEdgeSource(
      provenance: provenance,
      partIndex: 1,
      startVertexIndex: 1,
      endVertexIndex: 3,
      geometry: coordinates.sublist(1, 4),
      isReversed: false,
    );
    expect(source.reversed().reversed(), source);
  });

  test('parsed source attributes and intermediate geometry survive in a graph',
      () {
    final segment = parseSegment();
    final edge = mainRoadsEdgeFromSegment(
      segment: segment,
      partIndex: 0,
      startVertex: 0,
      endVertex: 4,
      id: 'generated-edge',
      fromNodeId: 'a',
      toNodeId: 'b',
      lengthMetres: 100,
    );
    final graph = RoadGraph(
      nodes: [node('a', coordinates.first), node('b', coordinates.last)],
      edges: [edge],
    );
    final source = graph.edgeById('generated-edge')!.mainRoadsSource!;
    final provenance = source.provenance;
    expect(provenance.globalId, 'original-feature');
    expect(provenance.objectId, 42);
    expect(provenance.road, 'H001');
    expect(provenance.roadName, 'Highway');
    expect(provenance.routeNeId, 23);
    expect(provenance.startSlk, 1.0);
    expect(provenance.endSlk, 9.0);
    expect(provenance.startTrueDist, 1.2);
    expect(provenance.endTrueDist, 9.2);
    expect(provenance.networkType, 'Tandem Drive');
    expect(provenance.networkCategory, 'Network 1');
    expect(provenance.maxNetwork, 1);
    expect(source.geometry, coordinates);
    expect(source.isReversed, isFalse);
    expect(() => source.geometry.clear(), throwsUnsupportedError);
  });

  test('explicit slices share feature identity but not geometry', () {
    final segment = parseSegment();
    final first = mainRoadsEdgeFromSegment(
      segment: segment,
      partIndex: 0,
      startVertex: 0,
      endVertex: 2,
      id: 'first',
      fromNodeId: 'a',
      toNodeId: 'b',
      lengthMetres: 50,
    );
    final second = mainRoadsEdgeFromSegment(
      segment: segment,
      partIndex: 0,
      startVertex: 2,
      endVertex: 4,
      id: 'second',
      fromNodeId: 'b',
      toNodeId: 'c',
      lengthMetres: 50,
    );
    final graph = RoadGraph(
      nodes: [
        node('a', coordinates[0]),
        node('b', coordinates[2]),
        node('c', coordinates[4]),
      ],
      edges: [first, second],
    );
    final a = graph.edgeById('first')!.mainRoadsSource!;
    final b = graph.edgeById('second')!.mainRoadsSource!;
    expect(a.provenance, b.provenance);
    expect(a.provenance.globalId, 'original-feature');
    expect(a.geometry, coordinates.sublist(0, 3));
    expect(b.geometry, coordinates.sublist(2, 5));

    final reverse = first.reversed(id: 'reverse');
    expect(reverse.fromNodeId, 'b');
    expect(reverse.toNodeId, 'a');
    expect(
        reverse.mainRoadsSource!.geometry, coordinates.sublist(0, 3).reversed);
    expect(reverse.mainRoadsSource!.provenance, same(a.provenance));
    expect(reverse.mainRoadsSource!.isReversed, isTrue);
    expect(reverse.reversed(id: 'first'), first);
    expect(
      RoadGraph(
          nodes: [node('a', coordinates[0]), node('b', coordinates[2])],
          edges: [reverse]).outgoingEdges('b'),
      [reverse],
    );
  });

  test(
      'nullable attributes remain null and reverse construction uses source order',
      () {
    final edge = mainRoadsEdgeFromSegment(
      segment: parseSegment(nullable: true),
      partIndex: 0,
      startVertex: 1,
      endVertex: 3,
      id: 'reverse',
      fromNodeId: 'b',
      toNodeId: 'a',
      lengthMetres: 20,
      reverse: true,
    );
    final source = edge.mainRoadsSource!;
    expect(source.provenance.objectId, isNull);
    expect(source.provenance.roadName, isNull);
    expect(source.provenance.networkType, isNull);
    expect(source.provenance.networkCategory, isNull);
    expect(source.geometry, coordinates.sublist(1, 4).reversed);
    expect(source.isReversed, isTrue);
    expect(edge.reversed(id: 'forward').mainRoadsSource!.isReversed, isFalse);
  });

  test('a multipart edge contains only the selected source part', () {
    final segment = parseSegment();
    final edge = mainRoadsEdgeFromSegment(
      segment: segment,
      partIndex: 1,
      startVertex: 0,
      endVertex: 1,
      id: 'part-two',
      fromNodeId: 'a',
      toNodeId: 'b',
      lengthMetres: 10,
    );
    expect(edge.mainRoadsSource!.provenance.globalId, 'original-feature');
    expect(edge.mainRoadsSource!.geometry, segment.parts[1]);
    expect(edge.mainRoadsSource!.geometry, isNot(contains(coordinates.last)));
    expect(
      RoadGraph(
        nodes: [
          node('a', segment.parts[1].first),
          node('b', segment.parts[1].last),
        ],
        edges: [edge],
      ).edges,
      [edge],
    );
  });

  test('rejects invalid slices and mismatched directed nodes', () {
    final segment = parseSegment();
    for (final (part, start, end) in [
      (-1, 0, 1),
      (2, 0, 1),
      (0, -1, 1),
      (0, 1, 1),
      (0, 2, 1),
      (1, 0, 2),
    ]) {
      expect(
        () => mainRoadsEdgeFromSegment(
          segment: segment,
          partIndex: part,
          startVertex: start,
          endVertex: end,
          id: 'bad',
          fromNodeId: 'a',
          toNodeId: 'b',
          lengthMetres: 1,
        ),
        throwsRangeError,
      );
    }
    final edge = mainRoadsEdgeFromSegment(
      segment: segment,
      partIndex: 0,
      startVertex: 0,
      endVertex: 2,
      id: 'edge',
      fromNodeId: 'a',
      toNodeId: 'b',
      lengthMetres: 1,
    );
    expect(
      () => RoadGraph(
        nodes: [node('a', coordinates[2]), node('b', coordinates[0])],
        edges: [edge],
      ),
      throwsArgumentError,
    );
  });
}
