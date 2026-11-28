import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roads_map/hive_boxes.dart';
import 'package:roads_map/hive_registrar.g.dart';
import 'package:roads_map/models/menu_assets_notifier.riverpod.dart';
import 'package:roads_map/utils/marker_utilities.riverpod.dart';

final initializationProvider = FutureProvider<void>((ref) async {
  if (kDebugMode) {
    debugPrint('---Initialization Provider...');
    debugPrint('---Initializing Hive...');
    debugPrint('Registering Hive adapters...');
  } // Register only the required adapters for MenuAssets
  Hive.registerAdapters();
  // Not part of the generated registrar.
  Hive.registerAdapter(Uint8ListAdapter());

  if (kDebugMode) {
    debugPrint('Hive adapters registered successfully');
    debugPrint('Opening Hive boxes...');
  }
  for (final name in HiveBoxes.requiredAtStartup) {
    if (name == HiveBoxes.markerImages) {
      await Hive.openBox<Uint8List>(name);
    } else {
      await Hive.openBox(name);
    }
  }
  if (kDebugMode) {
    debugPrint('Hive boxes opened successfully');
    debugPrint('Hive initialization complete');
  }
  if (kDebugMode) {
    debugPrint('---Initializing MenuAssets Notifier...');
  }

  final menuAssets = await ref.read(menuAssetsNotifierProvider.future);
  if (kDebugMode) {
    debugPrint(
        'MenuAssets loaded: ${menuAssets.mapName} (v${menuAssets.menuVersion})');
  }
  if (kDebugMode) {
    debugPrint('MenuAssets Notifier initialized successfully');
    debugPrint('---Initialization Provider Completed...\n');
  }
});
