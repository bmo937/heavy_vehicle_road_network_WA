import 'package:maplibre_gl/maplibre_gl.dart';

/// Model class for search results from Google Places API
class PlaceSearchResult {
  PlaceSearchResult({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
    this.location,
    this.distanceFromPerth,
    this.formattedAddress,
    this.formattedPhoneNumber,
    this.internationalPhoneNumber,
    this.website,
    this.types,
    this.rating,
    this.priceLevel,
    this.addressComponents,
    this.openingHours,
    this.photos,
  });

  factory PlaceSearchResult.fromPrediction(Map<String, dynamic> prediction) {
    return PlaceSearchResult(
      placeId: prediction['place_id'] ?? '',
      description: prediction['description'] ?? '',
      mainText: prediction['structured_formatting']?['main_text'],
      secondaryText: prediction['structured_formatting']?['secondary_text'],
    );
  }

  final Map<String, dynamic>? addressComponents;
  final String description;
  final double? distanceFromPerth;
  // Additional properties from place details
  final String? formattedAddress;
  final String? formattedPhoneNumber;
  final String? internationalPhoneNumber;
  final LatLng? location;
  final String? mainText;
  final Map<String, dynamic>? openingHours;
  final List<Map<String, dynamic>>? photos;
  final String placeId;
  final int? priceLevel;
  final double? rating;
  final String? secondaryText;
  final List<String>? types;
  final String? website;

  PlaceSearchResult copyWith({
    LatLng? location,
    double? distanceFromPerth,
    String? formattedAddress,
    String? internationalPhoneNumber,
    String? formattedPhoneNumber,
    String? website,
    List<String>? types,
    double? rating,
    int? priceLevel,
    Map<String, dynamic>? addressComponents,
    Map<String, dynamic>? openingHours,
    List<Map<String, dynamic>>? photos,
  }) {
    return PlaceSearchResult(
      placeId: placeId,
      description: description,
      mainText: mainText,
      secondaryText: secondaryText,
      location: location ?? this.location,
      distanceFromPerth: distanceFromPerth ?? this.distanceFromPerth,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      internationalPhoneNumber:
          internationalPhoneNumber ?? this.internationalPhoneNumber,
      formattedPhoneNumber: formattedPhoneNumber ?? this.formattedPhoneNumber,
      website: website ?? this.website,
      types: types ?? this.types,
      rating: rating ?? this.rating,
      priceLevel: priceLevel ?? this.priceLevel,
      addressComponents: addressComponents ?? this.addressComponents,
      openingHours: openingHours ?? this.openingHours,
      photos: photos ?? this.photos,
    );
  }
}
