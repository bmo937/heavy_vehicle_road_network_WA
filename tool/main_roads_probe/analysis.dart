// Pure analysis functions for the Main Roads schema investigation.
// Research tooling only: no HTTP, no routing assumptions.

typedef Attrs = Map<String, dynamic>;

double? toDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

/// Null, or a string that is empty/whitespace, counts as unpopulated.
bool isPopulated(Object? v) => v != null && !(v is String && v.trim().isEmpty);

String? asText(Object? v) => isPopulated(v) ? v.toString().trim() : null;

String truncate(String s, [int max = 120]) => s.length <= max ? s : '${s.substring(0, max)}…';

/// A validated numeric range. [tryCreate] returns null when either end is
/// missing or the range is reversed, so invalid ranges are never used as evidence.
class Interval {
  final double start;
  final double end;
  const Interval(this.start, this.end);

  static Interval? tryCreate(Object? start, Object? end) {
    final s = toDouble(start), e = toDouble(end);
    if (s == null || e == null || e < s) return null;
    return Interval(s, e);
  }

  bool get isZeroLength => start == end;
  bool containsPoint(double p) => p >= start && p <= end;
}

/// Overlap with positive length; a zero-length interval overlaps when its point
/// lies inside (inclusive) the other. Ranges that merely touch at a shared
/// endpoint do NOT overlap, to avoid manufacturing ambiguity at segment joins.
bool intervalsOverlap(Interval a, Interval b) {
  if (a.isZeroLength) return b.containsPoint(a.start);
  if (b.isZeroLength) return a.containsPoint(b.start);
  return a.start < b.end && b.start < a.end;
}

enum MatchStatus { confirmed, ambiguous, unmatched }

class MatchResult {
  final MatchStatus status;
  /// Indices into the layer-78 record list.
  final List<int> candidates;
  final String basis;
  /// null = not evaluable.
  final bool? roadAgrees;
  final bool? slkAgrees;
  const MatchResult(this.status, this.candidates, this.basis, {this.roadAgrees, this.slkAgrees});
}

/// Layer 78 segment, parsed once.
class Segment {
  final int index;
  final String? road;
  final String? routeNeId;
  final Interval? slk;
  final Interval? trueDist;
  final String? maxNetwork;
  const Segment(this.index, this.road, this.routeNeId, this.slk, this.trueDist, this.maxNetwork);

  factory Segment.fromAttrs(int index, Attrs a) => Segment(
        index,
        asText(a['ROAD']),
        asText(a['ROUTE_NE_ID']),
        Interval.tryCreate(a['START_SLK'], a['END_SLK']),
        Interval.tryCreate(a['START_TRUE_DIST'], a['END_TRUE_DIST']),
        asText(a['MAX_NETWORK']),
      );
}

List<Segment> parseSegments(List<Attrs> rows) => [for (var i = 0; i < rows.length; i++) Segment.fromAttrs(i, rows[i])];

/// Bridge → layer 78. Order of evidence: ROUTE_NE_ID, then true-distance
/// position, with SLK and ROAD as validation only. Multiple candidates are
/// never collapsed to one.
MatchResult matchBridge(Attrs bridge, List<Segment> segments) {
  final routeId = asText(bridge['ROUTE_NE_ID']);
  final road = asText(bridge['ROAD']);
  final td = toDouble(bridge['START_TRUE_DIST']);
  final slk = toDouble(bridge['START_SLK']);

  List<Segment> pool;
  String basis;
  if (routeId != null) {
    pool = segments.where((s) => s.routeNeId == routeId).toList();
    if (pool.isEmpty) return const MatchResult(MatchStatus.unmatched, [], 'routeIdNotFound');
    basis = 'routeId';
  } else if (road != null && td != null) {
    pool = segments.where((s) => s.road == road).toList();
    if (pool.isEmpty) return const MatchResult(MatchStatus.unmatched, [], 'roadNotFound');
    basis = 'roadFallback';
  } else {
    return const MatchResult(MatchStatus.unmatched, [], 'missingJoinFields');
  }

  var found = pool;
  if (td != null) {
    found = pool.where((s) => s.trueDist?.containsPoint(td) ?? false).toList();
    if (found.isEmpty) {
      // Route/road matched but position did not: a disagreement, not a match.
      return MatchResult(MatchStatus.unmatched, const [], '${basis}PositionOutsideRange');
    }
    basis = '${basis}AndTrueDist';
  } else if (basis == 'routeId') {
    basis = 'routeIdOnlyNoPosition';
  }

  final idx = [for (final s in found) s.index];
  final status = found.length == 1 ? MatchStatus.confirmed : MatchStatus.ambiguous;
  final only = found.length == 1 ? found.first : null;
  return MatchResult(
    status,
    idx,
    basis,
    roadAgrees: only == null || only.road == null || road == null ? null : only.road == road,
    slkAgrees: only == null || only.slk == null || slk == null ? null : only.slk!.containsPoint(slk),
  );
}

/// With/Without Conditions record → layer 78: exact ROAD plus overlapping
/// true-distance interval; SLK overlap reported as an independent check.
class ConditionMatch {
  final MatchResult result;
  final List<int> slkCandidates;
  /// True when both evidence sets were evaluable and differ.
  final bool evidenceDisagrees;
  const ConditionMatch(this.result, this.slkCandidates, this.evidenceDisagrees);
}

ConditionMatch matchConditionRecord(Attrs rec, List<Segment> segments) {
  final road = asText(rec['ROAD']);
  if (road == null) {
    return const ConditionMatch(MatchResult(MatchStatus.unmatched, [], 'missingRoad'), [], false);
  }
  final sameRoad = segments.where((s) => s.road == road).toList();
  if (sameRoad.isEmpty) {
    return const ConditionMatch(MatchResult(MatchStatus.unmatched, [], 'roadNotFound'), [], false);
  }
  final td = Interval.tryCreate(rec['START_TRUE_DIST'], rec['END_TRUE_DIST']);
  final slk = Interval.tryCreate(rec['START_SLK'], rec['END_SLK']);

  final tdHits = td == null
      ? <Segment>[]
      : sameRoad.where((s) => s.trueDist != null && intervalsOverlap(td, s.trueDist!)).toList();
  final slkHits = slk == null
      ? <Segment>[]
      : sameRoad.where((s) => s.slk != null && intervalsOverlap(slk, s.slk!)).toList();

  final tdIdx = [for (final s in tdHits) s.index];
  final slkIdx = [for (final s in slkHits) s.index];

  final MatchResult result;
  if (td == null) {
    result = const MatchResult(MatchStatus.unmatched, [], 'roadMatchedInvalidOrMissingTrueDist', roadAgrees: true);
  } else if (tdHits.isEmpty) {
    result = const MatchResult(MatchStatus.unmatched, [], 'roadMatchedNoTrueDistOverlap', roadAgrees: true);
  } else {
    result = MatchResult(
      tdHits.length == 1 ? MatchStatus.confirmed : MatchStatus.ambiguous,
      tdIdx,
      'roadAndTrueDistOverlap',
      roadAgrees: true,
    );
  }
  final evaluable = td != null && slk != null;
  final disagrees = evaluable && !(tdIdx.length == slkIdx.length && tdIdx.toSet().containsAll(slkIdx));
  return ConditionMatch(result, slkIdx, disagrees);
}

class FieldStat {
  final int populated;
  final int unpopulated;
  const FieldStat(this.populated, this.unpopulated);
  Map<String, int> toJson() => {'populated': populated, 'unpopulated': unpopulated};
}

Map<String, FieldStat> fieldStats(List<Attrs> rows, List<String> fields) => {
      for (final f in fields)
        f: () {
          final p = rows.where((r) => isPopulated(r[f])).length;
          return FieldStat(p, rows.length - p);
        }(),
    };

/// Counts of each populated value (as text), sorted by descending count.
Map<String, int> valueCounts(List<Attrs> rows, String field, {int maxDistinct = 100}) {
  final m = <String, int>{};
  for (final r in rows) {
    final v = asText(r[field]);
    if (v != null) m[v] = (m[v] ?? 0) + 1;
  }
  final entries = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return {for (final e in entries.take(maxDistinct)) truncate(e.key, 80): e.value};
}

class DuplicateStat {
  final int distinctValuesDuplicated;
  final int recordsInDuplicateGroups;
  const DuplicateStat(this.distinctValuesDuplicated, this.recordsInDuplicateGroups);
  Map<String, int> toJson() =>
      {'distinctValuesDuplicated': distinctValuesDuplicated, 'recordsInDuplicateGroups': recordsInDuplicateGroups};
}

/// Populated values only; nulls are never counted as duplicates.
DuplicateStat duplicateStat(List<Attrs> rows, String field) {
  final m = <String, int>{};
  for (final r in rows) {
    final v = asText(r[field]);
    if (v != null) m[v.toLowerCase()] = (m[v.toLowerCase()] ?? 0) + 1;
  }
  final dups = m.values.where((c) => c > 1);
  return DuplicateStat(dups.length, dups.fold(0, (a, b) => a + b));
}

class RangeStats {
  final int valid;
  final int missing;
  final int reversed;
  final int zeroLength;
  const RangeStats(this.valid, this.missing, this.reversed, this.zeroLength);
  Map<String, int> toJson() => {'valid': valid, 'missing': missing, 'reversed': reversed, 'zeroLength': zeroLength};
}

RangeStats rangeStats(List<Attrs> rows, String startField, String endField) {
  var valid = 0, missing = 0, reversed = 0, zero = 0;
  for (final r in rows) {
    final s = toDouble(r[startField]), e = toDouble(r[endField]);
    if (s == null || e == null) {
      missing++;
    } else if (e < s) {
      reversed++;
    } else {
      valid++;
      if (e == s) zero++;
    }
  }
  return RangeStats(valid, missing, reversed, zero);
}

/// Tallies of match outcomes, with a few row-index samples per status.
class MatchTally {
  final Map<String, int> byStatus = {for (final s in MatchStatus.values) s.name: 0};
  final Map<String, int> byBasis = {};
  int roadDisagreements = 0;
  int slkDisagreements = 0;
  int evidenceDisagreements = 0;
  final Map<String, List<int>> sampleRows = {};

  void add(int rowIndex, MatchResult r, {bool evidenceDisagrees = false, int sampleLimit = 3}) {
    byStatus[r.status.name] = byStatus[r.status.name]! + 1;
    byBasis[r.basis] = (byBasis[r.basis] ?? 0) + 1;
    if (r.roadAgrees == false) roadDisagreements++;
    if (r.slkAgrees == false) slkDisagreements++;
    if (evidenceDisagrees) evidenceDisagreements++;
    final list = sampleRows.putIfAbsent(r.status.name, () => []);
    if (list.length < sampleLimit) list.add(rowIndex);
  }

  Map<String, dynamic> toJson() => {
        'byStatus': byStatus,
        'byBasis': byBasis,
        'roadDisagreements': roadDisagreements,
        'slkDisagreements': slkDisagreements,
        'trueDistVsSlkEvidenceDisagreements': evidenceDisagreements,
      };
}

/// Keyword evidence only. NOT a parser; each flag needs later semantic review.
Map<String, int> conditionTextMentions(List<Attrs> rows, String field) {
  final patterns = {
    'road': RegExp(r'\b(road|rd|street|st|highway|hwy|drive|dr|avenue|ave)\b', caseSensitive: false),
    'approach': RegExp(r'\bapproach(es)?\b', caseSensitive: false),
    'direction': RegExp(r'\b(north|south|east|west|northbound|southbound|eastbound|westbound|[nsew]b)\b',
        caseSensitive: false),
    'movement': RegExp(r'\b(turn|turning|left|right|u-turn|movement|straight)\b', caseSensitive: false),
  };
  final out = {for (final k in patterns.keys) k: 0};
  for (final r in rows) {
    final t = asText(r[field]);
    if (t == null) continue;
    patterns.forEach((k, p) {
      if (p.hasMatch(t)) out[k] = out[k]! + 1;
    });
  }
  return out;
}

/// Evidence for the MAX_NETWORK question. [network] is the numeric level of the
/// individual-network layer. Never yields an unambiguous rule: at most
/// "contradicts" or "insufficient".
class MaxNetworkEvidence {
  final int network;
  int recordsConsidered = 0;
  int recordsWithOverlap = 0;
  int pairsMaxGeNetwork = 0;
  int pairsMaxLtNetwork = 0;
  int pairsUnparsableMax = 0;
  final Map<String, int> overlappedMaxNetworkValues = {};
  MaxNetworkEvidence(this.network);

  void add(Attrs rec, List<Segment> segments) {
    recordsConsidered++;
    final m = matchConditionRecord(rec, segments);
    if (m.result.candidates.isEmpty) return;
    recordsWithOverlap++;
    for (final i in m.result.candidates) {
      final mx = segments[i].maxNetwork;
      final key = mx ?? '(null)';
      overlappedMaxNetworkValues[key] = (overlappedMaxNetworkValues[key] ?? 0) + 1;
      final n = toDouble(mx);
      if (n == null) {
        pairsUnparsableMax++;
      } else if (n >= network) {
        pairsMaxGeNetwork++;
      } else {
        pairsMaxLtNetwork++;
      }
    }
  }

  String get verdict {
    if (recordsWithOverlap == 0) return 'insufficient (no overlapping layer-78 records)';
    if (pairsMaxLtNetwork > 0) {
      return 'contradicts a simple cumulative rule in $pairsMaxLtNetwork overlapping pair(s)';
    }
    return 'insufficient: no contradiction observed, but overlap alone does not establish a rule';
  }

  Map<String, dynamic> toJson() => {
        'network': network,
        'recordsConsidered': recordsConsidered,
        'recordsWithLayer78Overlap': recordsWithOverlap,
        'pairsMaxNetworkNumericGeNetwork': pairsMaxGeNetwork,
        'pairsMaxNetworkNumericLtNetwork': pairsMaxLtNetwork,
        'pairsMaxNetworkUnparsable': pairsUnparsableMax,
        'overlappedMaxNetworkValues': overlappedMaxNetworkValues,
        'verdict': verdict,
      };
}
