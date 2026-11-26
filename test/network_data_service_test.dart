import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/providers/network_data_service.dart';

class _FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  RequestOptions? last;
  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    last = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_FakeAdapter a) => Dio()..httpClientAdapter = a;

ResponseBody _json(String body, [int status = 200]) => ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

final _bounds = LatLngBounds(southwest: const LatLng(-32.0, 115.5), northeast: const LatLng(-31.5, 116.0));

void main() {
  group('constructUrlWithBounds', () {
    test('builds ArcGIS query with expected parameters', () {
      final uri = Uri.parse(constructUrlWithBounds('https://example.com/MapServer/3/', '115.5,-32.0,116.0,-31.5'));
      expect(uri.path, '/MapServer/3/query');
      expect(uri.queryParameters, {
        'where': '1=1',
        'geometry': '115.5,-32.0,116.0,-31.5',
        'geometryType': 'esriGeometryEnvelope',
        'inSR': '4326',
        'spatialRel': 'esriSpatialRelIntersects',
        'outFields': '*',
        'returnGeometry': 'true',
        'geometryPrecision': '6',
        'outSR': '4326',
        'f': 'geojson',
      });
    });

    test('replaces geometry in existing query, preserving other params', () {
      final uri = Uri.parse(constructUrlWithBounds('https://example.com/q?where=1%3D1&geometry=1,2,3,4&f=pgeojson', '9,8,7,6'));
      expect(uri.queryParameters['geometry'], '9,8,7,6');
      expect(uri.queryParameters['f'], 'pgeojson');
      expect(uri.queryParameters['where'], '1=1');
    });

    test('adds geometry params to existing query lacking geometry', () {
      final uri = Uri.parse(constructUrlWithBounds('https://example.com/q?f=geojson', '1,2,3,4'));
      expect(uri.queryParameters['geometry'], '1,2,3,4');
      expect(uri.queryParameters['geometryType'], 'esriGeometryEnvelope');
      expect(uri.queryParameters['inSR'], '4326');
      expect(uri.queryParameters['f'], 'geojson');
    });

    test('empty base URL returns empty string', () {
      expect(constructUrlWithBounds('', '1,2,3,4'), '');
    });
  });

  group('fetchOnlineLayerData', () {
    test('uses minLng,minLat,maxLng,maxLat ordering', () async {
      final adapter = _FakeAdapter((_) async => _json('{"type":"FeatureCollection","features":[]}'));
      await fetchOnlineLayerData(5, _bounds, dio: _dioWith(adapter));
      expect(adapter.last!.uri.queryParameters['geometry'], '115.5,-32.0,116.0,-31.5');
    });

    test('returns features on success', () async {
      final body = jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {'type': 'Feature'}
        ]
      });
      final result = await fetchOnlineLayerData(5, _bounds, dio: _dioWith(_FakeAdapter((_) async => _json(body))));
      expect(result['features'], hasLength(1));
    });

    test('legitimate empty response is a successful empty collection', () async {
      final result = await fetchOnlineLayerData(5, _bounds, dio: _dioWith(_FakeAdapter((_) async => _json('{"type":"FeatureCollection","features":[]}'))));
      expect(result['type'], 'FeatureCollection');
      expect(result['features'], isEmpty);
    });

    test('request failure throws rather than returning empty data', () async {
      final dio = _dioWith(_FakeAdapter((o) async => throw DioException.connectionTimeout(timeout: const Duration(seconds: 1), requestOptions: o)));
      expect(
        fetchOnlineLayerData(5, _bounds, dio: dio),
        throwsA(isA<NetworkDataException>().having((e) => e.failureType, 'type', DioExceptionType.connectionTimeout)),
      );
    });

    test('HTTP error status throws with status code', () async {
      final dio = _dioWith(_FakeAdapter((_) async => _json('{}', 500)));
      expect(
        fetchOnlineLayerData(5, _bounds, dio: dio),
        throwsA(isA<NetworkDataException>().having((e) => e.statusCode, 'status', 500)),
      );
    });

    test('malformed body throws', () async {
      final dio = _dioWith(_FakeAdapter((_) async => ResponseBody.fromString('not json', 200)));
      expect(fetchOnlineLayerData(5, _bounds, dio: dio), throwsA(isA<NetworkDataException>()));
    });

    test('JSON without features list throws', () async {
      final dio = _dioWith(_FakeAdapter((_) async => _json('{"error":{"code":400}}')));
      expect(fetchOnlineLayerData(5, _bounds, dio: dio), throwsA(isA<NetworkDataException>()));
    });
  });
}
