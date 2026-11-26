import 'package:roads_map/features/navigation/domain/road_edge.dart';
import 'package:roads_map/features/navigation/domain/road_graph.dart';
import 'package:roads_map/features/navigation/domain/road_node.dart';

void main() {
  const nodes = [
    RoadNode(id: 'a', latitude: 0, longitude: 0),
    RoadNode(id: 'b', latitude: 0, longitude: 0),
  ];
  final negative = RoadEdge(
    id: 'negative',
    fromNodeId: 'a',
    toNodeId: 'b',
    lengthMetres: double.parse('-1'),
  );
  try {
    RoadGraph(nodes: nodes, edges: [negative]);
  } on ArgumentError {
    const zero = RoadEdge(
      id: 'zero',
      fromNodeId: 'a',
      toNodeId: 'b',
      lengthMetres: 0,
    );
    if (RoadGraph(nodes: nodes, edges: [zero]).edgeById('zero') != zero) {
      throw StateError('Zero-length edge was not retained');
    }
    return;
  }
  throw StateError('Negative edge length was accepted');
}
