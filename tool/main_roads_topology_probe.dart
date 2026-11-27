import 'dart:convert';
import 'dart:io';

import 'main_roads_probe/arcgis_client.dart';
import 'main_roads_topology_probe/fetch.dart';
import 'main_roads_topology_probe/report.dart';
import 'main_roads_topology_probe/summary.dart';

/// Read-only research probe. See tool/README.md. Not imported by lib/.
/// Usage: dart run tool/main_roads_topology_probe.dart [--output-report=PATH] [--output-json=PATH]
Future<void> main(List<String> args) async {
  var reportPath = 'docs/main_roads_topology_investigation.md';
  var jsonPath = 'tool/output/main_roads_topology_summary.json';
  for (final a in args) {
    if (a.startsWith('--output-report=')) {
      reportPath = a.substring('--output-report='.length);
    } else if (a.startsWith('--output-json=')) {
      jsonPath = a.substring('--output-json='.length);
    } else {
      stderr.writeln('Unknown argument: $a');
      exit(64);
    }
  }

  stdout.writeln('Fetching layer $topologyLayerId with geometry ...');
  final fetch = await fetchLayerGeoJson(buildProbeDio());
  stdout.writeln('  ${fetch.retrieved} features, ${fetch.pages} page(s), complete=${fetch.complete}');

  final summary = buildTopologySummary(fetch, generatedAt: DateTime.now().toUtc().toIso8601String());
  File(jsonPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(summary)}\n');
  File(reportPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(renderTopologyReport(summary));
  stdout.writeln('Wrote $reportPath and $jsonPath');

  if (summary['status'] != 'COMPLETE') {
    stderr.writeln('Run INCOMPLETE: ${(summary['incompleteReasons'] as List).join('; ')}');
    exit(2);
  }
}
