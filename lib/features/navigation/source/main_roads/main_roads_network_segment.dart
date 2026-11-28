import '../../domain/source_coordinate.dart';

export '../../domain/source_coordinate.dart';

/// One physical road feature from Main Roads WA layer 78
/// ("Tandem Drive 1-10 All Networks").
///
/// This is raw source data. It is not a topology edge: a future topology
/// compiler may split [parts] at junctions or restriction boundaries.
/// [maxNetwork] is source metadata only and is not interpreted here.
///
/// A feature has one or more line [parts] (GeoJSON `LineString` = one part,
/// `MultiLineString` = one per member line). Parts stay separate: no edge is
/// implied between the end of one part and the start of the next, and all
/// parts share this feature's [globalId] and metadata.
class MainRoadsNetworkSegment {
  /// Pass exactly one of [geometry] (a single line) or [parts].
  MainRoadsNetworkSegment({
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
    List<SourceCoordinate>? geometry,
    List<List<SourceCoordinate>>? parts,
  })  : assert((geometry == null) != (parts == null),
            'provide exactly one of geometry or parts'),
        assert(parts == null || parts.isNotEmpty, 'parts must not be empty'),
        parts = List.unmodifiable(
          (parts ?? [geometry!]).map<List<SourceCoordinate>>(List.unmodifiable),
        );

  /// Source feature identity (unique per feature in the observed data).
  final String globalId;

  /// Source OBJECTID; may change across source refreshes. Metadata only.
  final int? objectId;

  final String road;
  final String? roadName;

  /// Route association metadata. NOT unique per feature.
  final int routeNeId;

  final double startSlk;
  final double endSlk;
  final double startTrueDist;
  final double endTrueDist;

  final String? networkType;
  final String? networkCategory;

  /// Raw MAX_NETWORK value. Not interpreted.
  final int maxNetwork;

  /// Line parts in source order, each with at least two vertices in source
  /// order. Never joined to one another.
  final List<List<SourceCoordinate>> parts;

  /// Vertices of the only part. Throws [StateError] for multipart features;
  /// use [parts] when the geometry may have more than one part.
  List<SourceCoordinate> get geometry {
    if (parts.length != 1) {
      throw StateError(
          'feature $globalId has ${parts.length} parts; use parts');
    }
    return parts.single;
  }
}
