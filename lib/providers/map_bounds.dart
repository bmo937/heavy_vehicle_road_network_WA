import 'package:maplibre_gl/maplibre_gl.dart';

/// Class to track map bounding boxes and determine if new requests are needed
class MapBounds {
  MapBounds({required this.southwest, required this.northeast});

  final LatLng northeast;
  final LatLng southwest;

  // Check if this bounding box completely contains another bounding box
  bool contains(MapBounds other) {
    return southwest.latitude <= other.southwest.latitude &&
        southwest.longitude <= other.southwest.longitude &&
        northeast.latitude >= other.northeast.latitude &&
        northeast.longitude >= other.northeast.longitude;
  }

  // Calculate the area of the bounding box
  double calculateArea() {
    final latDiff = northeast.latitude - southwest.latitude;
    final lonDiff = northeast.longitude - southwest.longitude;
    return latDiff * lonDiff;
  }

  // Check if two bounding boxes are significantly different
  bool isDifferentEnough(MapBounds other, {double threshold = 0.01}) {
    // If one box contains the other and the size difference isn't too large, consider it not different enough
    if ((contains(other) || other.contains(this))) {
      final areaRatio = calculateArea() / other.calculateArea();
      if (areaRatio > 0.5 - threshold && areaRatio < 2.0 + threshold) {
        return false;
      }
    }

    // Calculate the ratio of areas to determine significant difference
    final areaRatio = calculateArea() / other.calculateArea();
    return (areaRatio < 0.5 - threshold || areaRatio > 0.5 + threshold);
  }
}
