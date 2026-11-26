import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:roads_map/models/menu_assets_notifier.riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/widgets/feature_display/feature_display_providers.dart';
import 'package:roads_map/widgets/feature_display/feature_tapped_display.dart';
import 'package:roads_map/widgets/feature_menu/points_of_interest_menu.dart';
import 'package:roads_map/widgets/feature_menu/road_networks_menu.dart';
import 'package:roads_map/widgets/location_search_widget.dart';
import 'package:roads_map/widgets/navigation_widget/content_measurement_widget.dart';
import 'package:roads_map/widgets/navigation_widget/navigation_widget.dart';
import 'package:roads_map/widgets/navigation_widget/sliding_box_widget.dart';
import 'package:roads_map/widgets/settings_page.dart';

final activeTabIndexProvider = StateProvider<int>((ref) => 0);

class SheetBodyWidget extends ConsumerStatefulWidget {
  const SheetBodyWidget({
    super.key,
  });

  @override
  ConsumerState<SheetBodyWidget> createState() => _SheetBodyWidgetState();
}

class _SheetBodyWidgetState extends ConsumerState<SheetBodyWidget> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  BoxController get boxController => ref.read(boxControllerProvider);
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabChange);

    // Set initial state based on current selectedIndex
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentSelectedIndex = ref.read(selectedIndexProvider);
      if (currentSelectedIndex == 1) {
        _tabController!.index = 0; // Road Networks tab
        ref.read(activeTabIndexProvider.notifier).state = 0;
      } else if (currentSelectedIndex == 2) {
        _tabController!.index = 1; // POI tab
        ref.read(activeTabIndexProvider.notifier).state = 1;
      }
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController!.indexIsChanging) {
      final newTabIndex = _tabController!.index;
      ref.read(activeTabIndexProvider.notifier).state = newTabIndex;
      // Update selectedIndex to match tab selection (1 for Road Networks, 2 for POI)
      ref.read(selectedIndexProvider.notifier).state = newTabIndex + 1;
      debugPrint('Tab changed to index: $newTabIndex, selectedIndex updated to: ${newTabIndex + 1}');
    }
  }

  @override
  void didUpdateWidget(SheetBodyWidget oldWidget) {
    super.didUpdateWidget(oldWidget); // Check for feature taps
    final tappedFeature = ref.read(featureTapStateProvider);
    if (tappedFeature != null) {
      // Reduced logging - only log unique feature taps
      if (oldWidget.hashCode != hashCode) {
        debugPrint('SheetBodyWidget updated with tapped feature: ${tappedFeature.layerId}');
      }

      // Ensure the feature details view is shown
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(showFeatureDetailsProvider.notifier).state = true;
        ref.read(selectedIndexProvider.notifier).state = 3;
        // Reduced logging frequency
      });
    }

    // Sync tab controller with selectedIndex changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedIndex = ref.read(selectedIndexProvider);
      if (_tabController != null && !_tabController!.indexIsChanging) {
        if (selectedIndex == 1 && _tabController!.index != 0) {
          _tabController!.index = 0; // Road Networks tab
        } else if (selectedIndex == 2 && _tabController!.index != 1) {
          _tabController!.index = 1; // POI tab
        }
      }
    });
  }

  // Helper method to handle feature taps properly
  void _handleFeatureTapDisplay(TappedFeature? feature) {
    if (feature != null) {
      debugPrint('Handling feature tap display for feature: ${feature.layerId}');

      // First, make sure the feature details flag is enabled
      ref.read(showFeatureDetailsProvider.notifier).state = true;

      // Then update the selected index to show the feature view
      ref.read(selectedIndexProvider.notifier).state = 3;

      // Ensure the box is open
      // final boxController = ref.read(boxControllerProvider);
      if (boxController.isBoxClosed) {
        boxController.openBox();
      }

      debugPrint('State updated: showFeatureDetails=true, selectedIndex=3, box opened');
    }
  }

  // Helper method to build the tab-based navigation view
  Widget _buildTabView(AsyncValue<dynamic> menuAssets, double dynamicMaxHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Road Networks"),
            Tab(text: "Points of Interest"),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        SizedBox(
          height: dynamicMaxHeight * 0.82,
          child: ContentMeasurementWidget(
            debugName: 'TabBarView',
            child: TabBarView(
              controller: _tabController,
              children: [
                // Road Networks tab
                menuAssets.when(
                  data: (assets) => RoadNetworksMenu(
                    menuAssets: assets,
                    showOnlyDownloaded: !ref.watch(showAllLayersProvider),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error loading networks: $error'),
                  ),
                ),
                // Points of Interest tab
                menuAssets.when(
                  data: (assets) => PointsOfInterestMenu(
                    menuAssets: assets,
                    showOnlyDownloaded: !ref.watch(showAllLayersProvider),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error loading POIs: $error'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  // Helper method to build feature details view
  Widget _buildFeatureDetailsView(double dynamicMaxHeight) {
    return SizedBox(
      height: dynamicMaxHeight * 0.8,
      child: ContentMeasurementWidget(
        debugName: 'FeatureTappedDisplay',
        child: const Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: FeatureTappedDisplay(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build settings view
  Widget _buildSettingsView(double dynamicMaxHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          height: dynamicMaxHeight * 0.80,
          child: ContentMeasurementWidget(
            debugName: 'SettingsContent',
            child: Column(
              children: [
                const Expanded(
                  child: SingleChildScrollView(
                    child: SettingsContent(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('Close pressed in settings');
                      boxController.closeBox();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build location search view
  Widget _buildLocationSearchView(double dynamicMaxHeight, bool isActive) {
    return SizedBox(
      height: dynamicMaxHeight * 0.85,
      child: ContentMeasurementWidget(
        debugName: 'LocationSearchWidget',
        child: Column(
          children: [
            Expanded(
              child: LocationSearchWidget(shouldRequestFocus: isActive),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to determine which view index to show
  int _getViewIndex(int selectedIndex, bool hasFeatureTapped, bool showFeatureDetails) {
    // Priority order: Feature details > Settings > Location search > Tab view
    if (hasFeatureTapped && showFeatureDetails) return 0;
    if (selectedIndex == 4) return 1; // Settings
    if (selectedIndex == 5) return 2; // Location search
    return 3; // Tab view (default for selectedIndex 1 and 2)
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final tappedFeature = ref.watch(featureTapStateProvider);
    final showFeatureDetails = ref.watch(showFeatureDetailsProvider);
    final menuAssets = ref.watch(menuAssetsNotifierProvider);

    // Handle feature tap logic
    if (tappedFeature != null && selectedIndex != 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(selectedIndexProvider.notifier).mounted) {
          _handleFeatureTapDisplay(tappedFeature);
        }
      });
    }

    final viewportHeight = MediaQuery.of(context).size.height;
    final maxHeight = viewportHeight * 0.65;

    // Reduced logging frequency - only log state changes
    // debugPrint('SheetBodyWidget.build: selectedIndex=$selectedIndex, tappedFeature=${tappedFeature != null}');
    // debugPrint('Dynamic max height: $dynamicMaxHeight');

    if (tappedFeature != null) {
      // Only log feature details when debugging is needed
      // debugPrint('Tapped feature details: layerId=${tappedFeature.layerId}, properties=${tappedFeature.properties}');
      // debugPrint('showFeatureDetails=${ref.read(showFeatureDetailsProvider)}');
    }

    final currentViewIndex = _getViewIndex(selectedIndex, tappedFeature != null, showFeatureDetails);
    return IndexedStack(
      index: currentViewIndex,
      children: [
        // Index 0: Feature details view
        _buildFeatureDetailsView(maxHeight),

        // Index 1: Settings view
        _buildSettingsView(maxHeight),

        // Index 2: Location search view
        _buildLocationSearchView(maxHeight, currentViewIndex == 2),

        // Index 3: Tab view (Road Networks & POI)
        _buildTabView(menuAssets, maxHeight),
      ],
    );
  }
}
