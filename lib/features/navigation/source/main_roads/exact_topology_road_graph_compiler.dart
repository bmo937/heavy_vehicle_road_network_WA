import 'dart:math' as math;

import '../../domain/road_edge.dart';
import '../../domain/road_graph.dart';
import '../../domain/road_node.dart';
import 'main_roads_edge_builder.dart';
import 'main_roads_network_segment.dart';

typedef _CoordinateKey = (double longitude, double latitude);

/// Compiles Main Roads source features using exact source-coordinate topology.
///
/// Every part endpoint becomes a node. Coincident endpoints from separate parts
/// of one feature remain part-scoped unless another source feature establishes
/// a junction at that coordinate. An internal source vertex becomes a node only
/// when the exact same coordinate appears in a different source feature.
/// Nearby coordinates are never snapped and unrepresented geometric crossings
/// are never converted into junctions.
class ExactTopologyRoadGraphCompiler {
  const ExactTopologyRoadGraphCompiler();

  RoadGraph compile(Iterable<MainRoadsNetworkSegment> source) {
    final segments = List<MainRoadsNetworkSegment>.unmodifiable(source);
    final firstFeatureByCoordinate = <_CoordinateKey, int>{};
    final sharedAcrossFeatures = <_CoordinateKey>{};

    for (var featureIndex = 0; featureIndex < segments.length; featureIndex++) {
      final segment = segments[featureIndex];
      for (final part in segment.parts) {
        if (part.length < 2) {
          throw ArgumentError(
            'Feature ${segment.globalId} contains a part with fewer than two vertices',
          );
        }
        for (final coordinate in part) {
          final key = _key(coordinate);
          final firstFeature = firstFeatureByCoordinate[key];
          if (firstFeature == null) {
            firstFeatureByCoordinate[key] = featureIndex;
          } else if (firstFeature != featureIndex) {
            sharedAcrossFeatures.add(key);
          }
        }
      }
    }

    final nodesById = <String, RoadNode>{};
    String nodeIdFor(
      MainRoadsNetworkSegment segment,
      int partIndex,
      SourceCoordinate coordinate,
    ) {
      final key = _key(coordinate);
      final id = sharedAcrossFeatures.contains(key)
          ? exactCoordinateNodeId(
              longitude: key.$1,
              latitude: key.$2,
            )
          : partScopedNodeId(
              globalId: segment.globalId,
              partIndex: partIndex,
              longitude: key.$1,
              latitude: key.$2,
            );
      nodesById.putIfAbsent(
        id,
        () => RoadNode(
          id: id,
          longitude: key.$1,
          latitude: key.$2,
        ),
      );
      return id;
    }

    final edges = <RoadEdge>[];
    for (final segment in segments) {
      for (var partIndex = 0; partIndex < segment.parts.length; partIndex++) {
        final part = segment.parts[partIndex];
        final splitVertices = <int>[0];
        for (var vertex = 1; vertex < part.length - 1; vertex++) {
          if (sharedAcrossFeatures.contains(_key(part[vertex]))) {
            splitVertices.add(vertex);
          }
        }
        splitVertices.add(part.length - 1);

        for (var split = 0; split < splitVertices.length - 1; split++) {
          final start = splitVertices[split];
          final end = splitVertices[split + 1];
          final from = nodeIdFor(segment, partIndex, part[start]);
          final to = nodeIdFor(segment, partIndex, part[end]);
          final baseId = '${segment.globalId}:p$partIndex:v$start-$end';
          final length = _polylineLengthMetres(part, start, end);
          edges.add(
            mainRoadsEdgeFromSegment(
              segment: segment,
              partIndex: partIndex,
              startVertex: start,
              endVertex: end,
              id: '$baseId:f',
              fromNodeId: from,
              toNodeId: to,
              lengthMetres: length,
            ),
          );
          edges.add(
            mainRoadsEdgeFromSegment(
              segment: segment,
              partIndex: partIndex,
              startVertex: start,
              endVertex: end,
              id: '$baseId:r',
              fromNodeId: to,
              toNodeId: from,
              lengthMetres: length,
              reverse: true,
            ),
          );
        }
      }
    }

    final nodes = nodesById.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return RoadGraph(nodes: nodes, edges: edges);
  }
}

/// Stable node identity for an exact coordinate shared across source features.
String exactCoordinateNodeId({
  required double longitude,
  required double latitude,
}) =>
    'coordinate:${_canonical(longitude)},${_canonical(latitude)}';

/// Stable endpoint identity confined to one source feature part.
String partScopedNodeId({
  required String globalId,
  required int partIndex,
  required double longitude,
  required double latitude,
}) =>
    'part:$globalId:$partIndex:${_canonical(longitude)},${_canonical(latitude)}';

String _canonical(double value) => value == 0 ? '0.0' : value.toString();

_CoordinateKey _key(SourceCoordinate coordinate) => (
      coordinate.longitude == 0 ? 0.0 : coordinate.longitude,
      coordinate.latitude == 0 ? 0.0 : coordinate.latitude
    );

double _polylineLengthMetres(
  List<SourceCoordinate> part,
  int start,
  int end,
) {
  var length = 0.0;
  for (var i = start; i < end; i++) {
    length += _haversineMetres(part[i], part[i + 1]);
  }
  return length;
}

double _haversineMetres(SourceCoordinate a, SourceCoordinate b) {
  const radius = 6371008.8;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final deltaLat = lat2 - lat1;
  final deltaLongitude = (b.longitude - a.longitude) * math.pi / 180;
  final value = math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.pow(math.sin(deltaLongitude / 2), 2);
  return 2 * radius * math.asin(math.min(1, math.sqrt(value)));
}
