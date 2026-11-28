import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/providers/map_page_notifier.riverpod.dart';
import 'package:roads_map/providers/map_provider_state.dart';

MapPageNotifier _notifier(MapInitialSettingsLoader loader) =>
    MapPageNotifier(loader);

void main() {
  test('starts initialising and does no work until initialize()', () {
    var calls = 0;
    final n = _notifier(() async {
      calls++;
      return const MapInitialSettings(
          styleUrl: 's',
          isTravelLayerVisible: false,
          isSatelliteLayerVisible: false);
    });
    expect(n.state.initStatus, MapInitStatus.initialising);
    expect(n.state.currentStyleUrl, isEmpty);
    expect(calls, 0);
    n.dispose();
  });

  test(
      'successful init becomes ready with persisted settings; map not fully loaded',
      () async {
    final n = _notifier(() async => const MapInitialSettings(
        styleUrl: 'style',
        isTravelLayerVisible: true,
        isSatelliteLayerVisible: true));
    await n.initialize();
    expect(n.state.initStatus, MapInitStatus.ready);
    expect(n.state.currentStyleUrl, 'style');
    expect(n.state.isTravelLayerVisible, isTrue);
    expect(n.state.isSatelliteLayerVisible, isTrue);
    expect(n.isMapFullyLoaded, isFalse);
    n.markMapAsFullyLoaded();
    expect(n.state.isMapFullyLoaded, isTrue);
    expect(n.state.initStatus, MapInitStatus.ready);
    n.dispose();
  });

  test('failure is explicit, not ready, and hides details', () async {
    final n = _notifier(() async => throw StateError('https://secret?key=abc'));
    await n.initialize();
    expect(n.state.initStatus, MapInitStatus.failure);
    expect(n.state.currentStyleUrl, isEmpty);
    expect(n.state.initError, isNot(contains('secret')));
    n.dispose();
  });

  test('completion after disposal does not update state', () async {
    final c = Completer<MapInitialSettings>();
    final n = _notifier(() => c.future);
    final init = n.initialize();
    n.dispose();
    c.complete(const MapInitialSettings(
        styleUrl: 'late',
        isTravelLayerVisible: true,
        isSatelliteLayerVisible: true));
    await init;
    expect(n.mounted, isFalse);

    final c2 = Completer<MapInitialSettings>();
    final n2 = _notifier(() => c2.future);
    final init2 = n2.initialize();
    n2.dispose();
    c2.completeError(StateError('x'));
    await init2;
  });

  testWidgets(
      'controller-dependent calls before controller creation do not crash',
      (tester) async {
    final n = _notifier(() async => const MapInitialSettings(
        styleUrl: 's',
        isTravelLayerVisible: false,
        isSatelliteLayerVisible: false));
    late WidgetRef ref;
    late BuildContext context;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (c, r, _) {
        ref = r;
        context = c;
        return const SizedBox();
      }),
    ));
    expect(n.mapController, isNull);
    await n.handleFeatureTap(
        context, 'id', const Point(0.0, 0.0), const LatLng(0, 0), 'layer', ref);
    await n.onStyleLoaded(context, ref);
    n.dispose();
  });
}
