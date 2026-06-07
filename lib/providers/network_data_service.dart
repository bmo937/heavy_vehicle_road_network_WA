import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Fetch GeoJSON data for a specific sublayer within the visible bounds
Future<Map<String, dynamic>> fetchOnlineLayerData(int subLayerId, LatLngBounds visibleBounds) async {
  final dio = Dio();
  final southwest = visibleBounds.southwest;
  final northeast = visibleBounds.northeast;

  // Format: minLng,minLat,maxLng,maxLat
  final boundsString = '${southwest.longitude},${southwest.latitude},${northeast.longitude},${northeast.latitude}';
  try {
    debugPrint('Fetching data for layer $subLayerId with bounds: $boundsString');
    // Construct the URL with query parameters including the boundsString
    // Using the base URL format and adding query parameters
    String baseUrl = 'https://gisservices.mainroads.wa.gov.au/arcgis/rest/services/OpenData/HVS_Networks_2_DataPortal/MapServer/$subLayerId';
    String url = constructUrlWithBounds(baseUrl, boundsString);

    final response = await dio.get(url);

    if (response.statusCode == 200) {
      dynamic data;
      if (response.data is String) {
        data = jsonDecode(response.data);
      } else {
        data = response.data;
      }
      return data;
    } else {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching layer data: $e');
    return _createEmptyGeoJson(); // Return empty but valid GeoJSON instead of throwing
  }
}

/// Creates an empty but valid GeoJSON object to prevent crashes
Map<String, dynamic> _createEmptyGeoJson() {
  return {'type': 'FeatureCollection', 'features': []};
}

/// Helper method to construct a query URL with bounds
String constructUrlWithBounds(String baseUrl, String boundsString) {
  if (baseUrl.isEmpty) return '';

  // Normalize the base URL - remove trailing slash if present
  String normalizedUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  // Check if URL already has query parameters
  if (normalizedUrl.contains('?')) {
    // URL already has query parameters, add or update bounds parameter
    if (normalizedUrl.contains('geometry=')) {
      final regex = RegExp(r'geometry=[^&]*');
      return normalizedUrl.replaceAll(regex, 'geometry=$boundsString');
    } else {
      return '$normalizedUrl&geometry=$boundsString&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelIntersects';
    }
  } else {
    // URL does not have query parameters, add them with bounds
    return '$normalizedUrl/query?where=1%3D1&geometry=$boundsString&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=*&returnGeometry=true&geometryPrecision=6&outSR=4326&f=geojson';
  }
}
