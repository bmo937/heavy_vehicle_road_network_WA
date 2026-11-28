import 'dart:math' as math;

import '../../domain/road_edge.dart';
import '../../domain/road_graph.dart';
import '../../domain/road_node.dart';
import 'main_roads_edge_builder.dart';
import 'main_roads_network_segment.dart';

typedef _CoordinateKey = (double longitude, double latitude);

class _Appearance {
  const _Appearance(this.featureIndex, this.isEndpoint);

  final int featureIndex;
  final bool isEndpoint;
}

/// Compiles Main Roads source features using exact source-coordinate topology.
///
/// Every part endpoint becomes a node. An internal source vertex becomes a node
/// only when the exact same coordinate appears in a different source feature.
/// Parts are never bridged, nearby coordinates are never snapped, and
/// unrepresented geometric crossings are never converted into junctions.
class ExactTopologyRoadGraphCompiler {
  const ExactTopologyRoadGraphCompiler();

  RoadGraph compile(Iterable<MainRoadsNetworkSegment> source) {
    final segments = List<MainRoadsNetworkSegment>.unmodifiable(source);
    final appearances = <_CoordinateKey, List<_Appearance>>{};

    for (var featureIndex = 0;
        featureIndex < segments.length;
        featureIndex++) {
      final segment = segments[featureIndex];
      for (final part in segment.parts) {
        if (part.length < 2) {
          throw ArgumentError(
            'Feature ${segment.globalId} contains a part with fewer than two vertices',
          );
        }
        for (var vertex = 0; vertex < part.length; vertex++) {
          final coordinate = part[vertex];
          final key = _key(coordinate);
          (appearances[key] ??= []).add(
            _Appearance(
              featureIndex,
              vertex == 0 || vertex == part.length - 1,
            ),
          );
        }
      }
    }

    final sharedAcrossFeatures = <_CoordinateKey>{};
    for (final entry in appearances.entries) {
      if (entry.value.map((a) => a.featureIndex).toSet().length > 1) {
        sharedAcrossFeatures.add(entry.key);
      }
    }

    final nodeCoordinates = <_CoordinateKey>{};
    for (final entry in appearances.entries) {
      if (entry.value.any((a) => a.isEndpoint) ||
          sharedAcrossFeatures.contains(entry.key)) {
        nodeCoordinates.add(entry.key);
      }
    }

    final sortedNodeCoordinates = nodeCoordinates.toList()
      ..sort((a, b) {
        final longitude = a.$1.compareTo(b.$1);
        return longitude != 0 ? longitude : a.$2.compareTo(b.$2);
      });
    final nodes = [
      for (final coordinate in sortedNodeCoordinates)
        RoadNode(
          id: exactCoordinateNodeId(
            longitude: coordinate.$1,
            latitude: coordinate.$2,
          ),
          longitude: coordinate.$1,
          latitude: coordinate.$2,
        ),
    ];

    final edges = <RoadEdge>[];
    for (final segment in segments) {
      for (var partIndex = 0;
          partIndex < segment.parts.length;
          partIndex++) {
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
          final from = exactCoordinateNodeId(
            longitude: part[start].longitude,
            latitude: part[start].latitude,
          );
          final to = exactCoordinateNodeId(
            longitude: part[end].longitude,
            latitude: part[end].latitude,
          );
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

    return RoadGraph(nodes: nodes, edges: edges);
  }
}

/// Stable node identity for exact WGS84 source-coordinate equality.
String exactCoordinateNodeId({
  required double longitude,
  required double latitude,
}) {
  String canonical(double value) => value == 0 ? '0.0' : value.toString();
  return 'coordinate:${canonical(longitude)},${canonical(latitude)}';
}

_CoordinateKey _key(SourceCoordinate coordinate) =>
    (coordinate.longitude == 0 ? 0.0 : coordinate.longitude,
        coordinate.latitude == 0 ? 0.0 : coordinate.latitude);

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
