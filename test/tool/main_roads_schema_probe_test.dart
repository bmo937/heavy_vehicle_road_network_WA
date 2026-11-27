import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/main_roads_probe/analysis.dart';
import '../../tool/main_roads_probe/arcgis_client.dart';
import '../../tool/main_roads_probe/summary.dart';

class _Adapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) handler;
  final List<Uri> requests = [];
  _Adapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add(o.uri);
    return handler(o);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _body(Object json, [int status = 200]) =>
    ResponseBody.fromString(json is String ? json : jsonEncode(json), status,
        headers: {Headers.contentTypeHeader: ['application/json']});

Dio _dio(_Adapter a) => Dio(BaseOptions(responseType: ResponseType.plain))..httpClientAdapter = a;

Map<String, dynamic> _feat(int id) => {'attributes': {'OBJECTID': id}};

Segment _seg(int i, {String? road = 'H001', String? route, double? td0, double? td1, double? slk0, double? slk1}) =>
    Segment.fromAttrs(i, {
      'ROAD': road,
      'ROUTE_NE_ID': route,
      'START_TRUE_DIST': td0,
      'END_TRUE_DIST': td1,
      'START_SLK': slk0,
      'END_SLK': slk1,
    });

void main() {
  group('intervalsOverlap', () {
    test('overlapping, disjoint and touching ranges', () {
      expect(intervalsOverlap(const Interval(0, 5), const Interval(4, 9)), isTrue);
      expect(intervalsOverlap(const Interval(0, 5), const Interval(6, 9)), isFalse);
      expect(intervalsOverlap(const Interval(0, 5), const Interval(5, 9)), isFalse);
    });

    test('zero-length point inside is overlap', () {
      expect(intervalsOverlap(const Interval(3, 3), const Interval(0, 5)), isTrue);
      expect(intervalsOverlap(const Interval(7, 7), const Interval(0, 5)), isFalse);
    });

    test('reversed or null ranges are rejected', () {
      expect(Interval.tryCreate(5, 1), isNull);
      expect(Interval.tryCreate(null, 1), isNull);
      expect(Interval.tryCreate('1.5', '2'), isNotNull);
    });
  });

  group('matchBridge', () {
    final segs = [
      _seg(0, route: 'R1', td0: 0, td1: 5, slk0: 0, slk1: 5),
      _seg(1, route: 'R1', td0: 5, td1: 10, slk0: 5, slk1: 10),
      _seg(2, route: 'R2', td0: 0, td1: 10),
    ];

    test('route id plus true distance confirms one segment', () {
      final r = matchBridge({'ROUTE_NE_ID': 'R1', 'ROAD': 'H001', 'START_TRUE_DIST': 7, 'START_SLK': 7}, segs);
      expect(r.status, MatchStatus.confirmed);
      expect(r.candidates, [1]);
      expect(r.roadAgrees, isTrue);
      expect(r.slkAgrees, isTrue);
    });

    test('boundary position matching two segments is ambiguous', () {
      final r = matchBridge({'ROUTE_NE_ID': 'R1', 'START_TRUE_DIST': 5}, segs);
      expect(r.status, MatchStatus.ambiguous);
      expect(r.candidates, [0, 1]);
    });

    test('route id without position over multiple segments is ambiguous', () {
      expect(matchBridge({'ROUTE_NE_ID': 'R1'}, segs).status, MatchStatus.ambiguous);
    });

    test('unknown route id is unmatched', () {
      expect(matchBridge({'ROUTE_NE_ID': 'X', 'START_TRUE_DIST': 1}, segs).status, MatchStatus.unmatched);
    });

    test('route matched but position outside range is unmatched', () {
      final r = matchBridge({'ROUTE_NE_ID': 'R2', 'START_TRUE_DIST': 50}, segs);
      expect(r.status, MatchStatus.unmatched);
      expect(r.basis, contains('PositionOutsideRange'));
    });

    test('null join fields are unmatched, not forced', () {
      final r = matchBridge({'ROUTE_NE_ID': ' ', 'ROAD': null}, segs);
      expect(r.status, MatchStatus.unmatched);
      expect(r.basis, 'missingJoinFields');
    });

    test('ROAD disagreement is reported', () {
      final r = matchBridge({'ROUTE_NE_ID': 'R2', 'ROAD': 'H999', 'START_TRUE_DIST': 3}, segs);
      expect(r.status, MatchStatus.confirmed);
      expect(r.roadAgrees, isFalse);
    });

    test('segments with reversed ranges never match by position', () {
      final bad = [_seg(0, route: 'R1', td0: 9, td1: 1)];
      expect(matchBridge({'ROUTE_NE_ID': 'R1', 'START_TRUE_DIST': 5}, bad).status, MatchStatus.unmatched);
    });
  });

  group('matchConditionRecord', () {
    final segs = [
      _seg(0, td0: 0, td1: 5, slk0: 0, slk1: 5),
      _seg(1, td0: 5, td1: 10, slk0: 5, slk1: 10),
      _seg(2, road: 'H002', td0: 0, td1: 10),
    ];

    test('single overlap is confirmed', () {
      final m = matchConditionRecord(
          {'ROAD': 'H001', 'START_TRUE_DIST': 1, 'END_TRUE_DIST': 4, 'START_SLK': 1, 'END_SLK': 4}, segs);
      expect(m.result.status, MatchStatus.confirmed);
      expect(m.evidenceDisagrees, isFalse);
    });

    test('spanning record is ambiguous', () {
      final m = matchConditionRecord({'ROAD': 'H001', 'START_TRUE_DIST': 1, 'END_TRUE_DIST': 9}, segs);
      expect(m.result.status, MatchStatus.ambiguous);
      expect(m.result.candidates, [0, 1]);
    });

    test('unknown road, null road and reversed range are unmatched', () {
      expect(matchConditionRecord({'ROAD': 'ZZ', 'START_TRUE_DIST': 1, 'END_TRUE_DIST': 2}, segs).result.status,
          MatchStatus.unmatched);
      expect(matchConditionRecord({'ROAD': null}, segs).result.basis, 'missingRoad');
      final rev = matchConditionRecord({'ROAD': 'H001', 'START_TRUE_DIST': 9, 'END_TRUE_DIST': 1}, segs);
      expect(rev.result.status, MatchStatus.unmatched);
    });

    test('true-distance and SLK disagreement is flagged', () {
      final m = matchConditionRecord(
          {'ROAD': 'H001', 'START_TRUE_DIST': 1, 'END_TRUE_DIST': 4, 'START_SLK': 6, 'END_SLK': 9}, segs);
      expect(m.result.candidates, [0]);
      expect(m.slkCandidates, [1]);
      expect(m.evidenceDisagrees, isTrue);
    });
  });

  group('stats', () {
    test('range stats and duplicates ignore nulls', () {
      final rows = [
        {'S': 1, 'E': 2, 'G': 'a'},
        {'S': 3, 'E': 3, 'G': 'A'},
        {'S': 5, 'E': 1, 'G': null},
        {'S': null, 'E': 1, 'G': ''},
      ];
      final r = rangeStats(rows, 'S', 'E');
      expect([r.valid, r.zeroLength, r.reversed, r.missing], [2, 1, 1, 1]);
      final d = duplicateStat(rows, 'G');
      expect([d.distinctValuesDuplicated, d.recordsInDuplicateGroups], [1, 2]);
      expect(fieldStats(rows, ['G'])['G']!.populated, 2);
    });

    test('MAX_NETWORK evidence never reports an established rule', () {
      final e = MaxNetworkEvidence(2)
        ..add({'ROAD': 'H001', 'START_TRUE_DIST': 0, 'END_TRUE_DIST': 4},
            [Segment.fromAttrs(0, {'ROAD': 'H001', 'START_TRUE_DIST': 0, 'END_TRUE_DIST': 5, 'MAX_NETWORK': 3})]);
      expect(e.verdict, startsWith('insufficient'));
      final c = MaxNetworkEvidence(2)
        ..add({'ROAD': 'H001', 'START_TRUE_DIST': 0, 'END_TRUE_DIST': 4},
            [Segment.fromAttrs(0, {'ROAD': 'H001', 'START_TRUE_DIST': 0, 'END_TRUE_DIST': 5, 'MAX_NETWORK': 1})]);
      expect(c.verdict, startsWith('contradicts'));
    });
  });

  group('fetchAllAttributes', () {
    test('paginates with resultOffset until transfer limit clears', () async {
      final a = _Adapter((o) {
        if (!o.uri.path.endsWith('/query')) return _body({'name': 'L', 'maxRecordCount': 2});
        final off = int.parse(o.uri.queryParameters['resultOffset']!);
        final feats = [for (var i = off; i < (off + 2).clamp(0, 5); i++) _feat(i)];
        return _body({'features': feats, if (off + 2 < 5) 'exceededTransferLimit': true});
      });
      final d = await fetchAllAttributes(_dio(a), 7, delay: Duration.zero);
      expect(d.rows.length, 5);
      expect(d.complete, isTrue);
      expect(d.pages, 3);
      final q = a.requests.where((u) => u.path.endsWith('/query')).first.queryParameters;
      expect(q['where'], '1=1');
      expect(q['outFields'], '*');
      expect(q['returnGeometry'], 'false');
      expect(q['resultRecordCount'], '2');
      expect(a.requests.first.toString(), startsWith(investigationBaseUrl));
    });

    test('successful empty result is valid and complete', () async {
      final a = _Adapter((o) => o.uri.path.endsWith('/query') ? _body({'features': []}) : _body({'name': 'L'}));
      final d = await fetchAllAttributes(_dio(a), 7, delay: Duration.zero);
      expect(d.rows, isEmpty);
      expect(d.complete, isTrue);
    });

    test('hitting maxPages marks result incomplete', () async {
      final a = _Adapter((o) => o.uri.path.endsWith('/query')
          ? _body({'features': [_feat(1)], 'exceededTransferLimit': true})
          : _body({'name': 'L'}));
      final d = await fetchAllAttributes(_dio(a), 7, maxPages: 2, delay: Duration.zero);
      expect(d.complete, isFalse);
      expect(d.incompleteReason, isNotNull);
    });

    test('malformed, ArcGIS error and HTTP failures throw', () async {
      Future<void> expectFails(ResponseBody Function(RequestOptions) h) => expectLater(
          fetchAllAttributes(_dio(_Adapter(h)), 7, delay: Duration.zero), throwsA(isA<ProbeException>()));

      await expectFails((o) => _body('not json'));
      await expectFails((o) => _body({'error': {'code': 400, 'message': 'bad'}}));
      await expectFails((o) => o.uri.path.endsWith('/query') ? _body({'nofeatures': 1}) : _body({'name': 'L'}));
      await expectFails((o) => o.uri.path.endsWith('/query') ? _body({'features': [1]}) : _body({'name': 'L'}));
      await expectFails((o) => _body({}, 500));
    });
  });

  group('buildSummary', () {
    test('failed layer yields no stats and marks run unsuccessful', () {
      final s = buildSummary(layers: {}, failures: {78: 'boom'}, sampleLimit: 2, generatedAt: 't');
      expect(s['allLayersCompleteAndSuccessful'], isFalse);
      expect(s['layer78'], isNull);
      expect((s['failedLayers'] as Map)['78'], 'boom');
    });

    test('truncates long sample text', () {
      final m = sample({'CONDITION': 'x' * 500}, ['CONDITION']);
      expect((m['CONDITION'] as String).length, lessThan(200));
    });
  });
}
