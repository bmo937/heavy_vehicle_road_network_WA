import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:roads_map/models/place_search_result.dart';
import 'package:roads_map/providers/location_search_providers.dart';
import 'package:roads_map/providers/map_controller_manager.dart';
import 'package:roads_map/providers/settings_notifier.riverpod.dart';
import 'package:roads_map/services/google_places_service.riverpod.dart';

/// Service class to handle location search business logic
class LocationSearchService {
  LocationSearchService(this.ref, this.placesService);

  final WidgetRef ref;
  final GooglePlacesService placesService;

  /// Performs search and updates the search results provider
  Future<void> performSearch(String query, BuildContext context) async {
    ref.read(searchLoadingProvider.notifier).state = true;

    try {
      final predictions = await placesService.getAutocompletePredictions(query);
      final results = <PlaceSearchResult>[];

      // Convert predictions to PlaceSearchResult objects and get their coordinates
      for (final prediction in predictions) {
        final result = PlaceSearchResult.fromPrediction(prediction);

        try {
          // Get place details to calculate actual distance
          final placeDetails =
              await placesService.getPlaceDetails(result.placeId);
          final geometry = placeDetails['geometry'];
          final location = geometry?['location'];

          if (location != null) {
            final lat = location['lat']?.toDouble();
            final lng = location['lng']?.toDouble();

            if (lat != null && lng != null) {
              final latLng = LatLng(lat, lng);
              final distance = placesService.calculateDistance(
                -31.9505, 115.8605, // Perth coordinates
                lat, lng,
              );

              final updatedResult = result.copyWith(
                location: latLng,
                distanceFromPerth: distance,
              );
              results.add(updatedResult);
            } else {
              // Add without distance if coordinates unavailable
              results.add(result);
            }
          } else {
            // Add without distance if geometry unavailable
            results.add(result);
          }
        } catch (e) {
          debugPrint('Error getting details for ${result.placeId}: $e');
          // Add without distance if details fetch fails
          results.add(result);
        }
      }

      // Sort by distance (closest first)
      results.sort((a, b) {
        final distanceA = a.distanceFromPerth ?? double.maxFinite;
        final distanceB = b.distanceFromPerth ?? double.maxFinite;
        return distanceA.compareTo(distanceB);
      });

      ref.read(searchResultsProvider.notifier).state = results;
    } catch (e) {
      debugPrint('Error performing search: $e');
      ref.read(searchResultsProvider.notifier).state = [];

      // Show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching locations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(searchLoadingProvider.notifier).state = false;
    }
  }

  /// Handles place selection and marker creation
  Future<void> onPlaceSelected(
      PlaceSearchResult result, BuildContext context) async {
    try {
      LatLng? latLng = result.location;
      PlaceSearchResult updatedResult = result;

      // Always fetch place details to get additional information
      final placeDetails = await placesService.getPlaceDetails(result.placeId);
      final geometry = placeDetails['geometry'];
      final location = geometry?['location'];

      // Extract coordinates if not already available
      if (latLng == null && location != null) {
        final lat = location['lat']?.toDouble();
        final lng = location['lng']?.toDouble();

        if (lat != null && lng != null) {
          latLng = LatLng(lat, lng);
        }
      }

      // Calculate distance if coordinates are available
      double? distance = result.distanceFromPerth;
      if (latLng != null && distance == null) {
        distance = placesService.calculateDistance(
          -31.9505, 115.8605, // Perth coordinates
          latLng.latitude, latLng.longitude,
        );
      }

      // Create updated result with place details
      updatedResult = result.copyWith(
        location: latLng,
        distanceFromPerth: distance,
        formattedAddress: placeDetails['formatted_address'],
        formattedPhoneNumber: placeDetails['formatted_phone_number'],
        internationalPhoneNumber: placeDetails['international_phone_number'],
        website: placeDetails['website'],
        types: (placeDetails['types'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        rating: placeDetails['rating']?.toDouble(),
        priceLevel: placeDetails['price_level'],
        addressComponents: placeDetails['address_components'] is List
            ? {'components': placeDetails['address_components']}
            : placeDetails['address_components'] as Map<String, dynamic>?,
        openingHours: placeDetails['opening_hours'] as Map<String, dynamic>?,
        photos: (placeDetails['photos'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList(),
      );

      // Update selected place
      ref.read(selectedPlaceProvider.notifier).state = updatedResult;

      // Add marker to map if coordinates are available
      if (latLng != null) {
        final mapController = ref.read(mapControllerProvider);
        if (mapController != null) {
          await _addLocationMarker(mapController, latLng,
              updatedResult); // Move camera to the location
          await mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: latLng,
                zoom: 15.0,
              ),
            ),
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Location found: ${result.mainText ?? result.description}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Adds a location marker to the map
  Future<void> _addLocationMarker(MapLibreMapController controller,
      LatLng location, PlaceSearchResult placeResult) async {
    try {
      // Get the selected marker color from settings
      final markerColor = ref.read(markerColorNotifierProvider);
      final colorHex =
          '#${markerColor.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

      // Remove any existing search markers
      try {
        await controller.removeLayer('search-marker-layer');
        await controller.removeSource('search-marker-source');
      } catch (e) {
        // Ignore if layer/source doesn't exist
      }

      // Add a new marker for the search result
      await controller.addGeoJsonSource(
        'search-marker-source',
        {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [location.longitude, location.latitude],
              },
              'properties': {
                // Core identification
                'place_id': placeResult.placeId,
                'title': placeResult.mainText ?? placeResult.description,
                'description': placeResult.description,
                'place_name': placeResult.description,
                'name': placeResult.mainText ?? placeResult.description,

                // Structured address components
                'main_text': placeResult.mainText ?? '',
                'secondary_text': placeResult.secondaryText ?? '',
                'primary_name': placeResult.mainText ?? placeResult.description,
                'address': placeResult.secondaryText ?? '',
                'full_address': placeResult.description,
                'formatted_address': placeResult.formattedAddress ?? '',
                'vicinity': placeResult.secondaryText ?? '',

                // Location information
                'coordinates': '${location.latitude}, ${location.longitude}',
                'latitude': location.latitude,
                'longitude': location.longitude,

                // Contact information
                'phone': placeResult.internationalPhoneNumber ?? '',
                'formatted_phone_number':
                    placeResult.internationalPhoneNumber ?? '',
                'international_phone_number':
                    placeResult.internationalPhoneNumber ?? '',
                'website': placeResult.website ?? '',

                // Business information
                'business_status':
                    'OPERATIONAL', // Default, could be extracted from place details if available
                'rating': placeResult.rating ?? 0,
                'user_ratings_total':
                    0, // Could be extracted from place details if available
                'price_level': placeResult.priceLevel ?? 0,

                // Place types
                'types': placeResult.types?.join(', ') ?? '',
                'establishment_type':
                    placeResult.types?.first ?? 'establishment',

                // Address components - extract key components for easy access
                'street_number': _extractAddressComponent(
                    placeResult.addressComponents, 'street_number'),
                'route': _extractAddressComponent(
                    placeResult.addressComponents, 'route'),
                'locality': _extractAddressComponent(
                    placeResult.addressComponents, 'locality'),
                'administrative_area_level_1': _extractAddressComponent(
                    placeResult.addressComponents,
                    'administrative_area_level_1'),
                'administrative_area_level_2': _extractAddressComponent(
                    placeResult.addressComponents,
                    'administrative_area_level_2'),
                'country': _extractAddressComponent(
                    placeResult.addressComponents, 'country'),
                'postal_code': _extractAddressComponent(
                    placeResult.addressComponents, 'postal_code'),

                // Address components (as JSON string for full access)
                'address_components': placeResult.addressComponents != null
                    ? placeResult.addressComponents.toString()
                    : '',

                // Opening hours information
                'opening_hours': placeResult.openingHours != null
                    ? placeResult.openingHours.toString()
                    : '',
                'is_open_now': placeResult.openingHours?['open_now'] ?? false,

                // Photos and media
                'photo_reference': placeResult.photos?.isNotEmpty == true
                    ? placeResult.photos![0]['photo_reference'] ?? ''
                    : '',
                'icon': '', // Could be set from place details if available
                'icon_background_color': '#7B9EB0', // Default color

                // Visual properties
                'marker_color': colorHex,
                'marker_type': 'search_result',

                // Additional metadata
                'search_timestamp': DateTime.now().toIso8601String(),
                'source': 'google_places',
                'reference': placeResult.placeId,
                'url': 'https://maps.google.com/?cid=${placeResult.placeId}',
              },
            },
          ],
        },
      );

      await controller.addLayer(
        'search-marker-source',
        'search-marker-layer',
        CircleLayerProperties(
          circleRadius: [
            'interpolate',
            ['linear'],
            ['zoom'],
            5,
            2,
            10,
            5,
            15,
            7,
            20,
            10
          ],
          circleColor: colorHex,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
    } catch (e) {
      debugPrint('Error adding location marker: $e');
    }
  }

  /// Helper method to extract specific address component types
  String _extractAddressComponent(
      Map<String, dynamic>? addressComponents, String type) {
    if (addressComponents == null) return '';

    try {
      // Handle both direct list format and wrapped format
      List<dynamic>? components;
      if (addressComponents['components'] is List) {
        components = addressComponents['components'] as List<dynamic>;
      } else if (addressComponents is List) {
        components = addressComponents as List<dynamic>;
      }

      if (components == null) return '';

      for (final component in components) {
        if (component is Map<String, dynamic>) {
          final types = component['types'] as List<dynamic>?;
          if (types != null && types.contains(type)) {
            return component['long_name']?.toString() ??
                component['short_name']?.toString() ??
                '';
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting address component $type: $e');
    }

    return '';
  }
}
