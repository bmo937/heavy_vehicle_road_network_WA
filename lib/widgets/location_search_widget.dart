import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/models/place_search_result.dart';
import 'package:roads_map/providers/location_search_providers.dart';
import 'package:roads_map/services/google_places_service.riverpod.dart';
import 'package:roads_map/services/location_search_service.dart';
import 'package:roads_map/utils/app_config.dart';
import 'package:roads_map/widgets/navigation_widget/navigation_widget.dart';

/// Location search widget with autocomplete functionality
class LocationSearchWidget extends ConsumerStatefulWidget {
  final bool shouldRequestFocus;

  const LocationSearchWidget({
    super.key,
    this.shouldRequestFocus = false,
  });

  @override
  ConsumerState<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends ConsumerState<LocationSearchWidget> {
  Timer? _debounceTimer;
  final FocusNode _focusNode = FocusNode();
  late GooglePlacesService _placesService;
  late LocationSearchService _searchService;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _placesService = ref.read(googlePlacesServiceProvider(AppConfig.instance.googleApiKey));
    _searchService = LocationSearchService(ref, _placesService);
    _searchController.addListener(_onSearchChanged);

    // Only request focus if shouldRequestFocus is true
    if (widget.shouldRequestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(LocationSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Request focus when shouldRequestFocus changes from false to true
    if (widget.shouldRequestFocus && !oldWidget.shouldRequestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    ref.read(searchQueryProvider.notifier).state = query;

    // Debounce the search to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty && query.length > 2) {
        _searchService.performSearch(query, context);
      } else {
        ref.read(searchResultsProvider.notifier).state = [];
      }
    });
  }

  Future<void> _onPlaceSelected(PlaceSearchResult result) async {
    final boxController = ref.watch(boxControllerProvider);
    await _searchService.onPlaceSelected(result, context);

    // Clear search and close box
    _searchController.clear();
    ref.read(searchResultsProvider.notifier).state = [];
    boxController.closeBox();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final isLoading = ref.watch(searchLoadingProvider);
    final selectedPlace = ref.watch(selectedPlaceProvider);
    final boxController = ref.watch(boxControllerProvider);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search input field
          Row(
            children: [
              IconButton(
                onPressed: () {
                  boxController.closeBox();
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search for locations, addresses...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: isLoading
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchResultsProvider.notifier).state = [];
                                },
                              )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              )
            ],
          ),

          const SizedBox(height: 16),

          // Selected location display
          if (selectedPlace != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Location',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          selectedPlace.mainText ?? selectedPlace.description,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (selectedPlace.secondaryText != null)
                          Text(
                            selectedPlace.secondaryText!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(selectedPlaceProvider.notifier).state = null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Search results
          if (searchResults.isNotEmpty) ...[
            Text(
              'Search Results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final result = searchResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(result.mainText ?? result.description),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (result.secondaryText != null) Text(result.secondaryText!),
                          if (result.distanceFromPerth != null)
                            Text(
                              '${result.distanceFromPerth!.toStringAsFixed(1)} km from Perth',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      onTap: () => _onPlaceSelected(result),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                },
              ),
            ),
          ] else if (_searchController.text.isNotEmpty && !isLoading) ...[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey),
                  /* SizedBox(height: 16),
                  Text(
                    'Start typing to search for locations',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ), */
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
