import '../../domain/main_roads_edge_source.dart';
import '../../domain/road_edge.dart';
import 'main_roads_network_segment.dart';

/// Creates an edge for an explicitly selected, inclusive source-vertex slice.
///
/// This does not discover junctions, split lines, calculate lengths, or decide
/// whether the edge is traversable. Indices always refer to source order;
/// [reverse] only changes the direction of the resulting edge.
RoadEdge mainRoadsEdgeFromSegment({
  required MainRoadsNetworkSegment segment,
  required int partIndex,
  required int startVertex,
  required int endVertex,
  required String id,
  required String fromNodeId,
  required String toNodeId,
  required double lengthMetres,
  bool reverse = false,
}) {
  RangeError.checkValidIndex(partIndex, segment.parts, 'partIndex');
  final part = segment.parts[partIndex];
  if (startVertex < 0 || endVertex >= part.length || startVertex >= endVertex) {
    throw RangeError('Invalid source vertex slice: $startVertex..$endVertex');
  }
  final geometry = part.sublist(startVertex, endVertex + 1);
  return RoadEdge(
    id: id,
    fromNodeId: fromNodeId,
    toNodeId: toNodeId,
    lengthMetres: lengthMetres,
    mainRoadsSource: MainRoadsEdgeSource(
      provenance: MainRoadsEdgeProvenance(
        globalId: segment.globalId,
        objectId: segment.objectId,
        road: segment.road,
        roadName: segment.roadName,
        routeNeId: segment.routeNeId,
        startSlk: segment.startSlk,
        endSlk: segment.endSlk,
        startTrueDist: segment.startTrueDist,
        endTrueDist: segment.endTrueDist,
        networkType: segment.networkType,
        networkCategory: segment.networkCategory,
        maxNetwork: segment.maxNetwork,
      ),
      partIndex: partIndex,
      startVertexIndex: startVertex,
      endVertexIndex: endVertex,
      geometry: reverse ? geometry.reversed : geometry,
      isReversed: reverse,
    ),
  );
}
