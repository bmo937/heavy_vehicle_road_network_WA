import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// This will generate the code for the provider
part 'icons.riverpod.g.dart';

/// AppSvgIcon class provides a centralized way to access and use SVG icons
/// throughout the application
@riverpod
class AppSvgIcon extends _$AppSvgIcon {
  @override
  Map<String, String> build() {
    // This is a map of icon names to their SVG asset paths
    // You can add more icons as needed
    return {
      'location': 'assets/icons/location.svg',
      'truck': 'assets/icons/truck.svg',
      'layers': 'assets/icons/layers.svg',
      'emergency': 'assets/icons/emergency_home.svg',
      'wa': 'assets/icons/western_australia.svg',
      // Add more icons as needed
    };
  }

  /// Get the SVG asset path from the icon name
  String getIconPath(String iconName) {
    return state[iconName] ?? '';
  }

  /// Register a new icon or update an existing one
  void registerIcon(String iconName, String svgPath) {
    state = {...state, iconName: svgPath};
  }
}

/// Extension on BuildContext for easy access to SVG icons
extension SvgIconContextExtension on BuildContext {
  /// Get an SvgPicture widget for the given icon name
  SvgPicture svgIcon(
    String iconName, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
  }) {
    // Get the ProviderContainer from the BuildContext
    final container = ProviderScope.containerOf(this);
    final iconPath = container.read(appSvgIconProvider)[iconName] ?? '';

    if (iconPath.isEmpty) {
      throw Exception('Icon $iconName not found in AppSvgIcon registry');
    }

    return SvgPicture.asset(
      iconPath,
      width: width,
      height: height,
      colorFilter:
          color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      fit: fit,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
}

/// A widget for displaying SVG icons with a simpler API
class SvgIconWidget extends ConsumerWidget {
  final String iconName;
  final double? size;
  final Color? color;
  final BoxFit fit;
  final String? semanticsLabel;

  const SvgIconWidget({
    super.key,
    required this.iconName,
    this.size,
    this.color,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return context.svgIcon(
      iconName,
      width: size,
      height: size,
      color: color,
      fit: fit,
      semanticsLabel: semanticsLabel,
    );
  }
}
