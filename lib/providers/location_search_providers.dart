import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/models/place_search_result.dart';

/// Provider for search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search results
final searchResultsProvider =
    StateProvider<List<PlaceSearchResult>>((ref) => []);

/// Provider for loading state
final searchLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for selected place
final selectedPlaceProvider = StateProvider<PlaceSearchResult?>((ref) => null);
