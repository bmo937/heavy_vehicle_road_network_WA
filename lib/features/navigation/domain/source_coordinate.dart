/// A WGS84 position from a GeoJSON source, with named latitude and longitude.
class SourceCoordinate {
  const SourceCoordinate({required this.latitude, required this.longitude});

  final double latitude;
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
