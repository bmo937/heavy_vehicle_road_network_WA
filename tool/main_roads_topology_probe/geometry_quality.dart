import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

import 'geo.dart';

/// Segments with a non-zero length at or below this are reported as
/// "suspiciously tiny". A reporting threshold only; nothing is removed.
const double tinySegmentMetres = 1.0;

class GeometryQuality {
  GeometryQuality({
    required this.duplicateGroups,
    required this.exactDuplicatePairs,
    required this.reversedDuplicatePairs,
    required this.duplicatePairsByRelation,
    required this.zeroLengthPairs,
    required this.featuresWithZeroLengthPairs,
    required this.degenerateFeatures,
    required this.segmentLengthBuckets,
    required this.tinySegments,
    required this.featuresWithTinySegments,
    required this.duplicateDetails,
    required this.tinyDetails,
    required this.zeroLengthDetails,
  });

  /// Sets of >= 2 line parts sharing one coordinate sequence (either direction).
  final int duplicateGroups;
  final int exactDuplicatePairs;
  final int reversedDuplicatePairs;

  /// "exact|reversed ROAD same/different, ROUTE_NE_ID same/different" -> pairs.
  final Map<String, int> duplicatePairsByRelation;

  /// Consecutive identical coordinate pairs.
  final int zeroLengthPairs;
  final int featuresWithZeroLengthPairs;

  /// Features whose coordinates (across all parts) are all identical.
  final int degenerateFeatures;

  /// Bucketed lengths of segments; `exact same coordinate` = zero length.
  final Map<String, int> segmentLengthBuckets;
  final int tinySegments;
  final int featuresWithTinySegments;

  final List<Map<String, dynamic>> duplicateDetails;
  final List<Map<String, dynamic>> tinyDetails;
  final List<Map<String, dynamic>> zeroLengthDetails;

  Map<String, dynamic> toJson() => {
        'duplicateGeometryGroups': duplicateGroups,
        'exactDuplicatePairs': exactDuplicatePairs,
        'reversedDuplicatePairs': reversedDuplicatePairs,
        'duplicatePairsByRelation': duplicatePairsByRelation,
        'zeroLengthConsecutivePairs': zeroLengthPairs,
        'featuresWithZeroLengthPairs': featuresWithZeroLengthPairs,
        'degenerateFeaturesAllVerticesIdentical': degenerateFeatures,
        'segmentLengthBuckets': segmentLengthBuckets,
        'tinySegmentThresholdMetres': tinySegmentMetres,
        'tinySegments': tinySegments,
        'featuresWithTinySegments': featuresWithTinySegments,
        'duplicateDetails': duplicateDetails,
        'tinySegmentDetails': tinyDetails,
        'zeroLengthDetails': zeroLengthDetails,
        'note': 'Nothing was deduplicated, removed or repaired.',
      };
}

String _seqKey(Iterable<SourceCoordinate> cs) => cs.map((c) => '${c.longitude},${c.latitude}').join(';');

/// Detects identical / reversed duplicate coordinate sequences, zero-length
/// consecutive vertex pairs and tiny segments. Pure; does not alter geometry.
GeometryQuality analyzeGeometryQuality(
  List<MainRoadsNetworkSegment> segments, {
  int detailLimit = 5000,
}) {
  // Canonical key = lexicographically smaller of forward/reversed sequence, so
  // a feature and its reversed twin land in one group.
  final groups = <String, List<(int, bool)>>{};
  var zeroPairs = 0;
  var zeroFeatures = 0;
  var degenerate = 0;
  var tiny = 0;
  var tinyFeatures = 0;
  final lengthBuckets = emptyBucketCounts();
  final tinyDetails = <Map<String, dynamic>>[];
  final zeroDetails = <Map<String, dynamic>>[];

  for (var f = 0; f < segments.length; f++) {
    final s = segments[f];
    var zero = 0;
    var tinyHere = 0;
    var allIdentical = true;
    for (var p = 0; p < s.parts.length; p++) {
      final g = s.parts[p];
      if (g.length < 2) throw ArgumentError('feature ${s.globalId} part $p has fewer than 2 vertices');

      final fwd = _seqKey(g);
      final rev = _seqKey(g.reversed);
      final forwardIsCanonical = fwd.compareTo(rev) <= 0;
      (groups[forwardIsCanonical ? fwd : rev] ??= []).add((f, forwardIsCanonical || fwd == rev));

      for (var i = 0; i + 1 < g.length; i++) {
        final a = g[i], b = g[i + 1];
        final identical = a.latitude == b.latitude && a.longitude == b.longitude;
        final len = identical ? 0.0 : haversineMetres(a.latitude, a.longitude, b.latitude, b.longitude);
        lengthBuckets.update(bucketForDistance(len, exact: identical).label, (v) => v + 1);
        if (identical) {
          zero++;
          if (zeroDetails.length < detailLimit) {
            zeroDetails.add({
              'globalId': s.globalId,
              'partIndex': p,
              'segmentIndex': i,
              'longitude': a.longitude,
              'latitude': a.latitude,
            });
          }
        } else if (len <= tinySegmentMetres) {
          tinyHere++;
          if (tinyDetails.length < detailLimit) {
            tinyDetails.add({'globalId': s.globalId, 'partIndex': p, 'segmentIndex': i, 'lengthMetres': len});
          }
        }
      }
      if (!g.every((c) => c.latitude == g.first.latitude && c.longitude == g.first.longitude)) {
        allIdentical = false;
      }
    }
    zeroPairs += zero;
    if (zero > 0) zeroFeatures++;
    tiny += tinyHere;
    if (tinyHere > 0) tinyFeatures++;
    if (allIdentical) degenerate++;
  }

  var dupGroups = 0;
  var exactPairs = 0;
  var reversedPairs = 0;
  final relations = <String, int>{};
  final details = <Map<String, dynamic>>[];
  for (final members in groups.values) {
    if (members.length < 2) continue;
    dupGroups++;
    for (var i = 0; i < members.length; i++) {
      for (var j = i + 1; j < members.length; j++) {
        final a = segments[members[i].$1], b = segments[members[j].$1];
        final sameDirection = members[i].$2 == members[j].$2;
        if (sameDirection) {
          exactPairs++;
        } else {
          reversedPairs++;
        }
        final rel = '${sameDirection ? 'exact' : 'reversed'}: '
            '${a.road == b.road ? 'same' : 'different'} ROAD, '
            '${a.routeNeId == b.routeNeId ? 'same' : 'different'} ROUTE_NE_ID';
        relations[rel] = (relations[rel] ?? 0) + 1;
        if (details.length < detailLimit) {
          details.add({
            'relation': rel,
            'globalIdA': a.globalId,
            'globalIdB': b.globalId,
            'roadA': a.road,
            'roadB': b.road,
            'routeNeIdA': a.routeNeId,
            'routeNeIdB': b.routeNeId,
          });
        }
      }
    }
  }

  return GeometryQuality(
    duplicateGroups: dupGroups,
    exactDuplicatePairs: exactPairs,
    reversedDuplicatePairs: reversedPairs,
    duplicatePairsByRelation: relations,
    zeroLengthPairs: zeroPairs,
    featuresWithZeroLengthPairs: zeroFeatures,
    degenerateFeatures: degenerate,
    segmentLengthBuckets: lengthBuckets,
    tinySegments: tiny,
    featuresWithTinySegments: tinyFeatures,
    duplicateDetails: details,
    tinyDetails: tinyDetails,
    zeroLengthDetails: zeroDetails,
  );
}
