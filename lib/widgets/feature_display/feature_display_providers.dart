import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider to control the visibility of feature details in the IndexedStack
final showFeatureDetailsProvider = StateProvider<bool>((ref) => false);

/// Provider for image feature identification results
final identifiedImageFeaturesProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);
