// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_places_service.riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$googlePlacesServiceHash() =>
    r'05010a56528fabcc810e1538c26ea11713f3e2e2';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$GooglePlacesService
    extends BuildlessAutoDisposeNotifier<GooglePlacesService> {
  late final String apiKey;

  GooglePlacesService build(
    String apiKey,
  );
}

/// See also [GooglePlacesService].
@ProviderFor(GooglePlacesService)
const googlePlacesServiceProvider = GooglePlacesServiceFamily();

/// See also [GooglePlacesService].
class GooglePlacesServiceFamily extends Family<GooglePlacesService> {
  /// See also [GooglePlacesService].
  const GooglePlacesServiceFamily();

  /// See also [GooglePlacesService].
  GooglePlacesServiceProvider call(
    String apiKey,
  ) {
    return GooglePlacesServiceProvider(
      apiKey,
    );
  }

  @override
  GooglePlacesServiceProvider getProviderOverride(
    covariant GooglePlacesServiceProvider provider,
  ) {
    return call(
      provider.apiKey,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'googlePlacesServiceProvider';
}

/// See also [GooglePlacesService].
class GooglePlacesServiceProvider extends AutoDisposeNotifierProviderImpl<
    GooglePlacesService, GooglePlacesService> {
  /// See also [GooglePlacesService].
  GooglePlacesServiceProvider(
    String apiKey,
  ) : this._internal(
          () => GooglePlacesService()..apiKey = apiKey,
          from: googlePlacesServiceProvider,
          name: r'googlePlacesServiceProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$googlePlacesServiceHash,
          dependencies: GooglePlacesServiceFamily._dependencies,
          allTransitiveDependencies:
              GooglePlacesServiceFamily._allTransitiveDependencies,
          apiKey: apiKey,
        );

  GooglePlacesServiceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.apiKey,
  }) : super.internal();

  final String apiKey;

  @override
  GooglePlacesService runNotifierBuild(
    covariant GooglePlacesService notifier,
  ) {
    return notifier.build(
      apiKey,
    );
  }

  @override
  Override overrideWith(GooglePlacesService Function() create) {
    return ProviderOverride(
      origin: this,
      override: GooglePlacesServiceProvider._internal(
        () => create()..apiKey = apiKey,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        apiKey: apiKey,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<GooglePlacesService, GooglePlacesService>
      createElement() {
    return _GooglePlacesServiceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GooglePlacesServiceProvider && other.apiKey == apiKey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, apiKey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GooglePlacesServiceRef
    on AutoDisposeNotifierProviderRef<GooglePlacesService> {
  /// The parameter `apiKey` of this provider.
  String get apiKey;
}

class _GooglePlacesServiceProviderElement
    extends AutoDisposeNotifierProviderElement<GooglePlacesService,
        GooglePlacesService> with GooglePlacesServiceRef {
  _GooglePlacesServiceProviderElement(super.provider);

  @override
  String get apiKey => (origin as GooglePlacesServiceProvider).apiKey;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
