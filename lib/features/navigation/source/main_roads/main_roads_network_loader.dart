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
    Map<int, Set<int>> equivalentSourceWkidAliases = const {
      102100: {3857},
      3857: {102100},
    },
    this.requestedOutputWkid = _defaultOutputWkid,
    this.pageSize = _defaultPageSize,
    this.maxPages = _defaultMaxPages,
    this.interPageDelay = const Duration(milliseconds: 250),
    this.datumTransformation,
  })  : acceptedSourceWkids = Set.unmodifiable(acceptedSourceWkids),
        equivalentSourceWkidAliases = Map.unmodifiable(
          equivalentSourceWkidAliases.map(
            (wkid, aliases) => MapEntry(wkid, Set<int>.unmodifiable(aliases)),
          ),
        );

  final MainRoadsNetworkClient client;
  final MainRoadsNetworkParser parser;
  final Set<int> acceptedSourceWkids;
  final Map<int, Set<int>> equivalentSourceWkidAliases;
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
    final reference = _validatedSourceReference(metadata, 'layer metadata');
    final sourceWkid = reference.wkid ?? reference.latestWkid;

    final maxRecordCount = metadata['maxRecordCount'];
    if (maxRecordCount is! int || maxRecordCount <= 0) {
      throw const MainRoadsNetworkRetrievalException(
        'layer metadata',
        'maxRecordCount must be a positive integer',
      );
    }
    final requestedPageSize =
        pageSize < maxRecordCount ? pageSize : maxRecordCount;

    final countResponse = await client.getJsonWithStatus(
      client.layerUri(mainRoadsNetworkLayerId, path: 'query', query: const {
        'where': '1=1',
        'returnCountOnly': 'true',
        'f': 'json',
      }),
      context: 'feature count',
    );
    final expectedCount = countResponse.data['count'];
    if (expectedCount is! int || expectedCount < 0) {
      throw MainRoadsNetworkRetrievalException(
        'feature count',
        'ArcGIS did not return a non-negative integer count',
        statusCode: countResponse.statusCode,
      );
    }

    final initialObjectIds = await _getObjectIds('feature IDs');
    final features = <dynamic>[];
    final retrievedObjectIds = <int>[];
    var pages = 0;
    while (true) {
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

      _validatePageCrs(page, pages + 1);
      final transferLimitExceeded = _isTransferLimitExceeded(page, pages + 1);
      if (pageFeatures.length > requestedPageSize) {
        throw MainRoadsNetworkRetrievalException(
          'feature page ${pages + 1}',
          'page exceeds requested record count',
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
      if (pageFeatures.isEmpty) {
        if (transferLimitExceeded) {
          throw MainRoadsNetworkRetrievalException(
            'feature page $pages',
            'empty page reports exceededTransferLimit',
          );
        }
        break;
      }
      if (features.length >= expectedCount &&
          features.length >= initialObjectIds.length) {
        if (transferLimitExceeded) {
          throw MainRoadsNetworkRetrievalException(
            'feature page $pages',
            'service reports more features after expected count',
          );
        }
        break;
      }
      if (interPageDelay > Duration.zero) {
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

    final finalMetadata = await client.getJson(
      client.layerUri(mainRoadsNetworkLayerId, query: const {'f': 'json'}),
      context: 'layer metadata verification',
    );
    _validateLayerMetadata(finalMetadata);
    final finalReference =
        _validatedSourceReference(finalMetadata, 'layer metadata verification');
    if (reference.wkid != finalReference.wkid ||
        reference.latestWkid != finalReference.latestWkid) {
      throw MainRoadsNetworkCrsException(
        'layer metadata verification',
        'source WKID contract changed during retrieval',
        sourceWkid: finalReference.wkid,
        latestWkid: finalReference.latestWkid,
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
        sourceWkid: sourceWkid!,
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
    if (metadata.containsKey('sourceSpatialReference')) {
      return _parseReference(metadata['sourceSpatialReference']);
    }
    final candidates = <Object?>[
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
        return _parseReference(candidate);
      }
    }
    return const _SpatialReference(null, null);
  }

  _SpatialReference _parseReference(Object? candidate) {
    if (candidate is! Map) return const _SpatialReference(null, null);
    final wkid = _asWkid(candidate['wkid']);
    final latestWkid = _asWkid(candidate['latestWkid']);
    return _SpatialReference(
      wkid,
      latestWkid,
      hasInvalidWkid: candidate.containsKey('wkid') && wkid == null,
      hasInvalidLatestWkid:
          candidate.containsKey('latestWkid') && latestWkid == null,
    );
  }

  _SpatialReference _validatedSourceReference(
      Map<String, dynamic> metadata, String context) {
    final reference = _sourceReference(metadata);
    final wkid = reference.wkid;
    final latestWkid = reference.latestWkid;
    if (reference.hasInvalidWkid ||
        reference.hasInvalidLatestWkid ||
        (wkid == null && latestWkid == null)) {
      throw MainRoadsNetworkCrsException(
        context,
        'source WKID is missing or malformed',
        sourceWkid: wkid,
        latestWkid: latestWkid,
      );
    }
    if ((wkid != null && !acceptedSourceWkids.contains(wkid)) ||
        (latestWkid != null && !acceptedSourceWkids.contains(latestWkid))) {
      throw MainRoadsNetworkCrsException(
        context,
        'unsupported source WKIDs',
        sourceWkid: wkid,
        latestWkid: latestWkid,
      );
    }
    if (wkid != null &&
        latestWkid != null &&
        wkid != latestWkid &&
        !(equivalentSourceWkidAliases[wkid]?.contains(latestWkid) ?? false) &&
        !(equivalentSourceWkidAliases[latestWkid]?.contains(wkid) ?? false)) {
      throw MainRoadsNetworkCrsException(
        context,
        'unsupported or contradictory source WKIDs',
        sourceWkid: wkid,
        latestWkid: latestWkid,
      );
    }
    return reference;
  }

  void _validatePageCrs(Map<String, dynamic> page, int pageNumber) {
    if (!page.containsKey('crs')) return;
    final crs = page['crs'];
    final properties = crs is Map ? crs['properties'] : null;
    final name = properties is Map ? properties['name'] : null;
    const acceptedNames = {
      'EPSG:4326',
      'urn:ogc:def:crs:EPSG::4326',
      'urn:ogc:def:crs:OGC:1.3:CRS84',
      'OGC:CRS84',
      'CRS84',
    };
    if (crs is! Map ||
        crs['type'] != 'name' ||
        name is! String ||
        !acceptedNames.contains(name)) {
      throw MainRoadsNetworkCrsException(
        'feature page $pageNumber',
        'unsupported or malformed GeoJSON CRS declaration',
      );
    }
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
    if (objectIds is! List || objectIds.any((id) => id is! int || id < 0)) {
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
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
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
