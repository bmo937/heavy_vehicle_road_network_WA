import 'package:dio/dio.dart';

import '../main_roads_probe/arcgis_client.dart';

const int topologyLayerId = 78;

/// Outcome of retrieving layer 78 as GeoJSON. [collection] merges every page
/// into ONE FeatureCollection so the production parser sees the complete
/// dataset and its duplicate-GlobalID check spans all pages.
class GeoJsonFetchOutcome {
  const GeoJsonFetchOutcome({
    required this.collection,
    required this.complete,
    required this.pages,
    required this.expectedCount,
    required this.incompleteReasons,
  });

  final Map<String, dynamic> collection;

  /// True only if every page succeeded, the service reported no further
  /// records, and the retrieved count equals the service's own total count.
  final bool complete;
  final int pages;
  final int? expectedCount;
  final List<String> incompleteReasons;

  int get retrieved => (collection['features'] as List).length;
}

bool _exceeded(Map<String, dynamic> page) {
  // ArcGIS places the flag at the top level; some versions nest it in properties.
  final props = page['properties'];
  return page['exceededTransferLimit'] == true ||
      (props is Map && props['exceededTransferLimit'] == true);
}

/// Fetches all layer-78 features with geometry, paginated by OBJECTID order.
/// Never throws for service failures: any failure yields an INCOMPLETE outcome
/// (with whatever was retrieved) and an explanatory reason.
Future<GeoJsonFetchOutcome> fetchLayerGeoJson(
  Dio dio, {
  int layerId = topologyLayerId,
  String baseUrl = investigationBaseUrl,
  int pageSize = 1000,
  int maxPages = 200,
  Duration delay = const Duration(milliseconds: 250),
}) async {
  final features = <dynamic>[];
  final reasons = <String>[];
  int? expected;
  var pages = 0;

  Map<String, dynamic> collection() => {'type': 'FeatureCollection', 'features': features};
  GeoJsonFetchOutcome outcome() => GeoJsonFetchOutcome(
        collection: collection(),
        complete: reasons.isEmpty,
        pages: pages,
        expectedCount: expected,
        incompleteReasons: List.unmodifiable(reasons),
      );

  try {
    final meta = await fetchLayerMetadata(dio, layerId, baseUrl: baseUrl);
    final max = meta['maxRecordCount'];
    final size = max is int && max > 0 && max < pageSize ? max : pageSize;

    final countData = await fetchJson(
      dio,
      layerId,
      layerUri(layerId, path: 'query', baseUrl: baseUrl, query: {
        'where': '1=1',
        'returnCountOnly': 'true',
        'f': 'json',
      }),
    );
    final count = countData['count'];
    if (count is! int || count < 0) {
      reasons.add('service did not return a valid total count');
      return outcome();
    }
    expected = count;

    var lastFlag = false;
    while (true) {
      if (pages >= maxPages) {
        reasons.add('maxPages ($maxPages) reached before the service reported the end');
        break;
      }
      final page = await fetchJson(
        dio,
        layerId,
        layerUri(layerId, path: 'query', baseUrl: baseUrl, query: {
          'where': '1=1',
          'outFields': '*',
          'returnGeometry': 'true',
          'outSR': '4326',
          'orderByFields': 'OBJECTID',
          'resultOffset': '${features.length}',
          'resultRecordCount': '$size',
          'f': 'geojson',
        }),
      );
      final pageFeatures = page['features'];
      if (page['type'] != 'FeatureCollection' || pageFeatures is! List) {
        reasons.add('page ${pages + 1}: malformed GeoJSON FeatureCollection');
        break;
      }
      pages++;
      features.addAll(pageFeatures);
      lastFlag = _exceeded(page);
      if (pageFeatures.isEmpty) break;
      if (!lastFlag && features.length >= count) break;
      if (delay > Duration.zero) await Future<void>.delayed(delay);
    }

    if (reasons.isEmpty) {
      if (lastFlag) {
        reasons.add('service still reported exceededTransferLimit on the final page');
      }
      if (features.length != count) {
        reasons.add('retrieved ${features.length} features but service reports $count');
      }
    }
  } on ProbeException catch (e) {
    reasons.add(e.message);
  } on DioException catch (e) {
    reasons.add('Request failed: ${e.type.name}');
  }
  return outcome();
}
