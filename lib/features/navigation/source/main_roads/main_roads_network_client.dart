import 'dart:convert';

import 'package:dio/dio.dart';

const String mainRoadsNetworkServiceUrl =
    'https://gisservices.mainroads.wa.gov.au/arcgis/rest/services/OpenData/HVS_Networks_DataPortal/MapServer';
const int mainRoadsNetworkLayerId = 78;
const String mainRoadsNetworkLayerName =
    'Tandem Drive 1-10 All Networks';

/// Base type for failures while loading the Main Roads source.
abstract class MainRoadsNetworkLoadException implements Exception {
  const MainRoadsNetworkLoadException(this.context, this.message);

  final String context;
  final String message;

  @override
  String toString() => '${runtimeType.toString()}($context): $message';
}

/// A request, metadata, or pagination failure.
class MainRoadsNetworkRetrievalException
    extends MainRoadsNetworkLoadException {
  const MainRoadsNetworkRetrievalException(
    super.context,
    super.message, {
    this.statusCode,
    this.failureType,
  });

  final int? statusCode;
  final DioExceptionType? failureType;
}

/// Missing or unsupported source coordinate reference metadata.
class MainRoadsNetworkCrsException extends MainRoadsNetworkLoadException {
  const MainRoadsNetworkCrsException(
    super.context,
    super.message, {
    this.sourceWkid,
    this.latestWkid,
  });

  final int? sourceWkid;
  final int? latestWkid;
}

/// The complete response could not be parsed as Main Roads features.
class MainRoadsNetworkParseException extends MainRoadsNetworkLoadException {
  const MainRoadsNetworkParseException(super.context, super.message);
}

/// Small Dio wrapper that converts ArcGIS and transport failures to typed
/// errors without exposing request URLs in exception messages.
class MainRoadsNetworkClient {
  MainRoadsNetworkClient({
    required this.dio,
    this.serviceUrl = mainRoadsNetworkServiceUrl,
  });

  final Dio dio;
  final String serviceUrl;

  Uri layerUri(int layerId, {String? path, Map<String, String>? query}) {
    final base = Uri.parse(serviceUrl);
    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((segment) => segment.isNotEmpty),
        '$layerId',
        if (path != null) path,
      ],
      queryParameters: query,
    );
  }

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    required String context,
  }) async {
    return (await getJsonWithStatus(uri, context: context)).data;
  }

  Future<MainRoadsNetworkJsonResponse> getJsonWithStatus(
    Uri uri, {
    required String context,
  }) async {
    final Response response;
    try {
      response = await dio.getUri(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (error) {
      throw MainRoadsNetworkRetrievalException(
        context,
        'request failed',
        statusCode: error.response?.statusCode,
        failureType: error.type,
      );
    }

    if (response.statusCode != 200) {
      throw MainRoadsNetworkRetrievalException(
        context,
        'unexpected HTTP status',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      final raw = response.data;
      decoded = raw is String ? jsonDecode(raw) : raw;
    } on FormatException catch (error) {
      throw MainRoadsNetworkRetrievalException(
        context,
        'malformed JSON response: ${error.message}',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw MainRoadsNetworkRetrievalException(
        context,
        'response must be a JSON object',
        statusCode: response.statusCode,
      );
    }
    final data = Map<String, dynamic>.from(decoded);
    if (data['error'] != null) {
      final error = data['error'];
      final description =
          error is Map ? error['message'] ?? error['code'] : error;
      throw MainRoadsNetworkRetrievalException(
        context,
        'ArcGIS returned an error: $description',
        statusCode: response.statusCode,
      );
    }
    return MainRoadsNetworkJsonResponse(
      data: data,
      statusCode: response.statusCode!,
    );
  }
}

class MainRoadsNetworkJsonResponse {
  const MainRoadsNetworkJsonResponse({
    required this.data,
    required this.statusCode,
  });

  final Map<String, dynamic> data;
  final int statusCode;
}
