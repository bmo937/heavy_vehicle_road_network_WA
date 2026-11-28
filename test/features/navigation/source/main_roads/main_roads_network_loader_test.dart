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
}) {
  final sourceMetadata = metadata ??
      _metadata(maxRecordCount: servicePageSize);
  var pageIndex = 0;
  adapter.handler = (options) {
    final query = options.uri.queryParameters;
    if (options.uri.path.endsWith('/78')) return _json(sourceMetadata);
    if (query['returnCountOnly'] == 'true') return _json({'count': count});
    if (invalidPage != null) return _json(invalidPage);
    if (pages != null) return _json(pages[pageIndex++]);
    return _json(_page([]));
  };
  return MainRoadsNetworkLoader(
    client: MainRoadsNetworkClient(
      dio: _dio(adapter),
      serviceUrl: 'https://example.com/MapServer',
    ),
    parser: parser,
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
          spatialReference: {'wkid': 4283, 'latestWkid': 7844},
        ),
        pages: [
          _page([_feature('g1')]),
        ],
      );

      final result = await loader.load();

      expect(result.sourceContract.sourceWkid, 4283);
      expect(result.sourceContract.sourceLatestWkid, 7844);
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
      for (final reference in [null, {'wkid': 9999}]) {
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

    test('includes and records optional datum transformation on every page',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final loader = _loader(
        adapter,
        count: 2,
        pageSize: 1,
        datumTransformation: '{"wkid":1234}',
        pages: [
          _page([_feature('g1')], exceededTransferLimit: true),
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
      expect(queries.every((query) => query['orderByFields'] == 'OBJECTID'),
          isTrue);
      expect(queries.every((query) => query['outFields'] == '*'), isTrue);
      expect(queries.every((query) => query['returnGeometry'] == 'true'), isTrue);
    });

    test('uses the service count to continue when a page omits the limit flag',
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

    test('count mismatch is a retrieval failure and parser is not called',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final parser = _TrackingParser();
      final loader = _loader(
        adapter,
        count: 2,
        parser: parser,
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

    test('maxPages exhaustion is a retrieval failure and parser is not called',
        () async {
      final adapter = _Adapter((_) => _json({}));
      final parser = _TrackingParser();
      final loader = _loader(
        adapter,
        count: 3,
        maxPages: 1,
        parser: parser,
        pages: [
          _page([_feature('g1')], exceededTransferLimit: true),
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
          _page([_feature('duplicate')], exceededTransferLimit: true),
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
