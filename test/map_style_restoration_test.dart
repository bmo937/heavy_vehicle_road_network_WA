import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/providers/map_page_notifier.riverpod.dart';
import 'package:roads_map/providers/map_provider_state.dart';
import 'package:roads_map/providers/map_style_restoration.dart';
import 'package:roads_map/providers/network_selection_provider.riverpod.dart';

class _FakeNetworkSelection extends NetworkLayerSelection {
  @override
  String? build() => 'Network 1';
}

class _FakePoiSelection extends PoiLayerSelection {
  @override
  Map<String, bool> build() => {'Stopping Places': true};
}

MapPageNotifier _notifier() => MapPageNotifier(
    () async => const MapInitialSettings(styleUrl: 'light', isTravelLayerVisible: false, isSatelliteLayerVisible: false));

StyleRestorationStep _step(Future<bool> Function() action, {bool required = true}) => StyleRestorationStep('s', (run) => action(), required: required);

void main() {
  late MapPageNotifier n;

  setUp(() async {
    n = _notifier();
    await n.initialize();
    n.markMapAsFullyLoaded();
  });

  tearDown(() {
    if (n.mounted) n.dispose();
  });

  test('restoration start clears fully loaded; success sets it', () async {
    final gate = Completer<bool>();
    final result = n.restoreApplicationMapState([_step(() => gate.future)]);
    expect(n.isMapFullyLoaded, isFalse);
    gate.complete(true);
    expect(await result, StyleRestorationOutcome.completed);
    expect(n.isMapFullyLoaded, isTrue);
  });

  test('style change begin resets fully loaded and keeps init status', () {
    n.onStyleChangeBegan();
    expect(n.isMapFullyLoaded, isFalse);
    expect(n.state.initStatus, MapInitStatus.ready);
  });

  test('newer restoration supersedes older one', () async {
    final first = Completer<bool>();
    final second = Completer<bool>();
    final r1 = n.restoreApplicationMapState([_step(() => first.future)]);
    final r2 = n.restoreApplicationMapState([_step(() => second.future)]);

    first.complete(true);
    expect(await r1, StyleRestorationOutcome.superseded);
    expect(n.isMapFullyLoaded, isFalse);

    second.complete(true);
    expect(await r2, StyleRestorationOutcome.completed);
    expect(n.isMapFullyLoaded, isTrue);
  });

  test('style change during restoration prevents it from marking ready', () async {
    final gate = Completer<bool>();
    final r = n.restoreApplicationMapState([_step(() => gate.future)]);
    n.onStyleChangeBegan();
    gate.complete(true);
    expect(await r, StyleRestorationOutcome.superseded);
    expect(n.isMapFullyLoaded, isFalse);
  });

  test('stale run does not execute later steps', () async {
    final gate = Completer<bool>();
    var laterRan = false;
    final r = n.restoreApplicationMapState([
      _step(() => gate.future),
      _step(() async {
        laterRan = true;
        return true;
      }),
    ]);
    n.onStyleChangeBegan();
    gate.complete(true);
    await r;
    expect(laterRan, isFalse);
  });

  test('required failure or throw is not ready; optional failure is', () async {
    expect(await n.restoreApplicationMapState([_step(() async => false)]), StyleRestorationOutcome.failed);
    expect(n.isMapFullyLoaded, isFalse);

    expect(await n.restoreApplicationMapState([_step(() async => throw StateError('x'))]), StyleRestorationOutcome.failed);
    expect(n.isMapFullyLoaded, isFalse);

    final outcome = await n.restoreApplicationMapState([
      _step(() async => true),
      _step(() async => false, required: false),
    ]);
    expect(outcome, StyleRestorationOutcome.completed);
    expect(n.isMapFullyLoaded, isTrue);
  });

  test('disposal during restoration prevents late state update', () async {
    final gate = Completer<bool>();
    final r = n.restoreApplicationMapState([_step(() => gate.future)]);
    n.dispose();
    gate.complete(true);
    expect(await r, StyleRestorationOutcome.superseded);
    expect(n.mounted, isFalse);
  });

  test('style change invalidates in-flight network refresh', () {
    final ticket = n.refreshCoordinator.begin();
    expect(ticket.isCurrent, isTrue);
    n.onStyleChangeBegan();
    expect(ticket.isCurrent, isFalse);
  });

  test('network and POI selections survive style change and restoration', () async {
    final container = ProviderContainer(overrides: [
      networkLayerSelectionProvider.overrideWith(_FakeNetworkSelection.new),
      poiLayerSelectionProvider.overrideWith(_FakePoiSelection.new),
    ]);
    addTearDown(container.dispose);
    container.read(networkLayerSelectionProvider);
    container.read(poiLayerSelectionProvider);

    n.onStyleChangeBegan();
    await n.restoreApplicationMapState([_step(() async => true)]);

    expect(container.read(networkLayerSelectionProvider), 'Network 1');
    expect(container.read(poiLayerSelectionProvider), {'Stopping Places': true});
  });
}
