import 'main_roads_edge_source.dart';

/// A physical connection that can be traversed from one [RoadNode] to another.
///
/// Edges are DIRECTED: an edge may be travelled only from [fromNodeId] to
/// [toNodeId]. A two-way road is represented by two edges, one per direction.
/// This keeps one-way roads and future movement restrictions (which depend on
/// the incoming edge) possible without redesigning the graph.
///
/// Source metadata is not interpreted as routing eligibility or restrictions.
class RoadEdge {
  const RoadEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.lengthMetres,
    this.mainRoadsSource,
  }) : assert(lengthMetres >= 0, 'lengthMetres must not be negative');

  /// Stable identifier, unique within a [RoadGraph].
  final String id;

  /// Node this edge is travelled from.
  final String fromNodeId;

  /// Node this edge is travelled to.
  final String toNodeId;

  /// Physical length in metres; the basis for future routing cost.
  final double lengthMetres;

  /// Null for legacy or non-Main Roads edges.
  final MainRoadsEdgeSource? mainRoadsSource;

  /// Creates the opposite directed edge with the same source provenance.
  RoadEdge reversed({required String id}) => RoadEdge(
        id: id,
        fromNodeId: toNodeId,
        toNodeId: fromNodeId,
        lengthMetres: lengthMetres,
        mainRoadsSource: mainRoadsSource?.reversed(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoadEdge &&
          other.id == id &&
          other.fromNodeId == fromNodeId &&
          other.toNodeId == toNodeId &&
          other.lengthMetres == lengthMetres &&
          other.mainRoadsSource == mainRoadsSource;

  @override
  int get hashCode =>
      Object.hash(id, fromNodeId, toNodeId, lengthMetres, mainRoadsSource);

  @override
  String toString() =>
      'RoadEdge($id: $fromNodeId -> $toNodeId, ${lengthMetres}m)';
}
