import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roads_map/models/layer_sublayer.riverpod.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';
import 'package:roads_map/models/menu_assets_notifier.riverpod.dart';
import 'package:roads_map/utils/marker_utilities.riverpod.dart';

final initializationProvider = FutureProvider<void>((ref) async {
  if (kDebugMode) {
    debugPrint('---Initialization Provider...');
    debugPrint('---Initializing Hive...');
    debugPrint('Registering Hive adapters...');
  } // Register only the required adapters for MenuAssets
  Hive.registerAdapter(MenuAssetsAdapter());
  Hive.registerAdapter(LayerAdapter());
  Hive.registerAdapter(GroupMemberAdapter());
  Hive.registerAdapter(SubLayerAdapter());
  Hive.registerAdapter(LayerSubLayerAdapter());
  Hive.registerAdapter(Uint8ListAdapter());

  if (kDebugMode) {
    debugPrint('Hive adapters registered successfully');
    debugPrint('Opening Hive boxes...');
  }
  await Hive.openBox("layersBox");
  await Hive.openBox("settingsBox");
  await Hive.openBox("showAllLayersBox");
  await Hive.openBox("selectedPoiLayerBox");
  await Hive.openBox("selectedLayerBox");
  await Hive.openBox<Uint8List>("marker_images");
  if (kDebugMode) {
    debugPrint('Hive boxes opened successfully');
    debugPrint('Hive initialization complete');
  }
  if (kDebugMode) {
    debugPrint('---Initializing MenuAssets Notifier...');
  }

  final menuAssets = await ref.read(menuAssetsNotifierProvider.future);
  if (kDebugMode) {
    debugPrint('MenuAssets loaded: ${menuAssets.mapName} (v${menuAssets.menuVersion})');
  }
  if (kDebugMode) {
    debugPrint('MenuAssets Notifier initialized successfully');
    debugPrint('---Initialization Provider Completed...\n');
  }
});
