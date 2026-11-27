import 'dart:math' as math;

/// Input coordinates throughout the topology probe are GEOGRAPHIC degrees
/// (longitude, latitude; WGS84 / EPSG:4326 as requested with outSR=4326).
///
/// Metre distances are ALWAYS computed with [haversineMetres] (great-circle on
/// a spherical Earth). Degree differences are never labelled as metres.
const double earthRadiusMetres = 6371008.8;

/// Metres per degree of latitude on the same sphere; used only to size spatial
/// grid cells, never to report a distance.
const double metresPerDegreeLatitude = earthRadiusMetres * math.pi / 180.0;

double haversineMetres(double lat1, double lng1, double lat2, double lng2) {
  final p1 = lat1 * math.pi / 180.0;
  final p2 = lat2 * math.pi / 180.0;
  final dp = p2 - p1;
  final dl = (lng2 - lng1) * math.pi / 180.0;
  final a = math.pow(math.sin(dp / 2), 2) +
      math.cos(p1) * math.cos(p2) * math.pow(math.sin(dl / 2), 2);
  return 2 * earthRadiusMetres * math.asin(math.min(1.0, math.sqrt(a)));
}

/// Distance classes for proximity diagnostics. EXACT equality of the two
/// double coordinate pairs is a separate class from tolerance-based proximity:
/// two different coordinates are never put in [exact], however close.
/// Upper bounds are inclusive (0.1 m is in `>0 to 0.1 m`).
enum DistanceBucket {
  exact('exact same coordinate', 0),
  upTo0_1('>0 to 0.1 m', 0.1),
  upTo0_5('>0.1 to 0.5 m', 0.5),
  upTo1('>0.5 to 1 m', 1),
  upTo2('>1 to 2 m', 2),
  upTo5('>2 to 5 m', 5),
  upTo10('>5 to 10 m', 10),
  over10('>10 m', double.infinity);

  const DistanceBucket(this.label, this.upperMetres);
  final String label;
  final double upperMetres;
}

DistanceBucket bucketForDistance(double metres, {required bool exact}) {
  if (exact) return DistanceBucket.exact;
  if (metres.isNaN || metres < 0) {
    throw ArgumentError.value(metres, 'metres', 'must be a non-negative number');
  }
  for (final b in DistanceBucket.values) {
    if (b == DistanceBucket.exact) continue;
    if (metres <= b.upperMetres) return b;
  }
  return DistanceBucket.over10;
}

Map<String, int> emptyBucketCounts() => {
      for (final b in DistanceBucket.values) b.label: 0,
    };

/// Exact coordinate key: (longitude, latitude) compared with `==` on doubles.
/// No rounding, so keys are equal only when the source values are identical.
typedef CoordKey = (double, double);
