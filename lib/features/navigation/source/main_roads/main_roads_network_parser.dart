import 'main_roads_network_segment.dart';

/// Structured parse failure for Main Roads layer-78 GeoJSON.
class MainRoadsParseException implements Exception {
  const MainRoadsParseException({
    required this.problem,
    this.featureIndex,
    this.globalId,
    this.field,
  });

  final String problem;

  /// Index within `features`, or null for collection-level problems.
  final int? featureIndex;

  /// Source GlobalID when it could be read.
  final String? globalId;

  /// Offending field/path, e.g. `properties.ROAD` or `geometry.coordinates[2]`.
  final String? field;

  @override
  String toString() {
    final where = [
      if (featureIndex != null) 'feature $featureIndex',
      if (globalId != null) 'GlobalID $globalId',
      if (field != null) field,
    ].join(', ');
    return 'MainRoadsParseException(${where.isEmpty ? '' : '$where: '}$problem)';
  }
}

/// Parses an already-decoded GeoJSON FeatureCollection of Main Roads layer 78
/// into source segments. Performs no I/O, topology, snapping or eligibility
/// logic. Any invalid feature fails the whole parse.
///
/// GeoJSON coordinates are `[longitude, latitude]`. `LineString` (one part)
/// and `MultiLineString` (one part per member line, kept separate and never
/// joined) are supported; both keep the feature's GlobalID and metadata.
class MainRoadsNetworkParser {
  const MainRoadsNetworkParser();

  List<MainRoadsNetworkSegment> parseFeatureCollection(
    Map<String, dynamic> json,
  ) {
    if (json['type'] != 'FeatureCollection') {
      throw MainRoadsParseException(
        problem:
            'expected type FeatureCollection, got ${_describe(json['type'])}',
        field: 'type',
      );
    }
    final features = json['features'];
    if (features is! List) {
      throw const MainRoadsParseException(
        problem: 'features must be a list',
        field: 'features',
      );
    }

    final segments = <MainRoadsNetworkSegment>[];
    final seen = <String, int>{};
    for (var i = 0; i < features.length; i++) {
      final segment = _parseFeature(features[i], i);
      final first = seen[segment.globalId];
      if (first != null) {
        throw MainRoadsParseException(
          problem: 'duplicate GlobalID (first seen at feature $first)',
          featureIndex: i,
          globalId: segment.globalId,
          field: 'properties.GlobalID',
        );
      }
      seen[segment.globalId] = i;
      segments.add(segment);
    }
    return segments;
  }

  MainRoadsNetworkSegment _parseFeature(Object? raw, int index) {
    MainRoadsParseException fail(String problem, [String? field, String? id]) =>
        MainRoadsParseException(
          problem: problem,
          featureIndex: index,
          globalId: id,
          field: field,
        );

    if (raw is! Map) throw fail('feature must be an object');
    if (raw['type'] != 'Feature') {
      throw fail(
          'expected type Feature, got ${_describe(raw['type'])}', 'type');
    }
    final props = raw['properties'];
    if (props is! Map) throw fail('properties must be an object', 'properties');

    final globalId = _string(props['GlobalID']);
    if (globalId == null) {
      throw fail('missing or empty GlobalID', 'properties.GlobalID');
    }
    MainRoadsParseException f(String problem, String field) =>
        fail(problem, field, globalId);

    final road = _string(props['ROAD']);
    if (road == null) throw f('missing or empty ROAD', 'properties.ROAD');

    final routeNeId = _int(props['ROUTE_NE_ID']);
    if (routeNeId == null) {
      throw f(
          'missing or non-integer ROUTE_NE_ID: ${_describe(props['ROUTE_NE_ID'])}',
          'properties.ROUTE_NE_ID');
    }
    final maxNetwork = _int(props['MAX_NETWORK']);
    if (maxNetwork == null) {
      throw f(
          'missing or non-integer MAX_NETWORK: ${_describe(props['MAX_NETWORK'])}',
          'properties.MAX_NETWORK');
    }

    double number(String key) {
      final v = _double(props[key]);
      if (v == null) {
        throw f('missing or non-numeric $key: ${_describe(props[key])}',
            'properties.$key');
      }
      return v;
    }

    final startSlk = number('START_SLK');
    final endSlk = number('END_SLK');
    final startDist = number('START_TRUE_DIST');
    final endDist = number('END_TRUE_DIST');
    if (endSlk < startSlk) {
      throw f('END_SLK $endSlk < START_SLK $startSlk', 'properties.END_SLK');
    }
    if (endDist < startDist) {
      throw f('END_TRUE_DIST $endDist < START_TRUE_DIST $startDist',
          'properties.END_TRUE_DIST');
    }

    final objectIdRaw = props['OBJECTID'];
    final objectId = _int(objectIdRaw);
    if (objectIdRaw != null && objectId == null) {
      throw f('non-integer OBJECTID: ${_describe(objectIdRaw)}',
          'properties.OBJECTID');
    }

    final parts = _parseGeometry(raw['geometry'], f);

    return MainRoadsNetworkSegment(
      globalId: globalId,
      objectId: objectId,
      road: road,
      roadName: _string(props['ROAD_NAME']),
      routeNeId: routeNeId,
      startSlk: startSlk,
      endSlk: endSlk,
      startTrueDist: startDist,
      endTrueDist: endDist,
      networkType: _string(props['NETWORK_TYPE']),
      networkCategory: _string(props['NETWORK_CATEGORY']),
      maxNetwork: maxNetwork,
      parts: parts,
    );
  }

  List<List<SourceCoordinate>> _parseGeometry(
    Object? geometry,
    MainRoadsParseException Function(String, String) f,
  ) {
    if (geometry is! Map) throw f('missing or invalid geometry', 'geometry');
    final type = geometry['type'];
    final coords = geometry['coordinates'];
    if (type == 'LineString') {
      if (coords is! List) {
        throw f('coordinates must be a list', 'geometry.coordinates');
      }
      return [_parseLine(coords, 'geometry.coordinates', f)];
    }
    if (type == 'MultiLineString') {
      if (coords is! List) {
        throw f('coordinates must be a list', 'geometry.coordinates');
      }
      if (coords.isEmpty) {
        throw f(
            'MultiLineString needs at least 1 line', 'geometry.coordinates');
      }
      final parts = <List<SourceCoordinate>>[];
      for (var p = 0; p < coords.length; p++) {
        final line = coords[p];
        final path = 'geometry.coordinates[$p]';
        if (line is! List) throw f('line part must be a list', path);
        parts.add(_parseLine(line, path, f));
      }
      return parts;
    }
    throw f('unsupported geometry type ${_describe(type)}', 'geometry.type');
  }

  List<SourceCoordinate> _parseLine(
    List coords,
    String path,
    MainRoadsParseException Function(String, String) f,
  ) {
    if (coords.length < 2) {
      throw f('LineString needs at least 2 coordinates, got ${coords.length}',
          path);
    }

    final result = <SourceCoordinate>[];
    for (var i = 0; i < coords.length; i++) {
      final field = '$path[$i]';
      final c = coords[i];
      // Optional third element (elevation) is ignored.
      if (c is! List || c.length < 2 || c.length > 3) {
        throw f('coordinate must be [longitude, latitude(, z)]', field);
      }
      final lng = c[0];
      final lat = c[1];
      if (lng is! num || lat is! num) {
        throw f('non-numeric coordinate ${_describe(c)}', field);
      }
      if (!lng.isFinite || !lat.isFinite) {
        throw f('non-finite coordinate', field);
      }
      if (lat < -90 || lat > 90) {
        throw f('latitude $lat out of range [-90, 90]', field);
      }
      if (lng < -180 || lng > 180) {
        throw f('longitude $lng out of range [-180, 180]', field);
      }
      result.add(SourceCoordinate(
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
      ));
    }
    return List.unmodifiable(result);
  }

  static String? _string(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static double? _double(Object? v) {
    final d = v is num
        ? v.toDouble()
        : (v is String ? double.tryParse(v.trim()) : null);
    return d != null && d.isFinite ? d : null;
  }

  static int? _int(Object? v) {
    if (v is int) return v;
    if (v is double) {
      return v.isFinite && v == v.truncateToDouble()
          ? int.tryParse(v.toStringAsFixed(0))
          : null;
    }
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  /// Short, bounded description of a value for diagnostics.
  static String _describe(Object? v) {
    final s = '$v';
    return s.length > 60 ? '${s.substring(0, 60)}…' : s;
  }
}
