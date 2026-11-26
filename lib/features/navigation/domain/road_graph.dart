import 'road_edge.dart';
import 'road_node.dart';

/// An immutable directed graph of [RoadNode]s and [RoadEdge]s.
///
/// Invariants enforced at construction (violations throw [ArgumentError]):
/// - node IDs are unique;
/// - edge IDs are unique;
/// - every edge's `fromNodeId` and `toNodeId` refer to a node in the graph.
///
/// Lookups of unknown IDs return null (or an empty list for outgoing edges);
/// they never throw.
class RoadGraph {
  factory RoadGraph({
    required Iterable<RoadNode> nodes,
    required Iterable<RoadEdge> edges,
  }) {
    final nodesById = <String, RoadNode>{};
    for (final node in nodes) {
      if (nodesById.containsKey(node.id)) {
        throw ArgumentError('Duplicate node id: ${node.id}');
      }
      nodesById[node.id] = node;
    }

    final edgesById = <String, RoadEdge>{};
    final outgoing = <String, List<RoadEdge>>{};
    for (final edge in edges) {
      if (edgesById.containsKey(edge.id)) {
        throw ArgumentError('Duplicate edge id: ${edge.id}');
      }
      if (!nodesById.containsKey(edge.fromNodeId)) {
        throw ArgumentError(
          'Edge ${edge.id} references missing from-node: ${edge.fromNodeId}',
        );
      }
      if (!nodesById.containsKey(edge.toNodeId)) {
        throw ArgumentError(
          'Edge ${edge.id} references missing to-node: ${edge.toNodeId}',
        );
      }
      edgesById[edge.id] = edge;
      outgoing.putIfAbsent(edge.fromNodeId, () => []).add(edge);
    }

    return RoadGraph._(
      Map.unmodifiable(nodesById),
      Map.unmodifiable(edgesById),
      Map.unmodifiable({
        for (final entry in outgoing.entries)
          entry.key: List<RoadEdge>.unmodifiable(entry.value),
      }),
    );
  }

  const RoadGraph._(this._nodesById, this._edgesById, this._outgoingByNodeId);

  final Map<String, RoadNode> _nodesById;
  final Map<String, RoadEdge> _edgesById;
  final Map<String, List<RoadEdge>> _outgoingByNodeId;

  Iterable<RoadNode> get nodes => _nodesById.values;
  Iterable<RoadEdge> get edges => _edgesById.values;

  /// The node with [id], or null if there is none.
  RoadNode? nodeById(String id) => _nodesById[id];

  /// The edge with [id], or null if there is none.
  RoadEdge? edgeById(String id) => _edgesById[id];

  /// Edges that can be travelled away from [nodeId], in insertion order.
  /// Empty for a dead-end or unknown node.
  List<RoadEdge> outgoingEdges(String nodeId) =>
      _outgoingByNodeId[nodeId] ?? const [];

  /// The node an [edge] leads to. Null if [edge] is not part of this graph.
  RoadNode? destinationOf(RoadEdge edge) =>
      _edgesById[edge.id] == edge ? _nodesById[edge.toNodeId] : null;
}
