import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/features/navigation/source/main_roads/exact_topology_road_graph_compiler.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

SourceCoordinate c(double longitude, double latitude) =>
    SourceCoordinate(longitude: longitude, latitude: latitude);

MainRoadsNetworkSegment segment(
  String id,
  List<List<SourceCoordinate>> parts,
) =>
    MainRoadsNetworkSegment(
      globalId: id,
      objectId: null,
      road: 'ROAD-$id',
      roadName: null,
      routeNeId: id.hashCode,
      startSlk: 0,
      endSlk: 1,
      startTrueDist: 0,
      endTrueDist: 1,
      networkType: null,
      networkCategory: null,
      maxNetwork: 1,
      parts: parts,
    );

bool hasPath(dynamic graph, String start, String target) {
  final pending = <String>[start];
  final visited = <String>{};
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (current == target) return true;
    if (!visited.add(current)) continue;
    for (final edge in graph.outgoingEdges(current)) {
      pending.add(edge.toNodeId);
    }
  }
  return false;
}

void main() {
  const compiler = ExactTopologyRoadGraphCompiler();

  test('merges exact endpoints and creates directed edge pairs', () {
    final graph = compiler.compile([
      segment('a', [
        [c(115, -32), c(116, -32)]
      ]),
      segment('b', [
        [c(116, -32), c(117, -32)]
      ]),
    ]);

    expect(graph.nodes.length, 3);
    expect(graph.edges.length, 4);
    final shared = exactCoordinateNodeId(longitude: 116, latitude: -32);
    expect(graph.nodeById(shared), isNotNull);
    expect(graph.outgoingEdges(shared).length, 2);
  });

  test('splits at exact endpoint on another feature internal vertex', () {
    final graph = compiler.compile([
      segment('trunk', [
        [c(115, -32), c(116, -32), c(117, -32)]
      ]),
      segment('branch', [
        [c(116, -32), c(116, -31)]
      ]),
    ]);

    expect(graph.nodes.length, 4);
    expect(graph.edges.length, 6);
    final trunk = graph.edges
        .where((edge) => edge.mainRoadsSource!.provenance.globalId == 'trunk')
        .toList();
    expect(trunk.length, 4);
    expect(
      trunk.map((edge) => (
            edge.mainRoadsSource!.startVertexIndex,
            edge.mainRoadsSource!.endVertexIndex,
          )),
      containsAll([(0, 1), (1, 2)]),
    );
  });

  test('splits both features at an exact shared internal vertex', () {
    final graph = compiler.compile([
      segment('horizontal', [
        [c(115, -32), c(116, -32), c(117, -32)]
      ]),
      segment('vertical', [
        [c(116, -33), c(116, -32), c(116, -31)]
      ]),
    ]);

    expect(graph.nodes.length, 5);
    expect(graph.edges.length, 8);
    expect(
      graph
          .outgoingEdges(
            exactCoordinateNodeId(longitude: 116, latitude: -32),
          )
          .length,
      4,
    );
  });

  test('coincident endpoints in separate parts remain disconnected', () {
    final graph = compiler.compile([
      segment('multi', [
        [c(115, -32), c(116, -32)],
        [c(116, -32), c(117, -32)],
      ]),
    ]);

    expect(graph.nodes.length, 4);
    expect(graph.edges.length, 4);
    final left = partScopedNodeId(
      globalId: 'multi',
      partIndex: 0,
      longitude: 115,
      latitude: -32,
    );
    final right = partScopedNodeId(
      globalId: 'multi',
      partIndex: 1,
      longitude: 117,
      latitude: -32,
    );
    expect(hasPath(graph, left, right), isFalse);
    expect(
      graph.edges.map((edge) => edge.mainRoadsSource!.partIndex).toSet(),
      {0, 1},
    );
  });

  test('a different feature connects repeated coordinates across parts', () {
    final graph = compiler.compile([
      segment('multi', [
        [c(115, -32), c(116, -32)],
        [c(116, -32), c(117, -32)],
      ]),
      segment('branch', [
        [c(116, -32), c(116, -31)],
      ]),
      segment('another', [
        [c(116, -32), c(116, -33)],
      ]),
    ]);

    final shared = exactCoordinateNodeId(longitude: 116, latitude: -32);
    expect(graph.nodes.length, 5);
    expect(graph.outgoingEdges(shared).length, 4);
    expect(
      hasPath(
        graph,
        partScopedNodeId(
            globalId: 'multi', partIndex: 0, longitude: 115, latitude: -32),
        partScopedNodeId(
            globalId: 'multi', partIndex: 1, longitude: 117, latitude: -32),
      ),
      isTrue,
    );
  });

  test('repeated internal coordinates within one feature do not split', () {
    final graph = compiler.compile([
      segment('multi', [
        [c(115, -32), c(116, -32), c(117, -32)],
        [c(118, -32), c(116, -32), c(119, -32)],
      ]),
    ]);

    expect(graph.nodes.length, 4);
    expect(graph.edges.length, 4);
    expect(
        graph.edges.every((edge) => edge.mainRoadsSource!.geometry.length == 3),
        isTrue);
  });

  test('does not snap near endpoints or create a node at a geometric crossing',
      () {
    final graph = compiler.compile([
      segment('a', [
        [c(115, -32), c(117, -30)]
      ]),
      segment('b', [
        [c(115, -30), c(117, -32)]
      ]),
      segment('near', [
        [c(117.0000001, -30), c(118, -30)]
      ]),
    ]);

    expect(graph.nodes.length, 6);
    expect(graph.edges.length, 6);
    expect(
      graph.nodeById(
        exactCoordinateNodeId(longitude: 116, latitude: -31),
      ),
      isNull,
    );
  });

  test('measures every segment of an unsplit bent polyline in metres', () {
    final graph = compiler.compile([
      segment('bent', [
        [c(0, 0), c(0, 1), c(1, 1)]
      ]),
    ]);

    expect(graph.edges.length, 2);
    for (final edge in graph.edges) {
      expect(edge.mainRoadsSource!.geometry.length, 3);
      expect(edge.lengthMetres, closeTo(222373, 10));
    }
  });

  test('node and edge identities are deterministic', () {
    final source = [
      segment('a', [
        [c(115, -32), c(116, -32)]
      ]),
    ];
    final first = compiler.compile(source);
    final second = compiler.compile(source);

    expect(first.nodes.map((node) => node.id),
        second.nodes.map((node) => node.id));
    expect(first.edges.map((edge) => edge.id),
        second.edges.map((edge) => edge.id));
    expect(first.edges.first.lengthMetres, greaterThan(0));
  });
}
