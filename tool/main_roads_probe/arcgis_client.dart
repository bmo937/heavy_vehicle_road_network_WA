import 'dart:convert';

import 'package:dio/dio.dart';

/// Investigation source (NOT the production service constant in lib/).
const String investigationBaseUrl =
    'https://gisservices.mainroads.wa.gov.au/arcgis/rest/services/OpenData/HVS_Networks_DataPortal/MapServer';

/// Thrown for request failures, ArcGIS error payloads and malformed responses.
/// A failure is never represented as an empty result.
class ProbeException implements Exception {
  final int layerId;
  final String message;
  const ProbeException(this.layerId, this.message);
  @override
  String toString() => 'ProbeException(layer $layerId): $message';
}

class LayerData {
  final int layerId;
  final Map<String, dynamic> metadata;
  final List<Map<String, dynamic>> rows;
  /// False when pagination stopped before the service reported the end.
  final bool complete;
  final int pages;
  final String? incompleteReason;
  const LayerData(this.layerId, this.metadata, this.rows, this.complete, this.pages, this.incompleteReason);
}

Dio buildProbeDio() => Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.plain,
    ));

Uri layerUri(int layerId, {String? path, Map<String, String>? query, String baseUrl = investigationBaseUrl}) {
  final base = Uri.parse(baseUrl);
  return base.replace(
    pathSegments: [...base.pathSegments, '$layerId', if (path != null) path],
    queryParameters: query,
  );
}

Map<String, dynamic> _decode(int layerId, Response r) {
  if (r.statusCode != 200) throw ProbeException(layerId, 'Unexpected status ${r.statusCode}');
  try {
    final raw = r.data;
    final data = raw is String ? jsonDecode(raw) : raw;
    if (data is! Map) throw const FormatException('Response is not a JSON object');
    if (data['error'] != null) {
      final e = data['error'];
      throw ProbeException(layerId, 'ArcGIS error: ${e is Map ? e['message'] ?? e['code'] : e}');
    }
    return Map<String, dynamic>.from(data);
  } on FormatException catch (e) {
    throw ProbeException(layerId, 'Malformed response: ${e.message}');
  }
}

Future<Map<String, dynamic>> _get(Dio dio, int layerId, Uri uri) async {
  try {
    return _decode(layerId, await dio.getUri(uri));
  } on DioException catch (e) {
    throw ProbeException(layerId, 'Request failed: ${e.type.name} status=${e.response?.statusCode}');
  }
}

Future<Map<String, dynamic>> fetchLayerMetadata(Dio dio, int layerId, {String baseUrl = investigationBaseUrl}) =>
    _get(dio, layerId, layerUri(layerId, query: {'f': 'json'}, baseUrl: baseUrl));

/// Fetches every attribute row (no geometry) using resultOffset/resultRecordCount.
/// Stops only when the service stops reporting `exceededTransferLimit` (or
/// returns an empty page). If [maxPages] is hit the result is marked incomplete.
/// Throws [ProbeException] on any failed or malformed page.
Future<LayerData> fetchAllAttributes(
  Dio dio,
  int layerId, {
  String baseUrl = investigationBaseUrl,
  int pageSize = 1000,
  int maxPages = 500,
  Duration delay = const Duration(milliseconds: 250),
}) async {
  final metadata = await fetchLayerMetadata(dio, layerId, baseUrl: baseUrl);
  final max = metadata['maxRecordCount'];
  final size = max is int && max > 0 && max < pageSize ? max : pageSize;

  final rows = <Map<String, dynamic>>[];
  var offset = 0;
  var pages = 0;
  while (true) {
    if (pages >= maxPages) {
      return LayerData(layerId, metadata, rows, false, pages, 'maxPages ($maxPages) reached');
    }
    final uri = layerUri(layerId, path: 'query', baseUrl: baseUrl, query: {
      'where': '1=1',
      'outFields': '*',
      'returnGeometry': 'false',
      'orderByFields': 'OBJECTID',
      'resultOffset': '$offset',
      'resultRecordCount': '$size',
      'f': 'json',
    });
    final data = await _get(dio, layerId, uri);
    final features = data['features'];
    if (features is! List) throw ProbeException(layerId, 'Malformed response: missing features list');
    for (final f in features) {
      final a = f is Map ? f['attributes'] : null;
      if (a is! Map) throw ProbeException(layerId, 'Malformed response: feature without attributes');
      rows.add(Map<String, dynamic>.from(a));
    }
    pages++;
    offset += features.length;
    final more = data['exceededTransferLimit'] == true;
    if (features.isEmpty) {
      if (more) {
        return LayerData(layerId, metadata, rows, false, pages, 'empty page while exceededTransferLimit was true');
      }
      break;
    }
    if (!more) break;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }
  return LayerData(layerId, metadata, rows, true, pages, null);
}
