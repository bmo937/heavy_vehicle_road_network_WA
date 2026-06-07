import 'package:flutter/material.dart';
import 'package:flutter_decorated_container/flutter_decorated_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/divider.riverpod.dart';
import 'package:roads_map/widgets/feature_display/feature_display_helpers.dart';

/// Intersection display builder
class IntersectionDisplayBuilder {
  /// Build intersection display
  static Widget buildIntersectionDisplay(BuildContext context, TappedFeature feature, String title) {
    final Map<String, dynamic> properties = feature.properties;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer(builder: (context, ref, child) {
      final customDivider = ref.watch(dividerProvider);
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6, // Constrain height to 60% of screen
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fixed Header Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FeatureDisplayHelpers.buildSubTitle(context, properties['NODE_DESCR'] ?? properties['NAME']),
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (properties['NETWORK'] != null || properties['CONDITION'] != null) customDivider,

            // Scrollable Content Section
            if (properties['NETWORK'] != null || properties['CONDITION'] != null)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      // Network and Condition Information
                      Text('Condition', style: textTheme.bodyMedium),
                      if (properties['CONDITION'] != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            elevation: 10,
                            child: DecoratedContainer(
                              strokeColor: colorScheme.onErrorContainer,
                              strokeWidth: 2,
                              backgroundColor: colorScheme.errorContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  properties['CONDITION'].toString(),
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onError),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Add more content here as needed
                      const SizedBox(height: 16), // Bottom padding
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
