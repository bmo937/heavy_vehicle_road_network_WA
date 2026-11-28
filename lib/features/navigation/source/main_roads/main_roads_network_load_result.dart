import 'main_roads_network_segment.dart';

/// CRS and source details for one complete Main Roads layer retrieval.
class MainRoadsNetworkSourceContract {
  const MainRoadsNetworkSourceContract({
    required this.serviceUrl,
    required this.layerId,
    required this.layerName,
    required this.sourceWkid,
    required this.sourceLatestWkid,
    required this.requestedOutputWkid,
    required this.retrievedAt,
    required this.datumTransformationRequested,
    required this.datumTransformation,
  });

  final String serviceUrl;
  final int layerId;
  final String layerName;

  /// The layer's source `wkid`, or `latestWkid` when the former is absent.
  final int sourceWkid;

  /// The layer's source `latestWkid`, when supplied.
  final int? sourceLatestWkid;

  final int requestedOutputWkid;
  final DateTime retrievedAt;
  final bool datumTransformationRequested;
  final String? datumTransformation;
}

/// Parsed segments and completeness/CRS evidence for one successful load.
class MainRoadsNetworkLoadResult {
  MainRoadsNetworkLoadResult({
    required Iterable<MainRoadsNetworkSegment> segments,
    required this.pageCount,
    required this.expectedFeatureCount,
    required this.retrievedFeatureCount,
    required this.sourceContract,
  }) : segments = List.unmodifiable(segments);

  final List<MainRoadsNetworkSegment> segments;
  final int pageCount;
  final int expectedFeatureCount;
  final int retrievedFeatureCount;
  final MainRoadsNetworkSourceContract sourceContract;
}
