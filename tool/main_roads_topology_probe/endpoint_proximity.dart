import 'dart:math' as math;

import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

import 'geo.dart';

class EndpointProximity {
  EndpointProximity({
    required this.endpointCount,
    required this.nearestOther,
    required this.nearestNonIdentical,
    required this.searchRadiusMetres,
  });

  final int endpointCount;

  /// Per endpoint: bucket of the nearest endpoint of a DIFFERENT feature.
  /// An exact coordinate match, if any, wins and is reported as `exact`.
  final Map<String, int> nearestOther;

  /// Per endpoint: bucket of the nearest endpoint of a different feature whose
  /// coordinate is NOT identical. Shows near-misses even for endpoints that
  /// also have an exact partner.
  final Map<String, int> nearestNonIdentical;

  final double searchRadiusMetres;

  Map<String, dynamic> toJson() => {
        'endpointCount': endpointCount,
        'searchRadiusMetres': searchRadiusMetres,
        'nearestOtherEndpoint': nearestOther,
        'nearestNonIdenticalEndpoint': nearestNonIdentical,
        'note': 'Diagnostic only. No coordinate was snapped and no tolerance was chosen.',
      };
}

class _Ep {
  _Ep(this.feature, this.lat, this.lng);
  final int feature;
  final double lat, lng;
}

/// Measures, for every source part endpoint (two per line part), the great-circle distance in metres to
/// the nearest endpoint of a different feature.
///
/// Candidate stage: endpoints are hashed into a lat/lng cell grid whose cells
/// are at least [radiusMetres] wide in both axes (sized from the data's
/// maximum |latitude|), so only the 3x3 neighbouring cells are searched.
/// Endpoints with nothing within [radiusMetres] fall in the `>10 m` bucket.
EndpointProximity analyzeEndpointProximity(
  List<MainRoadsNetworkSegment> segments, {
  double radiusMetres = 10.0,
}) {
  final eps = <_Ep>[];
  var maxAbsLat = 0.0;
  for (var f = 0; f < segments.length; f++) {
    final parts = segments[f].parts;
    for (var p = 0; p < parts.length; p++) {
      final g = parts[p];
      if (g.length < 2) {
        throw ArgumentError('feature ${segments[f].globalId} part $p has fewer than 2 vertices');
      }
      for (final c in [g.first, g.last]) {
        eps.add(_Ep(f, c.latitude, c.longitude));
        maxAbsLat = math.max(maxAbsLat, c.latitude.abs());
      }
    }
  }

  // 1% margin so the radius is strictly inside one cell width.
  final cellLat = radiusMetres * 1.01 / metresPerDegreeLatitude;
  final cosLat = math.max(0.05, math.cos(maxAbsLat * math.pi / 180.0));
  final cellLng = cellLat / cosLat;

  final grid = <(int, int), List<_Ep>>{};
  (int, int) cellOf(_Ep e) => ((e.lng / cellLng).floor(), (e.lat / cellLat).floor());
  for (final e in eps) {
    (grid[cellOf(e)] ??= []).add(e);
  }

  final nearest = emptyBucketCounts();
  final nonIdentical = emptyBucketCounts();
  for (final e in eps) {
    final (cx, cy) = cellOf(e);
    var hasExact = false;
    var best = double.infinity;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final cell = grid[(cx + dx, cy + dy)];
        if (cell == null) continue;
        for (final o in cell) {
          if (o.feature == e.feature) continue;
          if (o.lat == e.lat && o.lng == e.lng) {
            hasExact = true;
            continue;
          }
          final d = haversineMetres(e.lat, e.lng, o.lat, o.lng);
          if (d < best) best = d;
        }
      }
    }
    if (best > radiusMetres) best = double.infinity;
    final nonIdBucket = best.isInfinite
        ? DistanceBucket.over10
        : bucketForDistance(best, exact: false);
    nonIdentical.update(nonIdBucket.label, (v) => v + 1);
    final b = hasExact ? DistanceBucket.exact : nonIdBucket;
    nearest.update(b.label, (v) => v + 1);
  }

  return EndpointProximity(
    endpointCount: eps.length,
    nearestOther: nearest,
    nearestNonIdentical: nonIdentical,
    searchRadiusMetres: radiusMetres,
  );
}
