/// Renders the topology summary map (see summary.dart) as Markdown. Counts only
/// are tabulated; per-coordinate and per-crossing detail stays in the JSON.
String renderTopologyReport(Map<String, dynamic> s) {
  final b = StringBuffer();
  final status = s['status'] as String;
  final source = s['source'] as Map;
  final retrieval = s['retrieval'] as Map;
  final reasons = (s['incompleteReasons'] as List).cast<String>();
  final analysis = s['analysis'] as Map<String, dynamic>?;

  b.writeln('# Main Roads layer 78 topology investigation');
  b.writeln();
  b.writeln('Read-only diagnostic of PHYSICAL geometry topology. Generated ${s['generatedAt']}.');
  b.writeln();
  b.writeln('> ${s['scope']}');
  b.writeln();
  b.writeln('## A. Run status');
  b.writeln();
  b.writeln('- **Status: $status**');
  b.writeln('- Source: ${source['service']}/${source['layerId']} (${source['layerName']})');
  b.writeln('- Query: `${source['query']}`');
  b.writeln('- Pages fetched: ${retrieval['pages']}');
  b.writeln('- Features retrieved: ${retrieval['retrievedFeatures']}; service-reported count: ${retrieval['serviceReportedCount']}');
  b.writeln('- Parsed record count: ${s['recordCount'] ?? 'n/a'}');
  if (reasons.isNotEmpty) {
    b.writeln();
    b.writeln('**INCOMPLETE reasons:**');
    for (final r in reasons) {
      b.writeln('- $r');
    }
  }
  if (analysis == null) {
    b.writeln();
    b.writeln('No analysis was produced. Missing or rejected features are not evidence of disconnected roads, '
        'so no topology conclusions are drawn. Re-run the probe.');
    return b.toString();
  }

  final g = analysis['geometryAndSharing'] as Map<String, dynamic>;
  final p = analysis['endpointProximity'] as Map<String, dynamic>;
  final c = analysis['crossings'] as Map<String, dynamic>;
  final q = analysis['geometryQuality'] as Map<String, dynamic>;
  final dist = g['endpointGroupSizeDistribution'] as Map;
  final nearest = (p['nearestOtherEndpoint'] as Map).cast<String, int>();
  final nonIdentical = (p['nearestNonIdenticalEndpoint'] as Map).cast<String, int>();
  final endpoints = g['endpointAppearances'] as int;

  b.writeln();
  b.writeln('## B. Geometry inventory');
  b.writeln();
  _table(b, ['Measure', 'Count'], [
    ['Source features (GlobalIDs)', g['features']],
    ['Line parts (LineString = 1, MultiLineString = one per member line)', g['parts']],
    ['Total vertices', g['totalVertices']],
    ['Distinct exact coordinates', g['distinctCoordinates']],
    ['Source part endpoints (2 per line part)', endpoints],
    ['Distinct endpoint coordinates', g['distinctEndpointCoordinates']],
    ['Closed-loop line parts (first == last)', g['closedLoopParts']],
  ]);
  b.writeln();
  b.writeln('Coordinates are WGS84 longitude/latitude degrees; "exact" means identical doubles, no rounding.');

  b.writeln();
  b.writeln('## C. Exact endpoint connectivity');
  b.writeln();
  _table(b, ['Measure', 'Count'], [
    ['Endpoints coinciding exactly with an endpoint of a different feature', g['endpointsCoincidingWithOtherFeatureEndpoint']],
    ['Endpoint coordinate groups with one endpoint', dist['oneEndpoint']],
    ['Endpoint coordinate groups with exactly two endpoints', dist['twoEndpoints']],
    ['Endpoint coordinate groups with three or more endpoints', dist['threeOrMoreEndpoints']],
    ['Endpoint groups spanning more than one feature', g['endpointGroupsSharedByMultipleFeatures']],
  ]);
  b.writeln();
  b.writeln('Endpoint-count histogram per coordinate group: ${_inline(g['endpointGroupSizeHistogram'] as Map)}');
  b.writeln('(A closed-loop LineString contributes both its endpoints to one group.)');

  b.writeln();
  b.writeln('## D. Near-endpoint distances');
  b.writeln();
  b.writeln('Great-circle (haversine) metres to the nearest endpoint of a DIFFERENT feature, searched within '
      '${p['searchRadiusMetres']} m using a grid candidate filter. Exact equality is a separate class. '
      'Nothing is snapped and no tolerance is chosen.');
  b.writeln();
  b.writeln('| Bucket | Nearest other endpoint | Nearest non-identical endpoint |');
  b.writeln('|---|---:|---:|');
  for (final k in nearest.keys) {
    b.writeln('| $k | ${nearest[k]} | ${nonIdentical[k]} |');
  }
  b.writeln();
  b.writeln('"Nearest non-identical" ignores exact partners, so it exposes near-misses even for endpoints that '
      'also have an exact partner.');

  b.writeln();
  b.writeln('## E. Endpoint / internal-vertex relationships');
  b.writeln();
  _table(b, ['Measure', 'Count'], [
    ['Endpoints coinciding exactly with an INTERNAL vertex of another feature', g['endpointsOnOtherFeatureInternalVertex']],
    ['Coordinate groups where that happens', g['endpointInternalVertexGroups']],
  ]);

  b.writeln();
  b.writeln('## F. Shared internal vertices');
  b.writeln();
  _table(b, ['Measure', 'Count'], [
    ['Internal vertex occurrences (total)', g['internalVertexAppearances']],
    ['Internal vertex occurrences whose exact coordinate is used by another feature', g['internalVertexAppearancesSharedWithOtherFeature']],
    ['Coordinate groups where internal vertices of 2+ features meet', g['internalInternalGroups']],
    ['Groups where one feature repeats a coordinate at an internal vertex', g['selfRepeatedInternalVertexGroups']],
  ]);
  b.writeln();
  b.writeln('Coordinate groups shared by 2+ features, by kind: ${_inline(g['sharedGroupsByKind'] as Map)}');
  b.writeln('By participating feature count: ${_inline(g['sharedGroupsByFeatureCount'] as Map)}');
  b.writeln('By distinct ROAD values: ${_inline(g['sharedGroupsByDistinctRoads'] as Map)}');
  b.writeln('By distinct ROUTE_NE_ID values: ${_inline(g['sharedGroupsByDistinctRoutes'] as Map)}');
  b.writeln();
  b.writeln('Per-group detail (${(g['sharedGroupDetails'] as List).length} recorded'
      '${g['sharedGroupDetailsTruncated'] == true ? ', TRUNCATED' : ''}) is in the JSON output only.');

  final crossings = c['unrepresentedCrossings'] as int;
  b.writeln();
  b.writeln('## G. Geometric crossings without shared vertices');
  b.writeln();
  b.writeln('Intersections between different features that are not at an exact shared source vertex. '
      'A crossing is NOT a junction (grade separation may exist) and none was created. Tests use exact '
      'double arithmetic in lon/lat space (axis-scaling invariant); near-misses and near-collinear overlaps '
      'are not detected.');
  b.writeln();
  _table(b, ['Measure', 'Count'], [
    ['Segments indexed', c['indexedSegments']],
    ['Segment pairs a naive comparison would test', c['naiveSegmentPairs']],
    ['Candidate pairs after grid + bounding-box filter', c['candidatePairsTested']],
    ['Unrepresented crossings', crossings],
    ['...of which involve a feature endpoint', c['crossingsInvolvingEndpoint']],
  ]);
  b.writeln();
  b.writeln('By kind: ${_inline(c['byKind'] as Map)}');
  b.writeln('By role of each feature at the intersection: ${_inline(c['byRoles'] as Map)}');
  b.writeln('By ROAD / ROUTE_NE_ID relation: ${_inline(c['byRoadRelation'] as Map)}');
  b.writeln('Distance from intersection to the nearer feature\'s own nearest vertex: ${_inline(c['nearestOwnVertexDistanceBuckets'] as Map)}');
  b.writeln();
  b.writeln('Detail records: ${(c['details'] as List).length}${c['detailsTruncated'] == true ? ' (TRUNCATED)' : ''} in the JSON.');

  b.writeln();
  b.writeln('## H. Duplicate / reversed geometry');
  b.writeln();
  _table(b, ['Measure', 'Count'], [
    ['Duplicate-geometry groups', q['duplicateGeometryGroups']],
    ['Exact duplicate pairs', q['exactDuplicatePairs']],
    ['Reversed duplicate pairs', q['reversedDuplicatePairs']],
    ['Zero-length consecutive coordinate pairs', q['zeroLengthConsecutivePairs']],
    ['Features containing zero-length pairs', q['featuresWithZeroLengthPairs']],
    ['Degenerate features (all vertices identical)', q['degenerateFeaturesAllVerticesIdentical']],
    ['Tiny segments (>0 to ${q['tinySegmentThresholdMetres']} m)', q['tinySegments']],
    ['Features containing tiny segments', q['featuresWithTinySegments']],
  ]);
  b.writeln();
  b.writeln('Duplicate pairs by relation: ${_inline(q['duplicatePairsByRelation'] as Map)}');
  b.writeln('Segment length buckets (exact = zero length): ${_inline(q['segmentLengthBuckets'] as Map)}');
  b.writeln('Nothing was deduplicated, removed or repaired.');

  b.writeln();
  b.writeln('## I. ROUTE_NE_ID / ROAD continuity at shared endpoints');
  b.writeln();
  b.writeln('Feature pairs meeting at an exact shared endpoint. Diagnostic only: no turn permission or merge is implied.');
  b.writeln();
  final pairs = (g['continuityPairs'] as Map).cast<String, int>();
  final cats = [
    'A: same ROAD + same ROUTE_NE_ID',
    'B: same ROAD + different ROUTE_NE_ID',
    'C: different ROAD + same ROUTE_NE_ID',
    'D: different ROAD + different ROUTE_NE_ID',
  ];
  _table(b, ['Category', 'Feature pairs'], [for (final k in cats) [k, pairs[k] ?? 0]]);
  b.writeln();
  b.writeln('Shared-endpoint groups by the set of categories present: ${_inline(g['continuityGroups'] as Map)}');

  // Derived figures for the conclusions.
  final exactPartner = g['endpointsCoincidingWithOtherFeatureEndpoint'] as int;
  final onInternal = g['endpointsOnOtherFeatureInternalVertex'] as int;
  final internalInternal = g['internalInternalGroups'] as int;
  final noExact = endpoints - (nearest['exact same coordinate'] ?? 0);
  int within(List<String> keys) => keys.fold(0, (a, k) => a + (nearest[k] ?? 0));
  final near1 = within(['>0 to 0.1 m', '>0.1 to 0.5 m', '>0.5 to 1 m']);
  final near2 = near1 + within(['>1 to 2 m']);
  final near10 = near2 + within(['>2 to 5 m', '>5 to 10 m']);
  final splitEvidence = onInternal > 0 || internalInternal > 0;
  final dupPairs = (q['exactDuplicatePairs'] as int) + (q['reversedDuplicatePairs'] as int);

  b.writeln();
  b.writeln('## J. Topology implications');
  b.writeln();
  b.writeln('### CONFIRMED FROM DATA');
  b.writeln();
  b.writeln('- $exactPartner of $endpoints endpoints ($noExact do not) coincide exactly with an endpoint of another feature.');
  b.writeln('- $onInternal endpoints coincide exactly with an internal vertex of another feature '
      '(${g['endpointInternalVertexGroups']} coordinate groups).');
  b.writeln('- $internalInternal coordinate groups join internal vertices of two or more features.');
  b.writeln('- Of the $noExact endpoints without an exact partner, $near1 have a different-feature endpoint within 1 m, '
      '$near2 within 2 m and $near10 within 10 m (nearest-other measure).');
  b.writeln('- $crossings geometric intersections are not represented by a shared source vertex.');
  b.writeln('- $dupPairs duplicate/reversed geometry pairs; ${q['zeroLengthConsecutivePairs']} zero-length vertex pairs; '
      '${q['tinySegments']} tiny segments.');
  b.writeln(splitEvidence
      ? '- Segmentation: the source is NOT uniformly split at shared vertices; at least some features carry an '
          'interior vertex that coincides with another feature\'s vertex or endpoint.'
      : '- Segmentation: no endpoint lies on another feature\'s internal vertex and no internal vertices are shared, '
          'so no exact-vertex evidence for further splitting was found. This says nothing about crossings (see G).');
  b.writeln();
  b.writeln('### RECOMMENDATION FOR FUTURE COMPILER');
  b.writeln();
  b.writeln('- Treat exact coordinate equality as the only confirmed node identity; do not merge near endpoints '
      'without a separate, evidenced decision.');
  if (splitEvidence) {
    b.writeln('- Plan to split features at shared internal vertices / endpoint-on-vertex contacts so those contacts can become nodes.');
  }
  if (crossings > 0) {
    b.writeln('- Keep the $crossings unrepresented crossings as non-junctions until inspected; some may be grade separations.');
  }
  if (dupPairs > 0 || (q['zeroLengthConsecutivePairs'] as int) > 0) {
    b.writeln('- Decide explicitly how duplicate geometries and zero-length vertex pairs are handled; they are not removed here.');
  }
  b.writeln('- Missing or unmatched endpoints must not be assumed to be dead ends.');

  b.writeln();
  b.writeln('## K. Candidate next milestone');
  b.writeln();
  b.writeln('Decision support only; no compiler is implemented here.');
  b.writeln();
  b.writeln('- **Endpoint-only topology:** ${exactPartner > 0 ? 'supported as a baseline' : 'not supported'} '
      '($exactPartner endpoints have exact partners), but it leaves $noExact endpoints unconnected.');
  b.writeln('- **Snapped endpoint topology:** ${near10 > 0 ? 'needs further investigation' : 'no near-miss evidence'}. '
      'Candidate tolerances to study (not chosen): 0.1 m, 0.5 m, 1 m, 2 m, 5 m, 10 m; endpoints without an exact partner and '
      'within 1 / 2 / 10 m: $near1 / $near2 / $near10.');
  b.writeln('- **Splitting at shared internal vertices:** ${splitEvidence ? 'indicated by the data' : 'not indicated by exact-vertex evidence'}.');
  final further = <String>[
    if (crossings > 0) 'unrepresented crossings ($crossings)',
    if (dupPairs > 0) 'duplicate geometries ($dupPairs pairs)',
    if ((q['zeroLengthConsecutivePairs'] as int) > 0) 'zero-length pairs',
    if (near10 > 0) 'endpoint near-misses',
    'endpoint-to-segment proximity (not measured)',
  ];
  b.writeln('- **Further geometry investigation:** ${further.join('; ')}.');
  b.writeln();
  b.writeln('**Cannot be established by this diagnostic:** whether crossings are junctions or grade separations; '
      'whether near endpoints are the same node; near-collinear overlaps and endpoint-to-segment near-misses '
      '(no tolerance is applied); self-crossings within one feature; any eligibility or restriction semantics.');
  return b.toString();
}

String _inline(Map m) => m.isEmpty ? 'none' : m.entries.map((e) => '${e.key}: ${e.value}').join('; ');

void _table(StringBuffer b, List<String> header, List<List<Object?>> rows) {
  b.writeln('| ${header.join(' | ')} |');
  b.writeln('|${header.map((_) => '---').join('|')}|');
  for (final r in rows) {
    b.writeln('| ${r.join(' | ')} |');
  }
}
