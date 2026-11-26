import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Timeouts for ordinary remote API requests (ArcGIS FeatureServer/MapServer).
/// Connect: 10s covers slow mobile connections; receive: 30s allows for large
/// GeoJSON responses.
const Duration kDefaultConnectTimeout = Duration(seconds: 10);
const Duration kDefaultReceiveTimeout = Duration(seconds: 30);

/// Single source of truth for common Dio configuration.
Dio buildAppDio() => Dio(BaseOptions(
      connectTimeout: kDefaultConnectTimeout,
      receiveTimeout: kDefaultReceiveTimeout,
    ));

final dioProvider = Provider<Dio>((ref) {
  final dio = buildAppDio();
  ref.onDispose(dio.close);
  return dio;
});
