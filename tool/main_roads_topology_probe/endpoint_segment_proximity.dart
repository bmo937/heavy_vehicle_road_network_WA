import 'dart:math' as math;

import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

import 'geo.dart';

class EndpointSegmentProximity {
  EndpointSegmentProximity({
    required this.eligibleEndpointCount,
    required this.withinRadiusCount,
    required this.withoutCandidateWithinRadius,
    required this.nearestSegmentDistanceBuckets,
    required this.nearestInteriorDistanceBuckets,
    required this.nearestLocationKinds,
    required this.byRoadRelation,
    required this.details,
    required this.detailsTruncated,
    required this.searchRadiusMetres,
  });

  final int eligibleEndpointCount;
  final int withinRadiusCount;
  final int withoutCandidateWithinRadius;
  final Map<String, int> nearestSegmentDistanceBuckets;
  final Map<String, int> nearestInteriorDistanceBuckets;
  final Map<String, int> nearestLocationKinds;
  final Map<String, int> byRoadRelation;
  final List<Map<String, dynamic>> details;
  final bool detailsTruncated;
  final double searchRadiusMetres;

  Map<String, dynamic> toJson() => {
        'eligibleEndpointCount': eligibleEndpointCount,
        'endpointsWithCandidateWithinRadius': withinRadiusCount,
        'endpointsWithoutCandidateWithinRadius': withoutCandidateWithinRadius,
        'searchRadiusMetres': searchRadiusMetres,
        'nearestSegmentDistanceBuckets': nearestSegmentDistanceBuckets,
        'nearestInteriorDistanceBuckets': nearestInteriorDistanceBuckets,
        'nearestLocationKinds': nearestLocationKinds,
        'byRoadRelation': byRoadRelation,
        'details': details,
        'detailsTruncated': detailsTruncated,
        'note': 'Diagnostic only. Candidates are not junctions; no coordinate was snapped and no feature was split.',
      };
}

class _Endpoint {
  _Endpoint(this.feature, this.part, this.isStart, this.lat, this.lng);
  final int feature;
  final int part;
  final bool isStart;
  final double lat;
  final double lng;
}

class _Segment {
  _Segment(this.feature, this.part, this.index, this.a, this.b);
  final int feature;
  final int part;
  final int index;
  final SourceCoordinate a;
  final SourceCoordinate b;
  double get minLat => math.min(a.latitude, b.latitude);
  double get maxLat => math.max(a.latitude, b.latitude);
  double get minLng => math.min(a.longitude, b.longitude);
  double get maxLng => math.max(a.longitude, b.longitude);
}

class _Projection {
  const _Projection(this.distance, this.t, this.lat, this.lng, this.location);
  final double distance;
  final double t;
  final double lat;
  final double lng;
  final String location;
}

class _Match {
  const _Match(this.segment, this.projection);
  final _Segment segment;
  final _Projection projection;
}

Map<String, int> _distanceBuckets() => {
      '0 m': 0,
      '>0 to 0.1 m': 0,
      '>0.1 to 0.5 m': 0,
      '>0.5 to 1 m': 0,
      '>1 to 2 m': 0,
      '>2 to 5 m': 0,
      '>5 to 10 m': 0,
      '>10 m': 0,
    };

String _bucket(double d, double radius) {
  if (d == 0) return '0 m';
  if (d > radius) return '>10 m';
  return bucketForDistance(d, exact: false).label;
}

_Projection _project(_Endpoint p, _Segment s) {
  final cosLat = math.max(0.05, math.cos(p.lat * math.pi / 180));
  final metresPerLng = metresPerDegreeLatitude * cosLat;
  final ax = (s.a.longitude - p.lng) * metresPerLng;
  final ay = (s.a.latitude - p.lat) * metresPerDegreeLatitude;
  final bx = (s.b.longitude - p.lng) * metresPerLng;
  final by = (s.b.latitude - p.lat) * metresPerDegreeLatitude;
  final dx = bx - ax;
  final dy = by - ay;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) {
    return const _Projection(double.infinity, 0, 0, 0, 'zeroLength');
  }
  final rawT = -(ax * dx + ay * dy) / len2;
  final t = rawT.clamp(0.0, 1.0).toDouble();
  final x = ax + t * dx;
  final y = ay + t * dy;
  final location = t == 0
      ? 'segmentStart'
      : t == 1
          ? 'segmentEnd'
          : 'segmentInterior';
  return _Projection(
    math.sqrt(x * x + y * y),
    t,
    s.a.latitude + t * (s.b.latitude - s.a.latitude),
    s.a.longitude + t * (s.b.longitude - s.a.longitude),
    location,
  );
}

EndpointSegmentProximity analyzeEndpointSegmentProximity(
  List<MainRoadsNetworkSegment> features, {
  double radiusMetres = 10,
  int detailLimit = 20000,
}) {
  if (!radiusMetres.isFinite || radiusMetres < 10) {
    throw ArgumentError.value(radiusMetres, 'radiusMetres');
  }

  final endpoints = <_Endpoint>[];
  final endpointFeatures = <(double, double), Set<int>>{};
  final segments = <_Segment>[];
  var maxAbsLat = 0.0;

  for (var f = 0; f < features.length; f++) {
    for (var p = 0; p < features[f].parts.length; p++) {
      final part = features[f].parts[p];
      if (part.length < 2) {
        throw ArgumentError('feature ${features[f].globalId} part $p has fewer than 2 vertices');
      }
      final ends = [part.first, part.last];
      for (var e = 0; e < ends.length; e++) {
        final c = ends[e];
        endpoints.add(_Endpoint(f, p, e == 0, c.latitude, c.longitude));
        (endpointFeatures[(c.longitude, c.latitude)] ??= <int>{}).add(f);
        maxAbsLat = math.max(maxAbsLat, c.latitude.abs());
      }
      for (var i = 0; i + 1 < part.length; i++) {
        final a = part[i], b = part[i + 1];
        if (a.latitude == b.latitude && a.longitude == b.longitude) continue;
        segments.add(_Segment(f, p, i, a, b));
        maxAbsLat = math.max(maxAbsLat, math.max(a.latitude.abs(), b.latitude.abs()));
      }
    }
  }

  final cellLat = radiusMetres * 1.01 / metresPerDegreeLatitude;
  final cosLat = math.max(0.05, math.cos(maxAbsLat * math.pi / 180));
  final cellLng = cellLat / cosLat;
  int cx(double lng) => (lng / cellLng).floor();
  int cy(double lat) => (lat / cellLat).floor();
  final expandLat = radiusMetres / metresPerDegreeLatitude;
  final expandLng = expandLat / cosLat;
  final grid = <(int, int), List<int>>{};
  final oversizedSegments = <int>[];
  const maxCellsPerSegment = 200000;
  for (var i = 0; i < segments.length; i++) {
    final s = segments[i];
    // Register the segment per piece (at most about one cell long) rather
    // than over its whole bounding box, which is huge for long diagonals.
    final pieces = math.max(
      1,
      math.max(
        ((s.maxLng - s.minLng) / cellLng).ceil(),
        ((s.maxLat - s.minLat) / cellLat).ceil(),
      ),
    );
    if (pieces > maxCellsPerSegment) {
      oversizedSegments.add(i);
      continue;
    }
    final cells = <(int, int)>{};
    final dLng = s.b.longitude - s.a.longitude;
    final dLat = s.b.latitude - s.a.latitude;
    for (var k = 0; k < pieces; k++) {
      final lng0 = s.a.longitude + dLng * k / pieces;
      final lng1 = s.a.longitude + dLng * (k + 1) / pieces;
      final lat0 = s.a.latitude + dLat * k / pieces;
      final lat1 = s.a.latitude + dLat * (k + 1) / pieces;
      final minX = cx(math.min(lng0, lng1) - expandLng);
      final maxX = cx(math.max(lng0, lng1) + expandLng);
      final minY = cy(math.min(lat0, lat1) - expandLat);
      final maxY = cy(math.max(lat0, lat1) + expandLat);
      for (var x = minX; x <= maxX; x++) {
        for (var y = minY; y <= maxY; y++) {
          cells.add((x, y));
        }
      }
    }
    for (final c in cells) {
      (grid[c] ??= []).add(i);
    }
  }

  final nearestBuckets = _distanceBuckets();
  final interiorBuckets = _distanceBuckets();
  final kinds = <String, int>{
    'segmentInterior': 0,
    'segmentStart': 0,
    'segmentEnd': 0,
    'noneWithinRadius': 0,
  };
  final relations = <String, int>{};
  final details = <Map<String, dynamic>>[];
  var truncated = false;
  var eligible = 0;
  var within = 0;

  for (final e in endpoints) {
    final exactFeatures = endpointFeatures[(e.lng, e.lat)]!;
    if (exactFeatures.any((f) => f != e.feature)) continue;
    eligible++;

    _Match? best;
    _Match? bestInterior;
    final candidates = [
      ...?grid[(cx(e.lng), cy(e.lat))],
      ...oversizedSegments,
    ];
    for (final id in candidates) {
      final s = segments[id];
      if (s.feature == e.feature) continue;
      final projection = _project(e, s);
      if (projection.distance > radiusMetres) continue;
      final match = _Match(s, projection);
      if (best == null || projection.distance < best.projection.distance) best = match;
      if (projection.location == 'segmentInterior' &&
          (bestInterior == null || projection.distance < bestInterior.projection.distance)) {
        bestInterior = match;
      }
    }

    nearestBuckets.update(
      best == null ? '>10 m' : _bucket(best.projection.distance, radiusMetres),
      (v) => v + 1,
    );
    interiorBuckets.update(
      bestInterior == null ? '>10 m' : _bucket(bestInterior.projection.distance, radiusMetres),
      (v) => v + 1,
    );

    if (best == null) {
      kinds['noneWithinRadius'] = kinds['noneWithinRadius']! + 1;
      continue;
    }
    within++;
    kinds[best.projection.location] = kinds[best.projection.location]! + 1;
    final source = features[e.feature];
    final target = features[best.segment.feature];
    final relation = '${source.road == target.road ? 'same' : 'different'} ROAD, '
        '${source.routeNeId == target.routeNeId ? 'same' : 'different'} ROUTE_NE_ID';
    relations[relation] = (relations[relation] ?? 0) + 1;

    if (details.length < detailLimit) {
      details.add({
        'sourceGlobalId': source.globalId,
        'sourcePartIndex': e.part,
        'sourceEndpoint': e.isStart ? 'start' : 'end',
        'sourceLongitude': e.lng,
        'sourceLatitude': e.lat,
        'sourceRoad': source.road,
        'sourceRouteNeId': source.routeNeId,
        'targetGlobalId': target.globalId,
        'targetPartIndex': best.segment.part,
        'targetSegmentIndex': best.segment.index,
        'targetRoad': target.road,
        'targetRouteNeId': target.routeNeId,
        'nearestLongitude': best.projection.lng,
        'nearestLatitude': best.projection.lat,
        'distanceMetres': best.projection.distance,
        'projectionT': best.projection.t,
        'targetLocation': best.projection.location,
        'sameRoad': source.road == target.road,
        'sameRouteNeId': source.routeNeId == target.routeNeId,
      });
    } else {
      truncated = true;
    }
  }

  return EndpointSegmentProximity(
    eligibleEndpointCount: eligible,
    withinRadiusCount: within,
    withoutCandidateWithinRadius: eligible - within,
    nearestSegmentDistanceBuckets: nearestBuckets,
    nearestInteriorDistanceBuckets: interiorBuckets,
    nearestLocationKinds: kinds,
    byRoadRelation: relations,
    details: details,
    detailsTruncated: truncated,
    searchRadiusMetres: radiusMetres,
  );
}
