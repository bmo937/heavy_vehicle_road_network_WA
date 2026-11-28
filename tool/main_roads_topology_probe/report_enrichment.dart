/// Adds endpoint-to-segment proximity findings to the human-readable topology
/// report. The machine-readable summary remains the source of truth.
String enrichTopologyReportWithEndpointSegmentProximity(
  String report,
  Map<String, dynamic> summary,
) {
  final analysis = summary['analysis'] as Map<String, dynamic>?;
  final proximity = analysis?['endpointSegmentProximity'] as Map<String, dynamic>?;
  if (proximity == null) return report;

  final segmentBuckets = proximity['nearestSegmentDistanceBuckets'] as Map;
  final interiorBuckets = proximity['nearestInteriorDistanceBuckets'] as Map;
  final locations = proximity['nearestLocationKinds'] as Map;
  final roadRelation = proximity['byRoadRelation'] as Map;
  final details = proximity['details'] as List;

  final b = StringBuffer()
    ..writeln('## I. Endpoint-to-segment proximity')
    ..writeln()
    ..writeln('For endpoints without an exact different-feature endpoint partner, this diagnostic searches for the nearest finite segment belonging to another source feature within ${proximity['searchRadiusMetres']} m. Candidates are diagnostic only: no coordinate was snapped, no feature was split and no junction was created.')
    ..writeln()
    ..writeln('| Measure | Count |')
    ..writeln('|---|---:|')
    ..writeln('| Eligible endpoints without an exact different-feature endpoint partner | ${proximity['eligibleEndpointCount']} |')
    ..writeln('| Endpoints with a foreign-segment candidate within radius | ${proximity['endpointsWithCandidateWithinRadius']} |')
    ..writeln('| Endpoints without a foreign-segment candidate within radius | ${proximity['endpointsWithoutCandidateWithinRadius']} |')
    ..writeln()
    ..writeln('Nearest finite-segment distance: ${_inlineMap(segmentBuckets)}')
    ..writeln()
    ..writeln('Nearest segment-interior distance: ${_inlineMap(interiorBuckets)}')
    ..writeln()
    ..writeln('Nearest target location: ${_inlineMap(locations)}')
    ..writeln()
    ..writeln('By ROAD / ROUTE_NE_ID relation: ${_inlineMap(roadRelation)}')
    ..writeln()
    ..writeln('Detail records: ${details.length}${proximity['detailsTruncated'] == true ? ' (TRUNCATED)' : ''} in the JSON.')
    ..writeln();

  var enriched = report;
  const insertionPoint = '## J. Topology implications';
  if (enriched.contains(insertionPoint)) {
    enriched = enriched.replaceFirst(insertionPoint, '${b.toString()}## J. Topology implications');
  } else {
    enriched = '$enriched\n${b.toString()}';
  }

  enriched = enriched.replaceAll('endpoint-to-segment proximity (not measured)',
      'endpoint-to-segment proximity (measured; see section I)');
  enriched = enriched.replaceAll(
    'near-collinear overlaps and endpoint-to-segment near-misses (no tolerance is applied)',
    'near-collinear overlaps; whether endpoint-to-segment near-misses represent true junctions (no tolerance is applied)',
  );
  return enriched;
}

String _inlineMap(Map values) =>
    values.isEmpty ? 'none' : values.entries.map((e) => '${e.key}: ${e.value}').join('; ');
