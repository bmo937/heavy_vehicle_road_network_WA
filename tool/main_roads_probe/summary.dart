import 'analysis.dart';
import 'arcgis_client.dart';

const layer78 = 78;
const bridgeLayers = {29: 1, 34: 2, 74: 10};
const intersectionLayers = {30: 1, 35: 2, 75: 10};
const conditionLayers = {
  31: (1, 'With Conditions'),
  32: (1, 'Without Conditions'),
  36: (2, 'With Conditions'),
  37: (2, 'Without Conditions'),
  76: (10, 'With Conditions'),
  77: (10, 'Without Conditions')
};

const layer78Fields = [
  'ROAD',
  'ROAD_NAME',
  'START_SLK',
  'END_SLK',
  'START_TRUE_DIST',
  'END_TRUE_DIST',
  'NETWORK_TYPE',
  'NETWORK_CATEGORY',
  'MAX_NETWORK',
  'ROUTE_NE_ID',
  'OBJECTID',
  'GlobalID'
];
const bridgeFields = [
  'ROAD',
  'ROAD_NAME',
  'START_SLK',
  'START_TRUE_DIST',
  'STR_NO',
  'STR_NAME',
  'CROSSING_NAME',
  'NETWORK_TYPE',
  'NETWORK',
  'CONDITION',
  'LONGITUDE',
  'LATITUDE',
  'ROUTE_NE_ID',
  'OBJECTID',
  'GlobalID'
];
const conditionFields = [
  'ROAD',
  'ROAD_NAME',
  'START_SLK',
  'END_SLK',
  'START_TRUE_DIST',
  'END_TRUE_DIST',
  'NETWORK_TYPE',
  'LG_NAME',
  'ACCESS_TYPE',
  'NETWORK',
  'FROM_INTERSECTION',
  'TO_INTERSECTION',
  'COMMENTS',
  'MAX_SPEED',
  'CURFEW',
  'CONDITION',
  'PRODUCT',
  'OBJECTID',
  'GlobalID'
];
const intersectionFields = [
  'NODE_NAME',
  'NODE_DESCR',
  'NODE_TYPE',
  'NO_NODE_ID',
  'NETWORK',
  'CONDITION',
  'OBJECTID',
  'GlobalID'
];

/// Minimal sample: only selected fields, long text truncated.
Map<String, dynamic> sample(Attrs r, List<String> fields) => {
      for (final f in fields)
        if (isPopulated(r[f]))
          f: r[f] is String ? truncate(r[f] as String) : r[f],
    };

Map<String, dynamic> _layerHeader(LayerData d, List<String> fields) {
  final names = (d.metadata['fields'] is List)
      ? [
          for (final f in d.metadata['fields'] as List)
            if (f is Map) f['name']
        ]
      : <dynamic>[];
  return {
    'layerId': d.layerId,
    'name': d.metadata['name'],
    'recordCount': d.rows.length,
    'pages': d.pages,
    'complete': d.complete,
    if (d.incompleteReason != null) 'incompleteReason': d.incompleteReason,
    'maxRecordCount': d.metadata['maxRecordCount'],
    'expectedFieldsMissingFromMetadata': names.isEmpty
        ? null
        : [
            for (final f in fields)
              if (!names.contains(f)) f
          ],
    'fieldStats': {
      for (final e in fieldStats(d.rows, fields).entries)
        e.key: e.value.toJson()
    },
    'globalId': {'duplicates': duplicateStat(d.rows, 'GlobalID').toJson()},
  };
}

Map<String, dynamic> _matchSection(
  List<Attrs> rows,
  MatchTally tally,
  List<String> sampleFields,
) =>
    {
      ...tally.toJson(),
      'examples': {
        for (final e in tally.sampleRows.entries)
          e.key: [for (final i in e.value) sample(rows[i], sampleFields)],
      },
    };

/// Builds the machine-readable summary. [layers] holds successfully fetched
/// layers; [failures] holds layerId → error text. Failed layers get no stats.
Map<String, dynamic> buildSummary({
  required Map<int, LayerData> layers,
  required Map<int, String> failures,
  required int sampleLimit,
  required String generatedAt,
}) {
  final out = <String, dynamic>{
    'generatedAt': generatedAt,
    'sourceService': investigationBaseUrl,
    'allLayersCompleteAndSuccessful':
        failures.isEmpty && layers.values.every((l) => l.complete),
    'failedLayers': {for (final e in failures.entries) '${e.key}': e.value},
    'incompleteLayers': {
      for (final l in layers.values)
        if (!l.complete) '${l.layerId}': l.incompleteReason,
    },
  };

  final core = layers[layer78];
  List<Segment>? segments;
  if (core != null) {
    final rows = core.rows;
    segments = parseSegments(rows);
    final maxCounts = valueCounts(rows, 'MAX_NETWORK');
    out['layer78'] = {
      ..._layerHeader(core, layer78Fields),
      'routeNeIdDuplicates': {
        ...duplicateStat(rows, 'ROUTE_NE_ID').toJson(),
        'note': 'Duplicate ROUTE_NE_ID may be legitimate segment records.',
      },
      'maxNetworkValues': maxCounts,
      'networkTypeValues': valueCounts(rows, 'NETWORK_TYPE'),
      'networkCategoryValues': valueCounts(rows, 'NETWORK_CATEGORY'),
      'slkRanges': rangeStats(rows, 'START_SLK', 'END_SLK').toJson(),
      'trueDistRanges':
          rangeStats(rows, 'START_TRUE_DIST', 'END_TRUE_DIST').toJson(),
      'maxNetworkExamples': {
        for (final k in maxCounts.keys)
          k: sample(rows.firstWhere((r) => asText(r['MAX_NETWORK']) == k),
              layer78Fields),
      },
      'note':
          'MAX_NETWORK values are reported as observed; no eligibility hierarchy is inferred.',
    };
  }
  final coreOk = core != null && core.complete;

  for (final entry in bridgeLayers.entries) {
    final d = layers[entry.key];
    if (d == null) continue;
    final sec = {..._layerHeader(d, bridgeFields), 'networkLevel': entry.value};
    sec['missingRouteNeId'] =
        d.rows.where((r) => !isPopulated(r['ROUTE_NE_ID'])).length;
    sec['routeNeIdDuplicates'] = duplicateStat(d.rows, 'ROUTE_NE_ID').toJson();
    if (segments != null) {
      final tally = MatchTally();
      for (var i = 0; i < d.rows.length; i++) {
        tally.add(i, matchBridge(d.rows[i], segments),
            sampleLimit: sampleLimit);
      }
      sec['layer78Association'] = {
        'layer78Complete': coreOk,
        if (!coreOk)
          'warning': 'Layer 78 incomplete: unmatched counts are NOT reliable.',
        ..._matchSection(d.rows, tally, bridgeFields),
      };
    } else {
      sec['layer78Association'] = 'skipped: layer 78 unavailable';
    }
    (out['bridges'] ??= <String, dynamic>{})['${entry.key}'] = sec;
  }

  final evidence = <int, MaxNetworkEvidence>{
    1: MaxNetworkEvidence(1),
    2: MaxNetworkEvidence(2),
    10: MaxNetworkEvidence(10)
  };
  for (final entry in conditionLayers.entries) {
    final d = layers[entry.key];
    if (d == null) continue;
    final (network, classification) = entry.value;
    final sec = <String, dynamic>{
      ..._layerHeader(d, conditionFields),
      'networkLevel': network,
      'sourceClassification': classification,
      'roadRecordsPopulated':
          d.rows.where((r) => isPopulated(r['ROAD'])).length,
      'trueDistRanges':
          rangeStats(d.rows, 'START_TRUE_DIST', 'END_TRUE_DIST').toJson(),
      'slkRanges': rangeStats(d.rows, 'START_SLK', 'END_SLK').toJson(),
      'accessTypeValues': valueCounts(d.rows, 'ACCESS_TYPE'),
      'note':
          'Blank condition fields are not proof that no restriction exists.',
      'conditionExamples': [
        for (final r in d.rows
            .where((r) =>
                isPopulated(r['CONDITION']) || isPopulated(r['COMMENTS']))
            .take(sampleLimit))
          sample(r, conditionFields),
      ],
    };
    if (segments != null) {
      final tally = MatchTally();
      var exactRoad = 0;
      final roads = {
        for (final s in segments)
          if (s.road != null) s.road
      };
      for (var i = 0; i < d.rows.length; i++) {
        final m = matchConditionRecord(d.rows[i], segments);
        tally.add(i, m.result,
            evidenceDisagrees: m.evidenceDisagrees, sampleLimit: sampleLimit);
        if (roads.contains(asText(d.rows[i]['ROAD']))) exactRoad++;
        evidence[network]!.add(d.rows[i], segments);
      }
      sec['layer78Association'] = {
        'layer78Complete': coreOk,
        if (!coreOk)
          'warning': 'Layer 78 incomplete: unmatched counts are NOT reliable.',
        'exactRoadMatches': exactRoad,
        'note':
            'Ambiguous is expected where one record spans several layer-78 segments.',
        ..._matchSection(d.rows, tally, conditionFields),
      };
    } else {
      sec['layer78Association'] = 'skipped: layer 78 unavailable';
    }
    (out['conditions'] ??= <String, dynamic>{})['${entry.key}'] = sec;
  }
  if (segments != null && out['conditions'] != null) {
    out['maxNetworkComparison'] = {
      'layer78Complete': coreOk,
      'note': 'Evidence only. Naming alone is not used to infer a hierarchy.',
      for (final e in evidence.entries) 'network${e.key}': e.value.toJson(),
    };
  }

  for (final entry in intersectionLayers.entries) {
    final d = layers[entry.key];
    if (d == null) continue;
    (out['intersections'] ??= <String, dynamic>{})['${entry.key}'] = {
      ..._layerHeader(d, intersectionFields),
      'networkLevel': entry.value,
      'nodeTypeValues': valueCounts(d.rows, 'NODE_TYPE'),
      'noNodeIdDuplicates': duplicateStat(d.rows, 'NO_NODE_ID').toJson(),
      'nodeDescrExamples':
          valueCounts(d.rows, 'NODE_DESCR', maxDistinct: sampleLimit),
      'conditionExamples':
          valueCounts(d.rows, 'CONDITION', maxDistinct: sampleLimit),
      'conditionTextKeywordMentions':
          conditionTextMentions(d.rows, 'CONDITION'),
      'note':
          'Keyword mentions are evidence requiring later semantic interpretation. '
              'No decision is made about whole-node vs edge-transition meaning. '
              'Point geometry was not sampled.',
    };
  }
  return out;
}
