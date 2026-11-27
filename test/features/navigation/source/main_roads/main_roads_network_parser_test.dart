import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/features/navigation/source/main_roads/main_roads_network_parser.dart';

Map<String, dynamic> props([Map<String, dynamic> overrides = const {}]) => {
      'GlobalID': 'g1',
      'OBJECTID': 7,
      'ROAD': 'H001',
      'ROAD_NAME': 'Test Hwy',
      'ROUTE_NE_ID': 100,
      'START_SLK': 0.0,
      'END_SLK': 1.5,
      'START_TRUE_DIST': 0.0,
      'END_TRUE_DIST': 1.6,
      'NETWORK_TYPE': 'Tandem Drive',
      'NETWORK_CATEGORY': 'Network 3',
      'MAX_NETWORK': 3,
      ...overrides,
    };

Map<String, dynamic> line([Object? coords]) => {
      'type': 'LineString',
      'coordinates': coords ??
          [
            [115.8, -31.9],
            [115.9, -32.0],
          ],
    };

Map<String, dynamic> feature({
  Map<String, dynamic> p = const {},
  Object? geometry = _unset,
  Object? properties = _unset,
}) =>
    {
      'type': 'Feature',
      'properties': identical(properties, _unset) ? props(p) : properties,
      'geometry': identical(geometry, _unset) ? line() : geometry,
    };

const _unset = Object();

Map<String, dynamic> collection(List<Object?> features) =>
    {'type': 'FeatureCollection', 'features': features};

void main() {
  const parser = MainRoadsNetworkParser();
  List parse(List<Object?> f) => parser.parseFeatureCollection(collection(f));
  void rejects(List<Object?> f, String field) => expect(
        () => parse(f),
        throwsA(isA<MainRoadsParseException>()
            .having((e) => e.field, 'field', field)
            .having((e) => e.featureIndex, 'index', 0)),
      );

  test('parses valid feature and preserves metadata', () {
    final s = parse([feature()]).single;
    expect(s.globalId, 'g1');
    expect(s.objectId, 7);
    expect(s.road, 'H001');
    expect(s.roadName, 'Test Hwy');
    expect(s.routeNeId, 100);
    expect(s.startSlk, 0.0);
    expect(s.endSlk, 1.5);
    expect(s.startTrueDist, 0.0);
    expect(s.endTrueDist, 1.6);
    expect(s.networkType, 'Tandem Drive');
    expect(s.networkCategory, 'Network 3');
    expect(s.maxNetwork, 3);
    expect(s.geometry.length, 2);
  });

  test('GeoJSON order is longitude, latitude', () {
    final g = parse([feature()]).single.geometry;
    expect(g.first.longitude, 115.8);
    expect(g.first.latitude, -31.9);
  });

  test('multiple features, duplicate ROUTE_NE_ID accepted', () {
    final r = parse([
      feature(p: {'GlobalID': 'a', 'ROUTE_NE_ID': 5}),
      feature(p: {'GlobalID': 'b', 'ROUTE_NE_ID': 5}),
    ]);
    expect(r.map((s) => s.globalId), ['a', 'b']);
    expect(r.map((s) => s.routeNeId), [5, 5]);
  });

  test('duplicate GlobalID rejected', () {
    expect(
      () => parse([feature(), feature()]),
      throwsA(isA<MainRoadsParseException>()
          .having((e) => e.featureIndex, 'index', 1)
          .having((e) => e.globalId, 'id', 'g1')),
    );
  });

  test('missing GlobalID / ROAD', () {
    rejects([feature(p: {'GlobalID': null})], 'properties.GlobalID');
    rejects([feature(p: {'ROAD': ' '})], 'properties.ROAD');
  });

  test('malformed ROUTE_NE_ID and MAX_NETWORK', () {
    rejects([feature(p: {'ROUTE_NE_ID': 'abc'})], 'properties.ROUTE_NE_ID');
    rejects([feature(p: {'MAX_NETWORK': 'x'})], 'properties.MAX_NETWORK');
    rejects([feature(p: {'MAX_NETWORK': null})], 'properties.MAX_NETWORK');
  });

  test('reversed ranges', () {
    rejects([feature(p: {'START_SLK': 5.0, 'END_SLK': 1.0})],
        'properties.END_SLK');
    rejects([feature(p: {'START_TRUE_DIST': 5.0, 'END_TRUE_DIST': 1.0})],
        'properties.END_TRUE_DIST');
  });

  test('geometry problems', () {
    rejects([feature(geometry: null)], 'geometry');
    rejects([feature(geometry: {'type': 'Point', 'coordinates': [1, 2]})],
        'geometry.type');
    rejects([
      feature(geometry: {
        'type': 'MultiLineString',
        'coordinates': [
          [
            [115.8, -31.9],
            [115.9, -32.0]
          ]
        ]
      })
    ], 'geometry.type');
    rejects([
      feature(geometry: line([
        [115.8, -31.9]
      ]))
    ], 'geometry.coordinates');
    rejects([
      feature(geometry: line([
        [115.8, -31.9],
        [115.9]
      ]))
    ], 'geometry.coordinates[1]');
    rejects([
      feature(geometry: line([
        [115.8, -31.9],
        ['x', -32.0]
      ]))
    ], 'geometry.coordinates[1]');
    rejects([
      feature(geometry: line([
        [115.8, -31.9],
        [double.nan, -32.0]
      ]))
    ], 'geometry.coordinates[1]');
    rejects([
      feature(geometry: line([
        [115.8, -91.0],
        [115.9, -32.0]
      ]))
    ], 'geometry.coordinates[0]');
    rejects([
      feature(geometry: line([
        [115.8, -31.9],
        [181.0, -32.0]
      ]))
    ], 'geometry.coordinates[1]');
  });

  test('malformed properties and collection', () {
    rejects([feature(properties: 'nope')], 'properties');
    expect(() => parser.parseFeatureCollection({'type': 'Feature'}),
        throwsA(isA<MainRoadsParseException>()));
    expect(
        () => parser.parseFeatureCollection(
            {'type': 'FeatureCollection', 'features': 'x'}),
        throwsA(isA<MainRoadsParseException>()));
    expect(() => parse(['not a map']), throwsA(isA<MainRoadsParseException>()));
  });
}
