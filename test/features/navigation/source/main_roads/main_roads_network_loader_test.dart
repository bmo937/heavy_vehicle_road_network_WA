import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_client.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_loader.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_parser.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_segment.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  ResponseBody Function(RequestOptions) handler;
  final List<Uri> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object value, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(value), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

ResponseBody _raw(String value, [int status = 200]) =>
    ResponseBody.fromString(value, status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

Map<String, dynamic> _metadata({
  Object? spatialReference = const {'wkid': 4283},
  int id = 78,
  String name = mainRoadsNetworkLayerName,
  String geometryType = 'esriGeometryPolyline',
  int maxRecordCount = 1000,
}) =>
    {
      'id': id,
      'name': name,
      'geometryType': geometryType,
      'maxRecordCount': maxRecordCount,
      'extent': {
        if (spatialReference != null) 'spatialReference': spatialReference,
      },
    };

Map<String, dynamic> _feature(String globalId, {int objectId = 1}) => {
      'type': 'Feature',
      'properties': {
        'GlobalID': globalId,
        'OBJECTID': objectId,
        'ROAD': 'H001',
        'ROAD_NAME': 'Test Road',
        'ROUTE_NE_ID': 123,
        'START_SLK': 0.0,
        'END_SLK': 1.0,
        'START_TRUE_DIST': 0.0,
        'END_TRUE_DIST': 1.0,
        'NETWORK_TYPE': 'State Road',
        'NETWORK_CATEGORY': 'Network 1',
        'MAX_NETWORK': 1,
      },
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [115.0, -32.0],
          [115.1, -32.1],
        ],
      },
    };

Map<String, dynamic> _page(
  List<Object?> features, {
  bool exceededTransferLimit = false,
}) =>
    {
      'type': 'FeatureCollection',
      'features': features,
      if (exceededTransferLimit)
        'exceededTransferLimit': exceededTransferLimit,
    };

class _TrackingParser extends MainRoadsNetworkParser {
  bool called = false;

  @override
  List<MainRoadsNetworkSegment> parseFeatureCollection(
    Map<String, dynamic> json,
  ) {
    called = true;
    return super.parseFeatureCollection(json);
  }
}

Dio _dio(_Adapter adapter) =>
    Dio(BaseOptions(responseType: ResponseType.plain))
      ..httpClientAdapter = adapter;

MainRoadsNetworkLoader _loader(
  _Adapter adapter, {
  int count = 1,
  int maxPages = 200,
  int pageSize = 1000,
  String? datumTransformation,
  MainRoadsNetworkParser parser = const MainRoadsNetworkParser(),
  Map<String, dynamic>? metadata,
  List<Map<String, dynamic>>? pages,
  Object? invalidPage,
  int servicePageSize = 1000,
  List<int>? objectIds,
  List<List<int>>? objectIdResponses,
  ResponseBody? Function(RequestOptions)? responseOverride,
  Set<int> acceptedSourceWkids = const {4283, 7844},
  Map<int, Set<int>> equivalentSourceWkidAliases = const {
    102100: {3857},
    3857: {102100},
  },
}) {
  final sourceMetadata = metadata ??
      _metadata(maxRecordCount: servicePageSize);
  var pageIndex = 0;
  var objectIdResponseIndex = 0;
  adapter.handler = (options) {
    final override = responseOverride?.call(options);
    if (override != null) return override;
    final query = options.uri.queryParameters;
    if (options.uri.path.endsWith('/78')) return _json(sourceMetadata);
    if (query['returnCountOnly'] == 'true') return _json({'count': count});
    if (query['returnIdsOnly'] == 'true') {
      final List<int> ids;
      if (objectIdResponses != null) {
        ids = objectIdResponses[objectIdResponseIndex++];
      } else if (objectIds != null) {
        ids = objectIds;
      } else if (pages == null) {
        ids = List<int>.generate(count, (index) => index + 1);
      } else {
        ids = pages
            .expand((page) => page['features'] as List)
            .map((feature) =>
                (feature as Map)['properties']['OBJECTID'] as int)
            .toSet()
            .toList()
          ..sort();
      }
      return _json({'objectIds': ids});
    }
    if (invalidPage != null) return _json(invalidPage);
    if (pages != null) {
      return _json(pageIndex < pages.length ? pages[pageIndex++] : _page([]));
    }
    return _json(_page([]));
  };
  return MainRoadsNetworkLoader(
    client: MainRoadsNetworkClient(
      dio: _dio(adapter),
      serviceUrl: 'https://example.com/MapServer',
    ),
    parser: parser,
    acceptedSourceWkids: acceptedSourceWkids,
    equivalentSourceWkidAliases: equivalentSourceWkidAliases,
    maxPages: maxPages,
    pageSize: pageSize,
    datumTransformation: datumTransformation,
    interPageDelay: Duration.zero,
  );
}

void main() {
  group('MainRoadsNetworkLoader', () {
    test('accepts EPSG:4283 and records source/output contract', () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        pages: [
          _page([_feature('g1')]),
        ],
      );

      final result = await loader.load();

      expect(result.segments, hasLength(1));
      expect(result.pageCount, 1);
      expect(result.expectedFeatureCount, 1);
      expect(result.retrievedFeatureCount, 1);
      expect(result.sourceContract.sourceWkid, 4283);
      expect(result.sourceContract.sourceLatestWkid, isNull);
      expect(result.sourceContract.requestedOutputWkid, 4326);
      expect(result.sourceContract.datumTransformationRequested, isFalse);
      expect(result.sourceContract.retrievedAt.isUtc, isTrue);
      expect(
        adapter.requests
            .singleWhere((uri) => uri.queryParameters['f'] == 'geojson')
            .queryParameters,
        containsPair('outSR', '4326'),
      );
      expect(
        () => result.segments.add(result.segments.single),
        throwsUnsupportedError,
      );
    });

    test('accepts EPSG:7844 as the source WKID', () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        metadata: _metadata(
          spatialReference: {'wkid': 7844},
        ),
        pages: [
          _page([_feature('g1')]),
        ],
      );

      final result = await loader.load();

      expect(result.sourceContract.sourceWkid, 7844);
    });

    test('retains the source wkid and latestWkid when both are supplied',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        metadata: _metadata(
          spatialReference: {'wkid': 4283, 'latestWkid': 4283},
        ),
        pages: [
          _page([_feature('g1')]),
        ],
      );

      final result = await loader.load();

      expect(result.sourceContract.sourceWkid, 4283);
      expect(result.sourceContract.sourceLatestWkid, 4283);
    });

    test('accepts configured equivalent WKID aliases and retains both IDs',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        acceptedSourceWkids: {102100, 3857},
        metadata: _metadata(
          spatialReference: {'wkid': 102100, 'latestWkid': 3857},
        ),
        pages: [_page([_feature('g1')])],
      );

      final result = await loader.load();

      expect(result.sourceContract.sourceWkid, 102100);
      expect(result.sourceContract.sourceLatestWkid, 3857);
    });

    test('aliases do not bypass the accepted source WKID allowlist', () async {
      final adapter = _Adapter((_) => _json({}));
      final parser = _TrackingParser();
      final loader = _loader(
        adapter,
        parser: parser,
        acceptedSourceWkids: {102100},
        metadata: _metadata(
          spatialReference: {'wkid': 102100, 'latestWkid': 3857},
        ),
      );

      await expectLater(
        loader.load(),
        throwsA(
          isA<MainRoadsNetworkCrsException>()
              .having((error) => error.context, 'context', 'layer metadata')
              .having(
                (error) => error.message,
                'message',
                'unsupported source WKIDs',
              ),
        ),
      );
      expect(parser.called, isFalse);
      expect(
        adapter.requests.any((uri) => uri.queryParameters['f'] == 'geojson'),
        isFalse,
      );
    });

    test('supports explicitly configured equivalent WKID aliases', () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        acceptedSourceWkids: {900001, 900002},
        equivalentSourceWkidAliases: const {
          900001: {900002},
        },
        metadata: _metadata(
          spatialReference: {'wkid': 900001, 'latestWkid': 900002},
        ),
        pages: [_page([_feature('g1')])],
      );

      final result = await loader.load();

      expect(result.sourceContract.sourceWkid, 900001);
      expect(result.sourceContract.sourceLatestWkid, 900002);
    });

    test('reads a latestWkid-only source reference', () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        metadata: _metadata(spatialReference: {'latestWkid': 7844}),
        pages: [
          _page([_feature('g1')]),
        ],
      );

      final result = await loader.load();

      expect(result.sourceContract.sourceWkid, 7844);
      expect(result.sourceContract.sourceLatestWkid, 7844);
    });

    test('rejects missing and unknown source WKIDs before querying features',
        () async {
      for (final reference in [
        null,
        {'wkid': 9999},
        {'wkid': 9999, 'latestWkid': 7844},
        {'wkid': 4283, 'latestWkid': 9999},
        {'wkid': 4283, 'latestWkid': 7844},
        {'wkid': 7844, 'latestWkid': 4283},
      ]) {
        final adapter = _Adapter((_) => _json({}));
        final loader = _loader(
          adapter,
          metadata: _metadata(spatialReference: reference),
        );

        await expectLater(
          loader.load(),
          throwsA(isA<MainRoadsNetworkCrsException>()),
        );
        expect(
          adapter.requests.any((uri) => uri.queryParameters['f'] == 'geojson'),
          isFalse,
        );
      }
    });

    test('rejects unsupported output WKID before retrieval', () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = MainRoadsNetworkLoader(
        client: MainRoadsNetworkClient(
          dio: _dio(adapter),
          serviceUrl: 'https://example.com/MapServer',
        ),
        requestedOutputWkid: 7844,
      );

      await expectLater(loader.load(), throwsArgumentError);
      expect(adapter.requests, isEmpty);
    });

    test('includes and records optional datum transformation on every page',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        count: 2,
        pageSize: 1,
        datumTransformation: '{"wkid":1234}',
        pages: [
          _page([_feature('g1')]),
          _page([_feature('g2', objectId: 2)]),
        ],
      );

      final result = await loader.load();
      final geometryQueries = adapter.requests
          .map((uri) => uri.queryParameters)
          .where((query) => query['f'] == 'geojson')
          .toList();

      expect(geometryQueries, hasLength(2));
      expect(
        geometryQueries.map((query) => query['datumTransformation']),
        everyElement('{"wkid":1234}'),
      );
      expect(result.sourceContract.datumTransformationRequested, isTrue);
      expect(result.sourceContract.datumTransformation, '{"wkid":1234}');
    });

    test('paginates completely and caps page size at service maxRecordCount',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        count: 3,
        pageSize: 10,
        servicePageSize: 2,
        pages: [
          _page([
            _feature('g1'),
            _feature('g2', objectId: 2),
          ], exceededTransferLimit: true),
          _page([_feature('g3', objectId: 3)]),
        ],
      );

      final result = await loader.load();
      final queries = adapter.requests
          .map((uri) => uri.queryParameters)
          .where((query) => query['f'] == 'geojson')
          .toList();

      expect(result.segments.map((segment) => segment.globalId),
          ['g1', 'g2', 'g3']);
      expect(result.pageCount, 2);
      expect(queries.map((query) => query['resultRecordCount']), ['2', '2']);
      expect(queries.map((query) => query['resultOffset']), ['0', '2']);
      expect(queries.every((query) => !query.containsKey('objectIds')), isTrue);
      expect(queries.every((query) => query['orderByFields'] == 'OBJECTID'),
          isTrue);
      expect(queries.every((query) => query['outFields'] == '*'), isTrue);
      expect(queries.every((query) => query['returnGeometry'] == 'true'), isTrue);
    });

    test('retrieves offset pages when limit flag is absent',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        count: 2,
        pageSize: 1,
        pages: [
          _page([_feature('g1')]),
          _page([_feature('g2', objectId: 2)]),
        ],
      );

      final result = await loader.load();

      expect(result.segments.map((segment) => segment.globalId), ['g1', 'g2']);
      expect(result.pageCount, 2);
    });

    test('validates each page CRS before parsing', () async {
      for (final name in [
        'EPSG:4326',
        'urn:ogc:def:crs:EPSG::4326',
        'urn:ogc:def:crs:OGC:1.3:CRS84',
        'OGC:CRS84',
        'CRS84',
      ]) {
        final adapter = _Adapter((_) => _json({}));
        final loader = _loader(adapter, pages: [
          {
            ..._page([_feature('g1')]),
            'crs': {'type': 'name', 'properties': {'name': name}},
          },
        ]);
        expect((await loader.load()).segments, hasLength(1), reason: name);
      }

      for (final crs in [
        null,
        'EPSG:4326',
        {},
        {'type': 'name', 'properties': {'name': 'EPSG:7844'}},
        {'type': 'name', 'properties': {'name': 4326}},
        {'type': 'link', 'properties': {'name': 'EPSG:4326'}},
      ]) {
        final adapter = _Adapter((_) => _json({}));
        final parser = _TrackingParser();
        final loader = _loader(
          adapter,
          count: 2,
          pageSize: 1,
          parser: parser,
          pages: [
            _page([_feature('g1')]),
            {..._page([_feature('g2', objectId: 2)]), 'crs': crs},
          ],
        );
        await expectLater(
          loader.load(),
          throwsA(isA<MainRoadsNetworkCrsException>()
              .having((error) => error.context, 'context', 'feature page 2')),
          reason: '$crs',
        );
        expect(parser.called, isFalse);
      }
    });

    test('rejects unusable explicit source CRS instead of falling back',
        () async {
      for (final reference in [null, {}, {'wkt': 'WKT'}, 'invalid']) {
        final adapter = _Adapter((_) => _json({}));
        final parser = _TrackingParser();
        final loader = _loader(
          adapter,
          parser: parser,
          metadata: {..._metadata(), 'sourceSpatialReference': reference},
        );
        await expectLater(loader.load(), throwsA(isA<MainRoadsNetworkCrsException>()));
        expect(parser.called, isFalse);
        expect(adapter.requests, hasLength(1));
      }
    });

    test('revalidates the source CRS after fetching geometry', () async {
      for (final reference in [
        {'wkid': 7844},
        null,
        {'wkid': 4283, 'latestWkid': 7844},
        {'wkid': '4283'},
        {'wkid': 9999},
      ]) {
        final adapter = _Adapter((_) => _json({}));
        final parser = _TrackingParser();
        var metadataRequests = 0;
        final loader = _loader(
          adapter,
          parser: parser,
          pages: [_page([_feature('g1')])],
          responseOverride: (options) {
            if (options.uri.path.endsWith('/78') && ++metadataRequests == 2) {
              return _json(_metadata(spatialReference: reference));
            }
            return null;
          },
        );
        await expectLater(
          loader.load(),
          throwsA(isA<MainRoadsNetworkCrsException>().having(
            (error) => error.context,
            'context',
            'layer metadata verification',
          )),
          reason: '$reference',
        );
        expect(parser.called, isFalse);
      }
    });

    test('count mismatch is a retrieval failure and parser is not called',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final parser = _TrackingParser();
      final loader = _loader(
        adapter,
        count: 2,
        pageSize: 1,
        parser: parser,
        objectIds: [1, 2],
        pages: [
          _page([_feature('g1')]),
          _page([]),
        ],
      );

      await expectLater(
        loader.load(),
        throwsA(
          isA<MainRoadsNetworkRetrievalException>()
              .having((error) => error.context, 'context', 'feature pagination')
              .having(
                (error) => error.message,
                'message',
                'retrieved 1 features, expected 2',
              ),
        ),
      );
      expect(parser.called, isFalse);
    });

    test('maxPages exhaustion is a retrieval failure and parser is not called',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final parser = _TrackingParser();
      final loader = _loader(
        adapter,
        count: 3,
        maxPages: 1,
        pageSize: 1,
        parser: parser,
        objectIds: [1, 2, 3],
        pages: [
          _page([_feature('g1')]),
        ],
      );

      await expectLater(
        loader.load(),
        throwsA(isA<MainRoadsNetworkRetrievalException>()),
      );
      expect(parser.called, isFalse);
    });

    test('rejects invalid layer identity, geometry type and metadata', () async {
      for (final metadata in [
        _metadata(id: 77),
        _metadata(name: 'Other layer'),
        _metadata(geometryType: 'esriGeometryPolygon'),
        {
          ..._metadata(),
          'maxRecordCount': null,
        },
      ]) {
        final adapter = _Adapter((_) => _json({}));
        final loader = _loader(adapter, metadata: metadata);
        await expectLater(
          loader.load(),
          throwsA(isA<MainRoadsNetworkRetrievalException>()),
        );
      }
    });

    test('rejects malformed GeoJSON pages and ArcGIS error payloads', () async {
      final malformedAdapter = _Adapter((_) => _json({}));
      final malformedLoader = _loader(
        malformedAdapter,
        invalidPage: {'type': 'FeatureCollection', 'features': 'invalid'},
      );
      await expectLater(
        malformedLoader.load(),
        throwsA(isA<MainRoadsNetworkRetrievalException>()),
      );

      final errorAdapter = _Adapter((_) => _json({}));
      final errorLoader = _loader(
        errorAdapter,
        metadata: {
          'error': {'code': 400, 'message': 'invalid layer'},
        },
      );
      await expectLater(
        errorLoader.load(),
        throwsA(isA<MainRoadsNetworkRetrievalException>()),
      );
    });

    test('rejects empty pages while exceededTransferLimit is true', () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        count: 1,
        pages: [
          _page([], exceededTransferLimit: true),
        ],
      );

      await expectLater(
        loader.load(),
        throwsA(isA<MainRoadsNetworkRetrievalException>()),
      );
    });

    test('fetches a geometry page when the reported and ID counts are zero',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(adapter, count: 0, pages: [_page([])]);

      final result = await loader.load();

      expect(result.segments, isEmpty);
      expect(result.pageCount, 1);
      expect(
        adapter.requests.where((uri) => uri.queryParameters['f'] == 'geojson'),
        hasLength(1),
      );
    });

    test('checks for features even when the reported count is zero', () async {
      final adapter = _Adapter((_) => _json({}));
      final parser = _TrackingParser();
      final loader = _loader(
        adapter,
        count: 0,
        parser: parser,
        objectIds: [1],
        pages: [
          _page([_feature('g1')]),
        ],
      );

      await expectLater(
        loader.load(),
        throwsA(
          isA<MainRoadsNetworkRetrievalException>()
              .having((error) => error.context, 'context', 'feature pagination')
              .having(
                (error) => error.message,
                'message',
                'retrieved 1 features, expected 0',
              ),
        ),
      );
      expect(parser.called, isFalse);
      expect(
        adapter.requests.where((uri) => uri.queryParameters['f'] == 'geojson'),
        hasLength(1),
      );
    });

    test('detects an OBJECTID set changing during geometry retrieval', () async {
      final adapter = _Adapter((_) => _json({}));
      final parser = _TrackingParser();
      final loader = _loader(
        adapter,
        count: 2,
        pageSize: 1,
        parser: parser,
        objectIds: [1, 2],
        objectIdResponses: [
          [1, 2],
          [1, 3],
        ],
        pages: [
          _page([_feature('g1')]),
          _page([_feature('g2', objectId: 2)]),
        ],
      );

      await expectLater(
        loader.load(),
        throwsA(
          isA<MainRoadsNetworkRetrievalException>()
              .having((error) => error.context, 'context', 'feature pagination')
              .having(
                (error) => error.message,
                'message',
                'OBJECTID set changed during retrieval',
              ),
        ),
      );
      expect(parser.called, isFalse);
    });

    test('rejects malformed transfer-limit flags', () async {
      for (final page in [
        {
          ..._page([_feature('g1')]),
          'exceededTransferLimit': 'true',
        },
        {
          ..._page([_feature('g1')]),
          'properties': {'exceededTransferLimit': 'false'},
        },
      ]) {
        final adapter = _Adapter((_) => _json({}));
        final parser = _TrackingParser();
        final loader = _loader(
          adapter,
          parser: parser,
          pages: [page],
        );

        await expectLater(
          loader.load(),
          throwsA(
            isA<MainRoadsNetworkRetrievalException>()
                .having((error) => error.context, 'context', 'feature page 1')
                .having(
                  (error) => error.message,
                  'message',
                  'exceededTransferLimit must be a boolean when supplied',
                ),
          ),
        );
        expect(parser.called, isFalse);
      }
    });

    test('reports structured errors for failed or malformed retrievals', () async {
      final cases = <String, ResponseBody? Function(RequestOptions)>{
        'non-200': (options) => options.uri.queryParameters['returnCountOnly'] == 'true'
            ? _json({'error': 'unavailable'}, 503)
            : null,
        'invalid JSON': (options) =>
            options.uri.path.endsWith('/78') ? _raw('{') : null,
        'non-object body': (options) =>
            options.uri.path.endsWith('/78') ? _raw('[]') : null,
        'malformed count': (options) =>
            options.uri.queryParameters['returnCountOnly'] == 'true'
                ? _json({'count': 'one'})
                : null,
        'page ArcGIS error': (options) =>
            options.uri.queryParameters['f'] == 'geojson'
                ? _json({'error': {'code': 400, 'message': 'bad query'}})
                : null,
      };

      for (final entry in cases.entries) {
        final adapter = _Adapter((_) => _json({}));
        final parser = _TrackingParser();
        final loader = _loader(
          adapter,
          parser: parser,
          responseOverride: entry.value,
        );
        final expectedContext = switch (entry.key) {
          'non-200' || 'malformed count' => 'feature count',
          'page ArcGIS error' => 'feature page 1',
          _ => 'layer metadata',
        };
        final expectedStatusCode = switch (entry.key) {
          'non-200' => 503,
          _ => 200,
        };
        final expectedMessage = switch (entry.key) {
          'non-200' => 'unexpected HTTP status',
          'invalid JSON' => startsWith('malformed JSON response:'),
          'non-object body' => 'response must be a JSON object',
          'malformed count' =>
            'ArcGIS did not return a non-negative integer count',
          'page ArcGIS error' => 'ArcGIS returned an error: bad query',
          _ => fail('Unexpected retrieval failure test case: ${entry.key}'),
        };

        await expectLater(
          loader.load(),
          throwsA(
            isA<MainRoadsNetworkRetrievalException>()
                .having((error) => error.context, 'context', expectedContext)
                .having(
                  (error) => error.statusCode,
                  'statusCode',
                  expectedStatusCode,
                )
                .having(
                  (error) => error.message,
                  'message',
                  expectedMessage,
                ),
          ),
          reason: entry.key,
        );
        expect(parser.called, isFalse, reason: entry.key);
      }
    });

    test('reports Dio failure type and retrieval context', () async {
      final adapter = _Adapter((_) => _json({}));
      final parser = _TrackingParser();
      final loader = _loader(
        adapter,
        parser: parser,
        responseOverride: (options) {
          if (options.uri.queryParameters['returnCountOnly'] == 'true') {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
            );
          }
          return null;
        },
      );

      await expectLater(
        loader.load(),
        throwsA(
          isA<MainRoadsNetworkRetrievalException>()
              .having((error) => error.context, 'context', 'feature count')
              .having((error) => error.message, 'message', 'request failed')
              .having((error) => error.statusCode, 'statusCode', isNull)
              .having(
                (error) => error.failureType,
                'failureType',
                DioExceptionType.connectionTimeout,
              ),
        ),
      );
      expect(parser.called, isFalse);
    });

    test('rejects a transfer-limit flag after the reported count is reached',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        count: 1,
        pages: [
          _page([_feature('g1')], exceededTransferLimit: true),
        ],
      );

      await expectLater(
        loader.load(),
        throwsA(isA<MainRoadsNetworkRetrievalException>()),
      );
    });

    test('duplicate GlobalIDs across pages fail in the production parser',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        count: 2,
        pageSize: 1,
        pages: [
          _page([_feature('duplicate')]),
          _page([_feature('duplicate', objectId: 2)]),
        ],
      );

      await expectLater(
        loader.load(),
        throwsA(isA<MainRoadsNetworkParseException>()),
      );
    });
  });
}
