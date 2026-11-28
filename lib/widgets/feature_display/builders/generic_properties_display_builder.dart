import 'package:material_ui/material_ui.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';

import '../feature_display_helpers.dart';

/// Generic properties display builder
class GenericPropertiesDisplayBuilder {
  /// Build generic properties display for unknown feature types
  static Widget buildGenericPropertiesDisplay(
      BuildContext context, TappedFeature feature, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Properties',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...feature.properties.entries
            .where((entry) =>
                entry.value != null && entry.value.toString().isNotEmpty)
            .map((entry) => FeatureDisplayHelpers.buildProperty(
                context, entry.key, entry.value)),
      ],
    );
  }
}
