// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_selection_provider.riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$poiLayerSelectionHash() => r'a37c8d2de6e3a1f1cddd8e153710f9010bfbf649';

/// Provider to track POI layer selections using Riverpod annotation
///
/// Copied from [PoiLayerSelection].
@ProviderFor(PoiLayerSelection)
final poiLayerSelectionProvider =
    AutoDisposeNotifierProvider<PoiLayerSelection, Map<String, bool>>.internal(
  PoiLayerSelection.new,
  name: r'poiLayerSelectionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$poiLayerSelectionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PoiLayerSelection = AutoDisposeNotifier<Map<String, bool>>;
String _$networkLayerSelectionHash() =>
    r'76d5667644f964b812772146ac9ecb8636b164cd';

/// Provider to track network layer selection using Riverpod annotation
///
/// Copied from [NetworkLayerSelection].
@ProviderFor(NetworkLayerSelection)
final networkLayerSelectionProvider =
    AutoDisposeNotifierProvider<NetworkLayerSelection, String?>.internal(
  NetworkLayerSelection.new,
  name: r'networkLayerSelectionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkLayerSelectionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NetworkLayerSelection = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
