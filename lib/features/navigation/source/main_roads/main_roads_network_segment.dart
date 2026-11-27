/// A geographic position parsed from GeoJSON.
///
/// GeoJSON stores positions as `[longitude, latitude]`; this class keeps the
/// two values in named fields so the order cannot be reversed accidentally.
/// Pure Dart: deliberately independent of MapLibre's `LatLng`.
class SourceCoordinate {
  const SourceCoordinate({required this.latitude, required this.longitude});

  /// Degrees, -90..90.
  final double latitude;

  /// Degrees, -180..180.
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is SourceCoordinate &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'SourceCoordinate(lat: $latitude, lng: $longitude)';
}

/// One physical road feature from Main Roads WA layer 78
/// ("Tandem Drive 1-10 All Networks").
///
/// This is raw source data. It is not a topology edge: a future topology
/// compiler may split [geometry] at junctions or restriction boundaries.
/// [maxNetwork] is source metadata only and is not interpreted here.
class MainRoadsNetworkSegment {
  const MainRoadsNetworkSegment({
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
    required this.geometry,
  });

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

  /// Ordered line vertices (at least two), in source order.
  final List<SourceCoordinate> geometry;
}
