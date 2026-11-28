import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/widgets/feature_display/feature_display_providers.dart';
import 'package:roads_map/widgets/navigation_widget/navigation_widget.dart';

/// A widget that measures its child's dimensions and updates the contentHeightProvider
class ContentMeasurementWidget extends ConsumerStatefulWidget {
  final Widget child;
  final String debugName;

  const ContentMeasurementWidget({
    super.key,
    required this.child,
    required this.debugName,
  });

  @override
  ConsumerState<ContentMeasurementWidget> createState() =>
      _ContentMeasurementWidgetState();
}

class _ContentMeasurementWidgetState
    extends ConsumerState<ContentMeasurementWidget> {
  final GlobalKey _measureKey = GlobalKey();
  double? _lastMeasuredHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureContent();
    });
  }

  @override
  void didUpdateWidget(ContentMeasurementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-measure whenever the widget updates (content might have changed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureContent();
    });
  }

  void _measureContent() {
    final renderBox =
        _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      final contentHeight = size
          .height; // Only update if the height has actually changed to avoid unnecessary rebuilds
      if (_lastMeasuredHeight != contentHeight && contentHeight > 0) {
        _lastMeasuredHeight = contentHeight;
        // Reduced logging - only log significant height changes (> 5px difference)
        if (_lastMeasuredHeight == null ||
            (contentHeight - _lastMeasuredHeight!).abs() > 5) {
          debugPrint(
              '📏 ContentMeasurement for ${widget.debugName}: height=$contentHeight');
        }

        // Update the provider with the measured height
        ref.read(contentHeightProvider.notifier).state = contentHeight;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureContent();
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        key: _measureKey,
        child: widget.child,
      ),
    );
  }
}

/// Provider to calculate dynamic heights based on selected index and content size
/// This provider can be used by both NavigationWidget and SheetBodyWidget
final dynamicHeightProvider =
    Provider.family<double, double>((ref, screenHeight) {
  final selectedIndex = ref.watch(selectedIndexProvider);
  final tappedFeature = ref.watch(featureTapStateProvider);
  final showFeatureDetails = ref.watch(showFeatureDetailsProvider);
  final contentHeight = ref.watch(contentHeightProvider);

  // Maximum height is 65% of screen height
  final maxHeight = screenHeight * 0.65;

  // Base heights for different content types (including TabBar, buttons, and padding)
  const baseHeight = 120.0; // TabBar + buttons + padding
  const featureDetailsBaseHeight = 80.0; // Close button + padding
  const settingsBaseHeight = 80.0; // Header + close button + padding
  const searchBaseHeight = 60.0; // Close button + padding

  double calculatedHeight;
  // Handle feature details display first
  if (tappedFeature != null && showFeatureDetails) {
    calculatedHeight = contentHeight + featureDetailsBaseHeight;
    // Reduced logging frequency for dynamic height calculations
  } else {
    switch (selectedIndex) {
      case 0:
        // Map Navigation
        calculatedHeight = maxHeight;
        break;
      case 1:
      case 2:
        // Road Networks or Points of Interest (TabBar view)
        calculatedHeight = contentHeight + baseHeight;
        break;
      case 3:
        // Feature Details (fallback)
        calculatedHeight = contentHeight + featureDetailsBaseHeight;
        break;
      case 4:
        // Settings
        calculatedHeight = contentHeight + settingsBaseHeight;
        break;
      case 5:
        // Location Search
        calculatedHeight = contentHeight + searchBaseHeight;
        break;
      default:
        calculatedHeight = maxHeight;
        break;
    }
  }
  // Return the minimum of maxHeight or calculated height, but ensure minimum usable height
  final minUsableHeight = screenHeight * 0.25; // Minimum 25% of screen
  final finalHeight = (calculatedHeight > 0 && calculatedHeight < maxHeight)
      ? calculatedHeight.clamp(minUsableHeight, maxHeight)
      : maxHeight;

  // Only log when there are significant changes or errors
  if (finalHeight != calculatedHeight || calculatedHeight <= 0) {
    debugPrint(
        'Final dynamic height: $finalHeight (max: $maxHeight, calculated: $calculatedHeight)');
  }
  return finalHeight;
});

/// Provider for screen height - can be used across widgets for consistent calculations
final screenHeightProvider = Provider<double>((ref) {
  // This provider needs to be watched within a widget build context to get actual screen height
  // It's mainly used as a helper for other providers that need screen dimensions
  return 0.0; // Placeholder - actual height should be provided via family provider
});

// DYNAMIC HEIGHT PROVIDER USAGE:
//
// The dynamicHeightProvider is a family provider that calculates appropriate heights
// based on the current active tab index. Usage examples:
//
// In any widget's build method:
// ```dart
// Widget build(BuildContext context, WidgetRef ref) {
//   final screenHeight = MediaQuery.of(context).size.height;
//   final dynamicHeight = ref.watch(dynamicHeightProvider(screenHeight));
//
//   return Container(
//     height: dynamicHeight,
//     child: YourContent(),
//   );
// }
// ```
//
// The provider automatically reacts to changes in activeTabIndexProvider,
// so both NavigationWidget and SheetBodyWidget stay in sync.
