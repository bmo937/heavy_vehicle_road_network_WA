import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

import '../../tool/main_roads_topology_probe/report.dart';
import '../../tool/main_roads_topology_probe/report_enrichment.dart';
import '../../tool/main_roads_topology_probe/summary.dart';

MainRoadsNetworkSegment _segment(String id, List<SourceCoordinate> geometry) => MainRoadsNetworkSegment(
      globalId: id,
      objectId: null,
      road: 'R1',
      roadName: null,
      routeNeId: 1,
      startSlk: 0,
      endSlk: 1,
      startTrueDist: 0,
      endTrueDist: 1,
      networkType: null,
      networkCategory: null,
      maxNetwork: 1,
      geometry: geometry,
    );

void main() {
  test('generated Markdown includes endpoint-to-segment proximity analysis', () {
    final analysis = analyzeSegments([
      _segment('target', const [
        SourceCoordinate(longitude: 115.0, latitude: -32.0),
        SourceCoordinate(longitude: 115.001, latitude: -32.0),
      ]),
      _segment('source', const [
        SourceCoordinate(longitude: 115.0005, latitude: -32.0000001),
        SourceCoordinate(longitude: 115.0005, latitude: -31.999),
      ]),
    ]);

    final summary = <String, dynamic>{
      'generatedAt': 'now',
      'status': 'COMPLETE',
      'incompleteReasons': <String>[],
      'source': {'service': 'test', 'layerId': 78, 'layerName': 'test', 'query': 'test'},
      'retrieval': {'pages': 1, 'retrievedFeatures': 2, 'serviceReportedCount': 2},
      'recordCount': 2,
      'scope': 'test',
      'analysis': analysis,
    };

    final report = enrichTopologyReportWithEndpointSegmentProximity(
      renderTopologyReport(summary),
      summary,
    );
    final proximity = analysis['endpointSegmentProximity'] as Map<String, dynamic>;

    expect(report, contains('Endpoint-to-segment proximity'));
    expect(report, contains('Eligible endpoints without an exact different-feature endpoint partner'));
    expect(
      report,
      contains(
        '| Eligible endpoints without an exact different-feature endpoint partner | ${proximity['eligibleEndpointCount']} |',
      ),
    );
    expect(report, contains('Nearest finite-segment distance'));
    expect(report, contains('Nearest segment-interior distance'));
    expect(report, contains('Nearest target location'));
    expect(report, isNot(contains('endpoint-to-segment proximity (not measured)')));
  });
}
