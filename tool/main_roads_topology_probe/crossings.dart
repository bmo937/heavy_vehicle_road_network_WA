import 'geo.dart';
import 'shared_vertices.dart';

// 2D crossing diagnostics between DIFFERENT source features.
//
// Planar model: GeoJSON LineStrings are treated as straight lines in
// (longitude, latitude) space, exactly as the source geometry is defined.
// Whether two straight segments intersect is invariant under independent
// scaling of the two axes, so no degree->metre projection is needed (or
// applied) for the intersection tests themselves; intersection coordinates
// come back in degrees. Metre figures (nearest-vertex distances) use
// haversine. Orientation tests use exact double arithmetic with no tolerance,
// so nearly-touching or nearly-collinear geometry is NOT reported here.
// A crossing is a geometric fact, not a junction: grade separation may exist.

enum HitKind { proper, touch, overlap }

class SegmentHit {
  const SegmentHit(this.kind, this.x, this.y,
      {this.x2, this.y2, this.vertexOfA});
  final HitKind kind;
  final double x, y;

  /// Second point of a collinear overlap.
  final double? x2, y2;

  /// For [HitKind.touch]: true if the touching point is a vertex of segment A,
  /// false if it is a vertex of segment B.
  final bool? vertexOfA;
}

int _sign(double v) => v > 0 ? 1 : (v < 0 ? -1 : 0);

double _orient(
        double px, double py, double qx, double qy, double rx, double ry) =>
    (qx - px) * (ry - py) - (qy - py) * (rx - px);

bool _inBox(double x, double y, double x1, double y1, double x2, double y2) =>
    x >= (x1 < x2 ? x1 : x2) &&
    x <= (x1 < x2 ? x2 : x1) &&
    y >= (y1 < y2 ? y1 : y2) &&
    y <= (y1 < y2 ? y2 : y1);

/// Exact 2D intersection of segment A (a1-a2) and segment B (b1-b2).
/// Both segments must have non-zero length. Returns null when disjoint.
SegmentHit? intersectSegments(
  double ax1,
  double ay1,
  double ax2,
  double ay2,
  double bx1,
  double by1,
  double bx2,
  double by2,
) {
  final o1 = _sign(_orient(ax1, ay1, ax2, ay2, bx1, by1));
  final o2 = _sign(_orient(ax1, ay1, ax2, ay2, bx2, by2));
  final o3 = _sign(_orient(bx1, by1, bx2, by2, ax1, ay1));
  final o4 = _sign(_orient(bx1, by1, bx2, by2, ax2, ay2));

  if (o1 == 0 && o2 == 0) {
    // Collinear: compare projections on the dominant axis.
    final useX = (ax2 - ax1).abs() >= (ay2 - ay1).abs();
    final pts = [(ax1, ay1), (ax2, ay2), (bx1, by1), (bx2, by2)];
    double t((double, double) p) => useX ? p.$1 : p.$2;
    final aLo = t(pts[0]) < t(pts[1]) ? t(pts[0]) : t(pts[1]);
    final aHi = t(pts[0]) < t(pts[1]) ? t(pts[1]) : t(pts[0]);
    final bLo = t(pts[2]) < t(pts[3]) ? t(pts[2]) : t(pts[3]);
    final bHi = t(pts[2]) < t(pts[3]) ? t(pts[3]) : t(pts[2]);
    final lo = aLo > bLo ? aLo : bLo;
    final hi = aHi < bHi ? aHi : bHi;
    if (lo > hi) return null;
    final pLo = pts.firstWhere((p) => t(p) == lo);
    final pHi = pts.firstWhere((p) => t(p) == hi);
    if (lo == hi) {
      return SegmentHit(HitKind.touch, pLo.$1, pLo.$2,
          vertexOfA: pLo == pts[0] || pLo == pts[1]);
    }
    return SegmentHit(HitKind.overlap, pLo.$1, pLo.$2, x2: pHi.$1, y2: pHi.$2);
  }

  if (o1 * o2 < 0 && o3 * o4 < 0) {
    final d = (ax2 - ax1) * (by2 - by1) - (ay2 - ay1) * (bx2 - bx1);
    final t = ((bx1 - ax1) * (by2 - by1) - (by1 - ay1) * (bx2 - bx1)) / d;
    return SegmentHit(
        HitKind.proper, ax1 + t * (ax2 - ax1), ay1 + t * (ay2 - ay1));
  }
  if (o1 == 0 && _inBox(bx1, by1, ax1, ay1, ax2, ay2)) {
    return SegmentHit(HitKind.touch, bx1, by1, vertexOfA: false);
  }
  if (o2 == 0 && _inBox(bx2, by2, ax1, ay1, ax2, ay2)) {
    return SegmentHit(HitKind.touch, bx2, by2, vertexOfA: false);
  }
  if (o3 == 0 && _inBox(ax1, ay1, bx1, by1, bx2, by2)) {
    return SegmentHit(HitKind.touch, ax1, ay1, vertexOfA: true);
  }
  if (o4 == 0 && _inBox(ax2, ay2, bx1, by1, bx2, by2)) {
    return SegmentHit(HitKind.touch, ax2, ay2, vertexOfA: true);
  }
  return null;
}

class CrossingAnalysis {
  CrossingAnalysis({
    required this.indexedSegments,
    required this.skippedZeroLengthSegments,
    required this.naiveSegmentPairs,
    required this.candidatePairs,
    required this.crossings,
    required this.byKind,
    required this.byRoles,
    required this.crossingsInvolvingEndpoint,
    required this.nearestVertexBuckets,
    required this.byRoadRelation,
    required this.details,
    required this.detailsTruncated,
    required this.cellSizeDegrees,
  });

  final int indexedSegments;
  final int skippedZeroLengthSegments;

  /// Pairs a naive all-vs-all comparison would have tested.
  final int naiveSegmentPairs;

  /// Segment pairs of different features that passed the grid + bounding-box
  /// filter and received an exact intersection test.
  final int candidatePairs;

  /// Unrepresented crossings: intersections NOT at an exact shared source vertex.
  final int crossings;
  final Map<String, int> byKind;
  final Map<String, int> byRoles;
  final int crossingsInvolvingEndpoint;

  /// Distance from the intersection to the nearer of the two features' own
  /// nearest source vertex. A non-shared touch can be 0 m and has its own bucket;
  /// exact shared-vertex identity is excluded from this analysis.
  final Map<String, int> nearestVertexBuckets;
  final Map<String, int> byRoadRelation;
  final List<Map<String, dynamic>> details;
  final bool detailsTruncated;
  final double cellSizeDegrees;

  Map<String, dynamic> toJson() => {
        'method':
            'uniform lat/lng grid -> canonical-cell bbox filter -> exact double-precision segment intersection',
        'cellSizeDegrees': cellSizeDegrees,
        'indexedSegments': indexedSegments,
        'skippedZeroLengthSegments': skippedZeroLengthSegments,
        'naiveSegmentPairs': naiveSegmentPairs,
        'candidatePairsTested': candidatePairs,
        'unrepresentedCrossings': crossings,
        'byKind': byKind,
        'byRoles': byRoles,
        'crossingsInvolvingEndpoint': crossingsInvolvingEndpoint,
        'nearestOwnVertexDistanceBuckets': nearestVertexBuckets,
        'byRoadRelation': byRoadRelation,
        'details': details,
        'detailsTruncated': detailsTruncated,
        'note':
            'Crossings are NOT junctions. No junction was created and nothing was snapped.',
      };
}

class _Seg {
  _Seg(this.feature, this.part, this.index, this.x1, this.y1, this.x2, this.y2);
  final int feature, part, index;
  final double x1, y1, x2, y2;
  double get minX => x1 < x2 ? x1 : x2;
  double get maxX => x1 < x2 ? x2 : x1;
  double get minY => y1 < y2 ? y1 : y2;
  double get maxY => y1 < y2 ? y2 : y1;
}

CrossingAnalysis analyzeCrossings(
  CoordinateIndex index, {
  double cellSizeDegrees = 0.01,
  int detailLimit = 20000,
}) {
  final features = index.segments;
  final segs = <_Seg>[];
  var skipped = 0;
  for (var f = 0; f < features.length; f++) {
    final parts = features[f].parts;
    for (var p = 0; p < parts.length; p++) {
      final g = parts[p];
      for (var i = 0; i + 1 < g.length; i++) {
        final a = g[i], b = g[i + 1];
        if (a.longitude == b.longitude && a.latitude == b.latitude) {
          skipped++;
          continue;
        }
        segs.add(
            _Seg(f, p, i, a.longitude, a.latitude, b.longitude, b.latitude));
      }
    }
  }

  final grid = <(int, int), List<int>>{};
  int cell(double v) => (v / cellSizeDegrees).floor();
  for (var s = 0; s < segs.length; s++) {
    final g = segs[s];
    for (var cx = cell(g.minX); cx <= cell(g.maxX); cx++) {
      for (var cy = cell(g.minY); cy <= cell(g.maxY); cy++) {
        (grid[(cx, cy)] ??= []).add(s);
      }
    }
  }

  var candidates = 0;
  final seen = <String>{};
  final byKind = <String, int>{};
  final byRoles = <String, int>{};
  final byRoad = <String, int>{};
  final nearestBuckets = emptyBucketCounts()
    ..remove(DistanceBucket.exact.label)
    ..['0 m'] = 0;
  var involvesEndpoint = 0;
  var total = 0;
  final details = <Map<String, dynamic>>[];
  var truncated = false;

  double nearestVertex(int feature, int part, double x, double y) {
    var best = double.infinity;
    for (final c in features[feature].parts[part]) {
      final d = haversineMetres(y, x, c.latitude, c.longitude);
      if (d < best) best = d;
    }
    return best;
  }

  String role(int feature, int part, int segIndex, double x, double y) {
    final g = features[feature].parts[part];
    for (final v in [segIndex, segIndex + 1]) {
      if (g[v].longitude == x && g[v].latitude == y) {
        return v == 0 || v == g.length - 1 ? 'endpoint' : 'internalVertex';
      }
    }
    return 'segmentInterior';
  }

  for (final members in grid.entries) {
    final ids = members.value;
    final (cx, cy) = members.key;
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        var a = segs[ids[i]], b = segs[ids[j]];
        if (a.feature == b.feature) continue;
        if (a.maxX < b.minX ||
            b.maxX < a.minX ||
            a.maxY < b.minY ||
            b.maxY < a.minY) {
          continue;
        }
        // Test each pair once: only in the cell holding the min corner of the bbox overlap.
        final ox = a.minX > b.minX ? a.minX : b.minX;
        final oy = a.minY > b.minY ? a.minY : b.minY;
        if (cell(ox) != cx || cell(oy) != cy) continue;
        candidates++;
        if (a.feature > b.feature) {
          final t = a;
          a = b;
          b = t;
        }
        final hit =
            intersectSegments(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1, b.x2, b.y2);
        if (hit == null) continue;

        final fa = a.feature, fb = b.feature;
        final points = [
          (hit.x, hit.y),
          if (hit.kind == HitKind.overlap) (hit.x2!, hit.y2!),
        ];
        // Represented = every intersection point is already an exact source vertex
        // of both intersecting parts.
        final isRepresented = points.every(
          (p) => index.bothPartsHaveVertexAt(
            (p.$1, p.$2),
            fa,
            a.part,
            fb,
            b.part,
          ),
        );
        if (isRepresented) continue;

        final key =
            '$fa|${a.part}|$fb|${b.part}|${hit.kind.name}|${hit.x}|${hit.y}|${hit.x2}|${hit.y2}';
        if (!seen.add(key)) continue;

        final roleA = hit.kind == HitKind.overlap
            ? 'overlap'
            : role(fa, a.part, a.index, hit.x, hit.y);
        final roleB = hit.kind == HitKind.overlap
            ? 'overlap'
            : role(fb, b.part, b.index, hit.x, hit.y);
        final nearA = nearestVertex(fa, a.part, hit.x, hit.y);
        final nearB = nearestVertex(fb, b.part, hit.x, hit.y);
        final near = nearA < nearB ? nearA : nearB;
        final nearBucket =
            near == 0 ? '0 m' : bucketForDistance(near, exact: false).label;
        final endpointInvolved = roleA == 'endpoint' || roleB == 'endpoint';
        final fA = features[fa], fB = features[fb];
        final relation = '${fA.road == fB.road ? 'same' : 'different'} ROAD, '
            '${fA.routeNeId == fB.routeNeId ? 'same' : 'different'} ROUTE_NE_ID';

        total++;
        _bump(byKind, hit.kind.name);
        _bump(byRoles, 'A:$roleA / B:$roleB');
        _bump(byRoad, relation);
        nearestBuckets.update(nearBucket, (v) => v + 1);
        if (endpointInvolved) involvesEndpoint++;

        if (details.length < detailLimit) {
          details.add({
            'kind': hit.kind.name,
            'longitude': hit.x,
            'latitude': hit.y,
            if (hit.kind == HitKind.overlap) 'longitudeEnd': hit.x2,
            if (hit.kind == HitKind.overlap) 'latitudeEnd': hit.y2,
            'globalIdA': fA.globalId,
            'globalIdB': fB.globalId,
            'roadA': fA.road,
            'roadB': fB.road,
            'routeNeIdA': fA.routeNeId,
            'routeNeIdB': fB.routeNeId,
            'partIndexA': a.part,
            'partIndexB': b.part,
            'roleA': roleA,
            'roleB': roleB,
            'atEndpoint': endpointInvolved,
            'nearestOwnVertexMetresA': nearA,
            'nearestOwnVertexMetresB': nearB,
          });
        } else {
          truncated = true;
        }
      }
    }
  }

  return CrossingAnalysis(
    indexedSegments: segs.length,
    skippedZeroLengthSegments: skipped,
    naiveSegmentPairs: segs.length * (segs.length - 1) ~/ 2,
    candidatePairs: candidates,
    crossings: total,
    byKind: byKind,
    byRoles: byRoles,
    crossingsInvolvingEndpoint: involvesEndpoint,
    nearestVertexBuckets: nearestBuckets,
    byRoadRelation: byRoad,
    details: details,
    detailsTruncated: truncated,
    cellSizeDegrees: cellSizeDegrees,
  );
}

void _bump(Map<String, int> m, String k) => m[k] = (m[k] ?? 0) + 1;
