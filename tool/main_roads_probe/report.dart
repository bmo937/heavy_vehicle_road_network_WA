import 'dart:convert';

/// Renders a concise Markdown report from the summary map. Pure function.
String renderReport(Map<String, dynamic> s) {
  final b = StringBuffer()
    ..writeln('# Main Roads HVS schema investigation')
    ..writeln()
    ..writeln('Research evidence only. Nothing here is a routing rule.')
    ..writeln()
    ..writeln('- Source service: `${s['sourceService']}`')
    ..writeln('- Generated (UTC): ${s['generatedAt']}')
    ..writeln('- Regenerate: `dart run tool/main_roads_schema_probe.dart`')
    ..writeln();

  final failed = (s['failedLayers'] as Map).cast<String, dynamic>();
  final incomplete = (s['incompleteLayers'] as Map).cast<String, dynamic>();
  if (s['allLayersCompleteAndSuccessful'] == true) {
    b.writeln('**Run status: COMPLETE** (all layers fetched with full pagination).');
  } else {
    b.writeln('**Run status: INCOMPLETE - do not rely on this report.**');
    for (final e in failed.entries) {
      b.writeln('- Layer ${e.key} FAILED: ${e.value}');
    }
    for (final e in incomplete.entries) {
      b.writeln('- Layer ${e.key} partial: ${e.value}');
    }
  }
  b.writeln();

  String json(Object? o) => const JsonEncoder.withIndent('  ').convert(o);
  void block(String title, Object? o) {
    b
      ..writeln('### $title')
      ..writeln()
      ..writeln('```json')
      ..writeln(json(o))
      ..writeln('```')
      ..writeln();
  }

  void layerTable(String heading, Map<String, dynamic>? layers) {
    if (layers == null) return;
    b
      ..writeln('## $heading')
      ..writeln()
      ..writeln('| Layer | Name | Records | Complete |')
      ..writeln('|---|---|---|---|');
    for (final e in layers.entries) {
      final l = e.value as Map;
      b.writeln('| ${e.key} | ${l['name']} | ${l['recordCount']} | ${l['complete']} |');
    }
    b.writeln();
    for (final e in layers.entries) {
      final l = Map<String, dynamic>.from(e.value as Map);
      block('Layer ${e.key}: ${l['name']}', l..remove('layerId')..remove('name'));
    }
  }

  if (s['layer78'] != null) {
    final l = Map<String, dynamic>.from(s['layer78'] as Map);
    b.writeln('## Layer 78 - Tandem Drive 1-10 All Networks\n');
    block('Summary', l);
  }
  layerTable('Bridges (29, 34, 74)', (s['bridges'] as Map?)?.cast<String, dynamic>());
  layerTable('With/Without Conditions (31, 32, 36, 37, 76, 77)', (s['conditions'] as Map?)?.cast<String, dynamic>());
  layerTable('Intersections (30, 35, 75)', (s['intersections'] as Map?)?.cast<String, dynamic>());
  if (s['maxNetworkComparison'] != null) {
    b.writeln('## MAX_NETWORK comparison\n');
    block('Evidence', s['maxNetworkComparison']);
  }
  b.writeln('## Limitations\n');
  b
    ..writeln('- Geometry was not sampled; no spatial validation of intersections or joins was performed.')
    ..writeln('- "Ambiguous" means multiple layer-78 candidates; no candidate was forced.')
    ..writeln('- Blank condition fields are not evidence of an unrestricted road.')
    ..writeln('- Textual observations need later semantic interpretation.');
  return b.toString();
}
