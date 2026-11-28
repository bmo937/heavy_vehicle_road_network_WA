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
    if (requestedOutputWkid != _defaultOutputWkid ||
        pageSize <= 0 ||
        maxPages <= 0) {
      throw ArgumentError(
        'requestedOutputWkid must be 4326; pageSize and maxPages '
        'must be positive',
      );
    }

    final metadata = await client.getJson(
      client.layerUri(mainRoadsNetworkLayerId, query: const {'f': 'json'}),
      context: 'layer metadata',
    );
    _validateLayerMetadata(metadata);
    final reference = _sourceReference(metadata);
    final sourceWkid = reference.wkid ?? reference.latestWkid;
    if (reference.hasInvalidWkid ||
        reference.hasInvalidLatestWkid ||
        sourceWkid == null) {
      throw MainRoadsNetworkCrsException(
        'layer metadata',
        'source WKID is missing or malformed',
        sourceWkid: reference.wkid,
        latestWkid: reference.latestWkid,
      );
    }
    if ((reference.wkid != null &&
            !acceptedSourceWkids.contains(reference.wkid)) ||
        (reference.latestWkid != null &&
            !acceptedSourceWkids.contains(reference.latestWkid))) {
      throw MainRoadsNetworkCrsException(
        'layer metadata',
        'unsupported source WKID ${reference.wkid}'
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

    final initialObjectIds = await _getObjectIds('feature IDs');
    final objectIdBatches = <List<int>>[];
    for (var start = 0;
        start < initialObjectIds.length;
        start += requestedPageSize) {
      final end = start + requestedPageSize < initialObjectIds.length
          ? start + requestedPageSize
          : initialObjectIds.length;
      objectIdBatches.add(initialObjectIds.sublist(start, end));
    }
    if (objectIdBatches.isEmpty) objectIdBatches.add(const []);

    final features = <dynamic>[];
    final retrievedObjectIds = <int>[];
    var pages = 0;
    for (final objectIds in objectIdBatches) {
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
        'resultRecordCount': '$requestedPageSize',
        'f': 'geojson',
        if (objectIds.isNotEmpty) 'objectIds': objectIds.join(','),
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

      final transferLimitExceeded = _isTransferLimitExceeded(page, pages + 1);
      if (transferLimitExceeded) {
        throw MainRoadsNetworkRetrievalException(
          'feature page ${pages + 1}',
          'service reports exceededTransferLimit for an OBJECTID batch',
        );
      }
      pages++;
      features.addAll(pageFeatures);
      for (final feature in pageFeatures) {
        final properties = (feature as Map)['properties'];
        final objectId =
            properties is Map ? _asWkid(properties['OBJECTID']) : null;
        if (objectId == null) {
          throw MainRoadsNetworkRetrievalException(
            'feature page $pages',
            'feature is missing a valid OBJECTID',
          );
        }
        retrievedObjectIds.add(objectId);
      }
      if (pages < objectIdBatches.length && interPageDelay > Duration.zero) {
        await Future<void>.delayed(interPageDelay);
      }
    }

    final finalObjectIds = await _getObjectIds('feature ID verification');
    if (!_sameIds(initialObjectIds, finalObjectIds)) {
      throw const MainRoadsNetworkRetrievalException(
        'feature pagination',
        'OBJECTID set changed during retrieval',
      );
    }

    if (features.length != expectedCount) {
      throw MainRoadsNetworkRetrievalException(
        'feature pagination',
        'retrieved ${features.length} features, expected $expectedCount',
      );
    }
    retrievedObjectIds.sort();
    if (!_sameIds(initialObjectIds, retrievedObjectIds)) {
      throw const MainRoadsNetworkRetrievalException(
        'feature pagination',
        'retrieved OBJECTIDs do not match the stable source ID set',
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
      if (candidate.containsKey('wkid') ||
          candidate.containsKey('latestWkid')) {
        final rawWkid = candidate['wkid'];
        final rawLatestWkid = candidate['latestWkid'];
        final wkid = _asWkid(rawWkid);
        final latestWkid = _asWkid(rawLatestWkid);
        return _SpatialReference(
          wkid,
          latestWkid,
          hasInvalidWkid: candidate.containsKey('wkid') && wkid == null,
          hasInvalidLatestWkid:
              candidate.containsKey('latestWkid') && latestWkid == null,
        );
      }
    }
    return const _SpatialReference(null, null);
  }

  Future<List<int>> _getObjectIds(String context) async {
    final response = await client.getJson(
      client.layerUri(mainRoadsNetworkLayerId, path: 'query', query: const {
        'where': '1=1',
        'returnIdsOnly': 'true',
        'returnGeometry': 'false',
        'f': 'json',
      }),
      context: context,
    );
    final objectIds = response['objectIds'];
    if (objectIds is! List ||
        objectIds.any((id) => id is! int || id < 0)) {
      throw MainRoadsNetworkRetrievalException(
        context,
        'ArcGIS did not return a valid OBJECTID list',
      );
    }
    final ids = objectIds.cast<int>()..sort();
    if (ids.toSet().length != ids.length) {
      throw MainRoadsNetworkRetrievalException(
        context,
        'ArcGIS returned duplicate OBJECTIDs',
      );
    }
    return ids;
  }

  bool _sameIds(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
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

  bool _isTransferLimitExceeded(Map<String, dynamic> page, int pageNumber) {
    final properties = page['properties'];
    final topLevel = page['exceededTransferLimit'];
    final propertyLevel =
        properties is Map ? properties['exceededTransferLimit'] : null;
    if ((page.containsKey('exceededTransferLimit') && topLevel is! bool) ||
        (properties is Map &&
            properties.containsKey('exceededTransferLimit') &&
            propertyLevel is! bool)) {
      throw MainRoadsNetworkRetrievalException(
        'feature page $pageNumber',
        'exceededTransferLimit must be a boolean when supplied',
      );
    }
    return topLevel == true || propertyLevel == true;
  }
}

class _SpatialReference {
  const _SpatialReference(
    this.wkid,
    this.latestWkid, {
    this.hasInvalidWkid = false,
    this.hasInvalidLatestWkid = false,
  });

  final int? wkid;
  final int? latestWkid;
  final bool hasInvalidWkid;
  final bool hasInvalidLatestWkid;
}
