// Splash screen state management
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/initialization_provider.dart';
import 'package:roads_map/models/menu_assets_notifier.riverpod.dart';
import 'package:roads_map/providers/map_page_notifier.riverpod.dart';

enum SplashState {
  initializing,
  loadingMenuAssets,
  loadingMapTheme,
  loadingMapLayers,
  completed,
}

// Provider that automatically determines splash state based on other providers
final splashScreenProvider = Provider<SplashState>((ref) {
  // Watch the initialization provider
  final initialization = ref.watch(initializationProvider);

  return initialization.when(
    loading: () {
      debugPrint('🚀 Splash: Initializing...');
      return SplashState.initializing;
    },
    error: (error, stack) => SplashState.initializing,
    data: (_) {
      // Watch menu assets
      final menuAssets = ref.watch(menuAssetsNotifierProvider);

      return menuAssets.when(
        loading: () {
          debugPrint('🚀 Splash: Loading menu assets...');
          return SplashState.loadingMenuAssets;
        },
        error: (error, stack) => SplashState.loadingMenuAssets,
        data: (_) {
          // Watch map state
          final mapState = ref.watch(mapPageNotifierProvider);

          // Complete splash once map theme is loaded
          // The map layers will load after the main app is displayed
          if (mapState.currentStyleUrl.isNotEmpty) {
            debugPrint('🚀 Splash: Map theme loaded - COMPLETED!');
            return SplashState.completed;
          } else {
            debugPrint('🚀 Splash: Loading map theme...');
            return SplashState.loadingMapTheme;
          }
        },
      );
    },
  );
});
