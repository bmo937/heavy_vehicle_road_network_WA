import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_places_service.riverpod.g.dart';

@riverpod
class GooglePlacesService extends _$GooglePlacesService {
  @override
  // ignore: overridden_fields
  late String apiKey;

  late Dio _dio;

  // Perth, WA coordinates as reference point
  static const double perthLat = -31.9505;
  static const double perthLng = 115.8605;

  Future<List<Map<String, dynamic>>> getAutocompletePredictions(
      String query) async {
    try {
      final response = await _dio.get('/autocomplete/json', queryParameters: {
        'input': query,
        'key': apiKey,
        // Restrict to Western Australia using a circular area around Perth
        'location': '$perthLat,$perthLng',
        'radius': '500000', // 500km radius to cover most of WA
        'components': 'country:au',
        'strictbounds': 'true', // Strict geographical restriction
      });

      if (response.statusCode == 200) {
        final predictions =
            List<Map<String, dynamic>>.from(response.data['predictions']);

        // Sort predictions by distance from Perth
        predictions.sort((a, b) {
          final distanceA =
              _estimateDistanceFromDescription(a['description'] ?? '');
          final distanceB =
              _estimateDistanceFromDescription(b['description'] ?? '');
          return distanceA.compareTo(distanceB);
        });

        return predictions;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to fetch autocomplete predictions',
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Calculates the distance between two geographic points using the Haversine formula
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1Rad = lat1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double deltaLat = (lat2 - lat1) * (pi / 180);
    final double deltaLng = (lng2 - lng1) * (pi / 180);

    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Estimates distance from Perth based on location description
  /// This is a rough estimation for initial sorting before we get actual coordinates
  double _estimateDistanceFromDescription(String description) {
    // Simple heuristic: locations mentioning Perth or nearby suburbs get lower distance
    final lowerDesc = description.toLowerCase();
    if (lowerDesc.contains('perth')) return 0;
    if (lowerDesc.contains('fremantle') ||
        lowerDesc.contains('joondalup') ||
        lowerDesc.contains('rockingham') ||
        lowerDesc.contains('midland')) {
      return 25;
    }
    if (lowerDesc.contains('mandurah') ||
        lowerDesc.contains('armadale') ||
        lowerDesc.contains('wanneroo')) {
      return 50;
    }
    if (lowerDesc.contains('bunbury') || lowerDesc.contains('geraldton')) {
      return 200;
    }
    if (lowerDesc.contains('albany') || lowerDesc.contains('kalgoorlie')) {
      return 400;
    }
    if (lowerDesc.contains('broome') || lowerDesc.contains('karratha')) {
      return 1000;
    }

    // Default moderate distance for unknown locations
    return 100;
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get('/details/json', queryParameters: {
        'place_id': placeId,
        'key': apiKey,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('result')) {
          final result = responseData['result'];

          // Ensure result is a Map, not a List
          if (result is Map<String, dynamic>) {
            return result;
          } else {
            debugPrint('Unexpected result type: ${result.runtimeType}');
            debugPrint('Result content: $result');
            throw DioException(
              requestOptions: response.requestOptions,
              error: 'Place details result is not a Map: ${result.runtimeType}',
            );
          }
        } else {
          debugPrint('Unexpected response structure: $responseData');
          throw DioException(
            requestOptions: response.requestOptions,
            error: 'Invalid response structure from Places API',
          );
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Failed to fetch place details',
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in getPlaceDetails: $e');
      rethrow;
    }
  }

  void _handleDioError(DioException error) {
    // Handle different DioError types
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        debugPrint('Connection Timeout: ${error.message}');
        break;
      case DioExceptionType.sendTimeout:
        debugPrint('Send Timeout: ${error.message}');
        break;
      case DioExceptionType.receiveTimeout:
        debugPrint('Receive Timeout: ${error.message}');
        break;
      case DioExceptionType.badResponse:
        debugPrint(
            'Server Response Error: ${error.response?.statusCode} ${error.response?.statusMessage}');
        break;
      case DioExceptionType.cancel:
        debugPrint('Request Cancelled: ${error.message}');
        break;
      case DioExceptionType.unknown:
        debugPrint('Unexpected Error: ${error.message}');
        break;
      case DioExceptionType.badCertificate:
        debugPrint('Connection Timeout: ${error.message}');
        break;
      case DioExceptionType.connectionError:
        debugPrint('Connection Timeout: ${error.message}');
        break;
    }
  }

  @override
  GooglePlacesService build(String apiKey) {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://maps.googleapis.com/maps/api/place',
      connectTimeout: Duration(milliseconds: 5000),
      receiveTimeout: Duration(milliseconds: 3000),
    ));
    return this;
  }
}
