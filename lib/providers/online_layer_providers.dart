import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';

import 'map_bounds.dart';

/// Provider to track currently active online layer
final activeOnlineLayerProvider =
    StateNotifierProvider<ActiveOnlineLayerNotifier, GroupMember?>((ref) {
  return ActiveOnlineLayerNotifier();
});

class ActiveOnlineLayerNotifier extends StateNotifier<GroupMember?> {
  ActiveOnlineLayerNotifier() : super(null);

  void setActiveLayer(GroupMember? layer) {
    state = layer;
  }
}

/// Provider to track loading state
final onlineLayerLoadingProvider =
    StateNotifierProvider<OnlineLayerLoadingNotifier, bool>((ref) {
  return OnlineLayerLoadingNotifier();
});

class OnlineLayerLoadingNotifier extends StateNotifier<bool> {
  OnlineLayerLoadingNotifier() : super(false);

  void setLoading(bool loading) {
    state = loading;
  }
}

/// Provider to store last map bounds
final lastMapBoundsProvider =
    StateNotifierProvider<LastMapBoundsNotifier, MapBounds?>((ref) {
  return LastMapBoundsNotifier();
});

class LastMapBoundsNotifier extends StateNotifier<MapBounds?> {
  LastMapBoundsNotifier() : super(null);

  void setLastBounds(MapBounds bounds) {
    state = bounds;
  }

  void resetBounds() {
    state = null;
  }

  bool shouldFetchNewData(MapBounds newBounds) {
    if (state == null) return true;
    return newBounds.isDifferentEnough(state!);
  }
}
