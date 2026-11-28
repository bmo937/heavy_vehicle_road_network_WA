import 'main_roads_network_client.dart';
import 'main_roads_network_load_result.dart';
import 'main_roads_network_parser.dart';
import 'main_roads_network_segment.dart';

const int _defaultOutputWkid = 4326;
const int _defaultPageSize = 1000;
const int _defaultMaxPages = 200;

/// Retrieves and parses all features in Main Roads WA layer 78.
///
/// The parser consumes GeoJSON longitude/latitude coordinates. Source CRS is
/// validated from layer metadata, while every geometry page requests
/// [requestedOutputWkid] explicitly.
class MainRoadsNetworkLoader {
  MainRoadsNetworkLoader({
    required this.client,
    this.parser = const MainRoadsNetworkParser(),
    Set<int> acceptedSourceWkids = const {4283, 7844},
    this.requestedOutputWkid = _defaultOutputWkid,
    this.pageSize = _defaultPageSize,
    this.maxPages = _defaultMaxPages,
    this.interPageDelay = const Duration(milliseconds: 250),
    this.datumTransformation,
  }) : acceptedSourceWkids = Set.unmodifiable(acceptedSourceWkids);

  final MainRoadsNetworkClient client;
  final MainRoadsNetworkParser parser;
  final Set<int> acceptedSourceWkids;
  final int requestedOutputWkid;
  final int pageSize;
  final int maxPages;
  final Duration interPageDelay;
  final String? datumTransformation;

  Future<MainRoadsNetworkLoadResult> load() async {
    if (requestedOutputWkid <= 0 || pageSize <= 0 || maxPages <= 0) {
      throw ArgumentError(
        'requestedOutputWkid, pageSize, and maxPages must be positive',
      );
    }

    final metadata = await client.getJson(
      client.layerUri(mainRoadsNetworkLayerId, query: const {'f': 'json'}),
      context: 'layer metadata',
    );
    _validateLayerMetadata(metadata);
    final reference = _sourceReference(metadata);
    final sourceWkid = reference.wkid ?? reference.latestWkid;
    if (sourceWkid == null) {
      throw const MainRoadsNetworkCrsException(
        'layer metadata',
        'source WKID is missing',
      );
    }
    if (!acceptedSourceWkids.contains(sourceWkid) &&
        (reference.latestWkid == null ||
            !acceptedSourceWkids.contains(reference.latestWkid))) {
      throw MainRoadsNetworkCrsException(
        'layer metadata',
        'unsupported source WKID $sourceWkid'
            '${reference.latestWkid == null ? '' : ' (latestWkid ${reference.latestWkid})'}',
        sourceWkid: reference.wkid,
        latestWkid: reference.latestWkid,
      );
    }

    final maxRecordCount = metadata['maxRecordCount'];
    if (maxRecordCount is! int || maxRecordCount <= 0) {
      throw const MainRoadsNetworkRetrievalException(
        'layer metadata',
        'maxRecordCount must be a positive integer',
      );
    }
    final requestedPageSize =
        pageSize < maxRecordCount ? pageSize : maxRecordCount;

    final countResponse = await client.getJson(
      client.layerUri(mainRoadsNetworkLayerId, path: 'query', query: const {
        'where': '1=1',
        'returnCountOnly': 'true',
        'f': 'json',
      }),
      context: 'feature count',
    );
    final expectedCount = countResponse['count'];
    if (expectedCount is! int || expectedCount < 0) {
      throw const MainRoadsNetworkRetrievalException(
        'feature count',
        'ArcGIS did not return a non-negative integer count',
      );
    }

    final features = <dynamic>[];
    var pages = 0;
    while (features.length < expectedCount) {
      if (pages >= maxPages) {
        throw MainRoadsNetworkRetrievalException(
          'feature pagination',
          'maxPages ($maxPages) reached before retrieval completed',
        );
      }

      final query = <String, String>{
        'where': '1=1',
        'outFields': '*',
        'returnGeometry': 'true',
        'orderByFields': 'OBJECTID',
        'outSR': '$requestedOutputWkid',
        'resultOffset': '${features.length}',
        'resultRecordCount': '$requestedPageSize',
        'f': 'geojson',
        if (datumTransformation != null &&
            datumTransformation!.trim().isNotEmpty) ...{
          'datumTransformation': datumTransformation!,
        },
      };
      final page = await client.getJson(
        client.layerUri(mainRoadsNetworkLayerId, path: 'query', query: query),
        context: 'feature page ${pages + 1}',
      );
      final pageFeatures = page['features'];
      if (page['type'] != 'FeatureCollection' || pageFeatures is! List) {
        throw MainRoadsNetworkRetrievalException(
          'feature page ${pages + 1}',
          'response is not a GeoJSON FeatureCollection',
        );
      }
      if (pageFeatures.any((feature) => feature is! Map)) {
        throw MainRoadsNetworkRetrievalException(
          'feature page ${pages + 1}',
          'features must contain GeoJSON Feature objects',
        );
      }

      pages++;
      final transferLimitExceeded = _isTransferLimitExceeded(page);
      if (pageFeatures.isEmpty && transferLimitExceeded) {
        throw MainRoadsNetworkRetrievalException(
          'feature page $pages',
          'empty page returned while exceededTransferLimit is true',
        );
      }
      features.addAll(pageFeatures);
      if (transferLimitExceeded && features.length >= expectedCount) {
        throw const MainRoadsNetworkRetrievalException(
          'feature pagination',
          'service still reports exceededTransferLimit after the expected count',
        );
      }
      if (pageFeatures.isEmpty || features.length >= expectedCount) break;
      if (interPageDelay > Duration.zero) {
        await Future<void>.delayed(interPageDelay);
      }
    }

    if (features.length != expectedCount) {
      throw MainRoadsNetworkRetrievalException(
        'feature pagination',
        'retrieved ${features.length} features, expected $expectedCount',
      );
    }

    final Map<String, dynamic> collection = {
      'type': 'FeatureCollection',
      'features': features,
    };
    late final List<MainRoadsNetworkSegment> segments;
    try {
      segments = parser.parseFeatureCollection(collection);
    } on MainRoadsParseException catch (error) {
      throw MainRoadsNetworkParseException(
        'complete FeatureCollection',
        error.toString(),
      );
    }
    final transform = datumTransformation;
    return MainRoadsNetworkLoadResult(
      segments: segments,
      pageCount: pages,
      expectedFeatureCount: expectedCount,
      retrievedFeatureCount: features.length,
      sourceContract: MainRoadsNetworkSourceContract(
        serviceUrl: client.serviceUrl,
        layerId: mainRoadsNetworkLayerId,
        layerName: mainRoadsNetworkLayerName,
        sourceWkid: sourceWkid,
        sourceLatestWkid: reference.latestWkid,
        requestedOutputWkid: requestedOutputWkid,
        retrievedAt: DateTime.now().toUtc(),
        datumTransformationRequested:
            transform != null && transform.trim().isNotEmpty,
        datumTransformation: transform,
      ),
    );
  }

  void _validateLayerMetadata(Map<String, dynamic> metadata) {
    final id = metadata['id'];
    if (id != mainRoadsNetworkLayerId) {
      throw MainRoadsNetworkRetrievalException(
        'layer metadata',
        'expected layer id $mainRoadsNetworkLayerId, got $id',
      );
    }
    final name = metadata['name'];
    if (name != mainRoadsNetworkLayerName) {
      throw MainRoadsNetworkRetrievalException(
        'layer metadata',
        'expected layer name "$mainRoadsNetworkLayerName", got "$name"',
      );
    }
    if (metadata['geometryType'] != 'esriGeometryPolyline') {
      throw MainRoadsNetworkRetrievalException(
        'layer metadata',
        'expected esriGeometryPolyline, got ${metadata['geometryType']}',
      );
    }
  }

  _SpatialReference _sourceReference(Map<String, dynamic> metadata) {
    final candidates = <Object?>[
      metadata['sourceSpatialReference'],
      (metadata['extent'] is Map)
          ? (metadata['extent'] as Map)['spatialReference']
          : null,
      (metadata['fullExtent'] is Map)
          ? (metadata['fullExtent'] as Map)['spatialReference']
          : null,
      metadata['spatialReference'],
    ];
    for (final candidate in candidates) {
      if (candidate is! Map) continue;
      final wkid = _asWkid(candidate['wkid']);
      final latestWkid = _asWkid(candidate['latestWkid']);
      if (wkid != null || latestWkid != null) {
        return _SpatialReference(wkid, latestWkid);
      }
    }
    return const _SpatialReference(null, null);
  }

  int? _asWkid(Object? value) {
    if (value is int) return value;
    if (value is num &&
        value.isFinite &&
        value == value.truncateToDouble()) {
      return value.toInt();
    }
    return null;
  }

  bool _isTransferLimitExceeded(Map<String, dynamic> page) {
    final properties = page['properties'];
    return page['exceededTransferLimit'] == true ||
        (properties is Map && properties['exceededTransferLimit'] == true);
  }
}

class _SpatialReference {
  const _SpatialReference(this.wkid, this.latestWkid);

  final int? wkid;
  final int? latestWkid;
}
