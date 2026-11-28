import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/models/menu_assets.riverpod.dart';

/// Provider for managing selected filters in the layer menu
final selectedFiltersNotifierProvider =
    StateNotifierProvider<SelectedFiltersNotifier, Set<Filter>>((ref) {
  return SelectedFiltersNotifier();
});

/// Notifier for managing selected filters
class SelectedFiltersNotifier extends StateNotifier<Set<Filter>> {
  SelectedFiltersNotifier() : super({});

  void toggleFilter(Filter filter, bool isSelected) {
    if (isSelected) {
      state = {...state, filter};
    } else {
      state = {...state}..remove(filter);
    }
  }

  void clearFilters() {
    state = {};
  }

  void selectFilters(Set<Filter> filters) {
    state = filters;
  }
}
