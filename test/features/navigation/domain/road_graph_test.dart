import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/features/navigation/domain/road_edge.dart';
import 'package:roads_map/features/navigation/domain/road_graph.dart';
import 'package:roads_map/features/navigation/domain/road_node.dart';

RoadNode node(String id) => RoadNode(id: id, latitude: -31.9, longitude: 115.8);
RoadEdge edge(String id, String from, String to) =>
    RoadEdge(id: id, fromNodeId: from, toNodeId: to, lengthMetres: 100);

void main() {
  group('RoadNode', () {
    test('construction and value equality', () {
      const a = RoadNode(id: 'a', latitude: -31.95, longitude: 115.86);
      const b = RoadNode(id: 'a', latitude: -31.95, longitude: 115.86);
      expect(a.latitude, -31.95);
      expect(a.longitude, 115.86);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const RoadNode(id: 'a', latitude: 0, longitude: 0)));
      expect({a, ...[b]}.length, 1);
    });
  });

  group('RoadEdge', () {
    test('construction and value equality', () {
      final e = edge('e1', 'a', 'b');
      expect(e.fromNodeId, 'a');
      expect(e.toNodeId, 'b');
      expect(e.lengthMetres, 100);
      expect(e, edge('e1', 'a', 'b'));
    });

    test('is directed: reverse edge is a different edge', () {
      expect(edge('e1', 'a', 'b'), isNot(edge('e1', 'b', 'a')));
    });
  });

  group('RoadGraph', () {
    // a -> b, a -> c, b -> a ; c is a dead end.
    final ab = edge('ab', 'a', 'b');
    final ac = edge('ac', 'a', 'c');
    final ba = edge('ba', 'b', 'a');
    RoadGraph buildGraph() => RoadGraph(
          nodes: [node('a'), node('b'), node('c')],
          edges: [ab, ac, ba],
        );

    test('valid construction and lookups', () {
      final g = buildGraph();
      expect(g.nodes.length, 3);
      expect(g.edges.length, 3);
      expect(g.nodeById('b'), node('b'));
      expect(g.edgeById('ac'), ac);
    });

    test('outgoing edges are directed and ordered', () {
      final g = buildGraph();
      expect(g.outgoingEdges('a'), [ab, ac]);
      expect(g.outgoingEdges('b'), [ba]);
    });

    test('node with no outgoing edges returns empty list', () {
      expect(buildGraph().outgoingEdges('c'), isEmpty);
    });

    test('destination resolution', () {
      final g = buildGraph();
      expect(g.destinationOf(ab), node('b'));
      expect(g.destinationOf(ba), node('a'));
      expect(g.destinationOf(edge('zz', 'a', 'b')), isNull);
    });

    test('unknown ids are handled deterministically', () {
      final g = buildGraph();
      expect(g.nodeById('nope'), isNull);
      expect(g.edgeById('nope'), isNull);
      expect(g.outgoingEdges('nope'), isEmpty);
    });

    test('rejects edge with missing from-node', () {
      expect(
        () => RoadGraph(nodes: [node('a')], edges: [edge('e', 'x', 'a')]),
        throwsArgumentError,
      );
    });

    test('rejects edge with missing to-node', () {
      expect(
        () => RoadGraph(nodes: [node('a')], edges: [edge('e', 'a', 'x')]),
        throwsArgumentError,
      );
    });

    test('rejects duplicate node ids', () {
      expect(
        () => RoadGraph(nodes: [node('a'), node('a')], edges: const []),
        throwsArgumentError,
      );
    });

    test('rejects duplicate edge ids', () {
      expect(
        () => RoadGraph(
          nodes: [node('a'), node('b')],
          edges: [edge('e', 'a', 'b'), edge('e', 'b', 'a')],
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative edge lengths without assertions', () async {
      final result = await Process.run('dart', [
        'run',
        '--no-enable-asserts',
        'test/features/navigation/domain/road_graph_release_check.dart',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    });

    test('outgoing list is unmodifiable', () {
      expect(() => buildGraph().outgoingEdges('a').add(ba),
          throwsUnsupportedError);
    });
  });
}
