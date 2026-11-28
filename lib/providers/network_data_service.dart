import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/services/dio_provider.dart';

const String _hvsNetworksBaseUrl =
    'https://gisservices.mainroads.wa.gov.au/arcgis/rest/services/OpenData/HVS_Networks_2_DataPortal/MapServer';

/// Thrown when a layer request fails or returns an unusable response.
/// Distinct from a successful response containing zero features.
/// Never includes the request URL (may carry credentials).
class NetworkDataException implements Exception {
  final String service;
  final String message;
  final int? statusCode;
  final DioExceptionType? failureType;

  const NetworkDataException(this.service, this.message,
      {this.statusCode, this.failureType});

  @override
  String toString() => 'NetworkDataException($service): $message'
      '${statusCode != null ? ' [status $statusCode]' : ''}'
      '${failureType != null ? ' [${failureType!.name}]' : ''}';
}

/// Fetch GeoJSON data for a specific sublayer within the visible bounds.
///
/// Returns a FeatureCollection (possibly with an empty `features` list when the
/// request genuinely succeeded with no data). Throws [NetworkDataException] on
/// any request or parsing failure; failures are never reported as empty data.
Future<Map<String, dynamic>> fetchOnlineLayerData(
    int subLayerId, LatLngBounds visibleBounds,
    {Dio? dio}) async {
  final client = dio ?? buildAppDio();
  final southwest = visibleBounds.southwest;
  final northeast = visibleBounds.northeast;

  // Format: minLng,minLat,maxLng,maxLat
  final boundsString =
      '${southwest.longitude},${southwest.latitude},${northeast.longitude},${northeast.latitude}';
  final service = 'MainRoadsNetwork/$subLayerId';
  final url =
      constructUrlWithBounds('$_hvsNetworksBaseUrl/$subLayerId', boundsString);

  final Response response;
  try {
    response = await client.get(url);
  } on DioException catch (e) {
    debugPrint(
        'Network error [$service]: ${e.type.name} status=${e.response?.statusCode}');
    throw NetworkDataException(service, 'Request failed',
        statusCode: e.response?.statusCode, failureType: e.type);
  }

  if (response.statusCode != 200) {
    throw NetworkDataException(service, 'Unexpected status',
        statusCode: response.statusCode);
  }

  try {
    final raw = response.data;
    final data = raw is String ? jsonDecode(raw) : raw;
    if (data is! Map || data['features'] is! List) {
      throw const FormatException('Not a GeoJSON FeatureCollection');
    }
    return Map<String, dynamic>.from(data);
  } on FormatException catch (e) {
    debugPrint('Malformed response [$service]: ${e.message}');
    throw NetworkDataException(service, 'Malformed response: ${e.message}',
        statusCode: response.statusCode);
  }
}

/// Builds an ArcGIS query URL for the given bounds.
/// [boundsString] is `minLng,minLat,maxLng,maxLat` (EPSG:4326).
String constructUrlWithBounds(String baseUrl, String boundsString) {
  if (baseUrl.isEmpty) return '';

  // Normalize the base URL - remove trailing slash if present
  final normalizedUrl = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final uri = Uri.parse(normalizedUrl);

  if (uri.hasQuery) {
    final params = Map<String, String>.from(uri.queryParameters);
    if (params.containsKey('geometry')) {
      params['geometry'] = boundsString;
    } else {
      params.addAll({
        'geometry': boundsString,
        'geometryType': 'esriGeometryEnvelope',
        'inSR': '4326',
        'spatialRel': 'esriSpatialRelIntersects',
      });
    }
    return uri.replace(queryParameters: params).toString();
  }

  return uri.replace(path: '${uri.path}/query', queryParameters: {
    'where': '1=1',
    'geometry': boundsString,
    'geometryType': 'esriGeometryEnvelope',
    'inSR': '4326',
    'spatialRel': 'esriSpatialRelIntersects',
    'outFields': '*',
    'returnGeometry': 'true',
    'geometryPrecision': '6',
    'outSR': '4326',
    'f': 'geojson',
  }).toString();
}
