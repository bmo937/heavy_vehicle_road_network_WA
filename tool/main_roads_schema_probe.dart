import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'main_roads_probe/arcgis_client.dart';
import 'main_roads_probe/report.dart';
import 'main_roads_probe/summary.dart';

/// Read-only research probe. See tool/README.md.
/// Usage: dart run tool/main_roads_schema_probe.dart [--output-report=PATH] [--output-json=PATH] [--sample-limit=N]
Future<void> main(List<String> args) async {
  var reportPath = 'docs/main_roads_schema_investigation.md';
  var jsonPath = 'tool/output/main_roads_schema_summary.json';
  var sampleLimit = 3;
  for (final a in args) {
    if (a.startsWith('--output-report=')) {
      reportPath = a.substring('--output-report='.length);
    } else if (a.startsWith('--output-json=')) {
      jsonPath = a.substring('--output-json='.length);
    } else if (a.startsWith('--sample-limit=')) {
      sampleLimit = int.tryParse(a.substring('--sample-limit='.length)) ?? -1;
      if (sampleLimit < 0) {
        stderr.writeln('Invalid --sample-limit');
        exit(64);
      }
    } else {
      stderr.writeln('Unknown argument: $a');
      exit(64);
    }
  }

  final ids = <int>[layer78, ...bridgeLayers.keys, ...intersectionLayers.keys, ...conditionLayers.keys]..sort();
  final dio = buildProbeDio();
  final layers = <int, LayerData>{};
  final failures = <int, String>{};
  for (final id in ids) {
    stdout.writeln('Fetching layer $id ...');
    try {
      final d = await fetchAllAttributes(dio, id);
      layers[id] = d;
      stdout.writeln('  ${d.rows.length} records, ${d.pages} page(s), complete=${d.complete}');
    } on ProbeException catch (e) {
      failures[id] = e.message;
      stderr.writeln('  FAILED: ${e.message}');
    } on DioException catch (e) {
      failures[id] = 'Request failed: ${e.type.name}';
      stderr.writeln('  FAILED: ${e.type.name}');
    }
  }

  final summary = buildSummary(
    layers: layers,
    failures: failures,
    sampleLimit: sampleLimit,
    generatedAt: DateTime.now().toUtc().toIso8601String(),
  );
  File(jsonPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(summary)}\n');
  File(reportPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(renderReport(summary));
  stdout.writeln('Wrote $reportPath and $jsonPath');

  if (summary['allLayersCompleteAndSuccessful'] != true) {
    stderr.writeln('Run INCOMPLETE: see failedLayers/incompleteLayers in the report.');
    exit(2);
  }
}
