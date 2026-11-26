/// One vertex in the compiled road graph (e.g. an intersection or road end).
///
/// Pure Dart: coordinates are plain WGS84 degrees stored as [double].
class RoadNode {
  const RoadNode({
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  /// Stable identifier, unique within a [RoadGraph].
  final String id;

  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoadNode &&
          other.id == id &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(id, latitude, longitude);

  @override
  String toString() => 'RoadNode($id, $latitude, $longitude)';
}
