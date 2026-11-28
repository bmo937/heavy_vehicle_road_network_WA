import 'source_coordinate.dart';

/// Uninterpreted attributes of the original Main Roads feature.
///
/// The SLK and true-distance ranges describe the whole feature, not an
/// interpolated range for an edge slice. They are never swapped on reversal.
class MainRoadsEdgeProvenance {
  const MainRoadsEdgeProvenance({
    required this.globalId,
    required this.objectId,
    required this.road,
    required this.roadName,
    required this.routeNeId,
    required this.startSlk,
    required this.endSlk,
    required this.startTrueDist,
    required this.endTrueDist,
    required this.networkType,
    required this.networkCategory,
    required this.maxNetwork,
  });

  final String globalId;
  final int? objectId;
  final String road;
  final String? roadName;
  final int routeNeId;
  final double startSlk;
  final double endSlk;
  final double startTrueDist;
  final double endTrueDist;
  final String? networkType;
  final String? networkCategory;
  final int maxNetwork;

  @override
  bool operator ==(Object other) =>
      other is MainRoadsEdgeProvenance &&
      globalId == other.globalId &&
      objectId == other.objectId &&
      road == other.road &&
      roadName == other.roadName &&
      routeNeId == other.routeNeId &&
      startSlk == other.startSlk &&
      endSlk == other.endSlk &&
      startTrueDist == other.startTrueDist &&
      endTrueDist == other.endTrueDist &&
      networkType == other.networkType &&
      networkCategory == other.networkCategory &&
      maxNetwork == other.maxNetwork;

  @override
  int get hashCode => Object.hash(
        globalId,
        objectId,
        road,
        roadName,
        routeNeId,
        startSlk,
        endSlk,
        startTrueDist,
        endTrueDist,
        networkType,
        networkCategory,
        maxNetwork,
      );
}

/// Source data for one directed edge, independent of graph identifiers.
class MainRoadsEdgeSource {
  MainRoadsEdgeSource({
    required this.provenance,
    required Iterable<SourceCoordinate> geometry,
    required this.isReversed,
  }) : geometry = List.unmodifiable(geometry) {
    if (this.geometry.length < 2) {
      throw ArgumentError('An edge geometry needs at least two coordinates');
    }
  }

  final MainRoadsEdgeProvenance provenance;

  /// Coordinates ordered from the edge's from-node to its to-node.
  final List<SourceCoordinate> geometry;

  /// Whether this edge travels opposite to the original source part order.
  final bool isReversed;

  MainRoadsEdgeSource reversed() => MainRoadsEdgeSource(
        provenance: provenance,
        geometry: geometry.reversed,
        isReversed: !isReversed,
      );

  @override
  bool operator ==(Object other) {
    if (other is! MainRoadsEdgeSource ||
        provenance != other.provenance ||
        isReversed != other.isReversed ||
        geometry.length != other.geometry.length) {
      return false;
    }
    for (var i = 0; i < geometry.length; i++) {
      if (geometry[i] != other.geometry[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(provenance, isReversed, Object.hashAll(geometry));
}
