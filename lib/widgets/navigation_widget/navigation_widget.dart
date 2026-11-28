// Refactored Navigation Widget that uses MenuAssets
import 'package:material_ui/material_ui.dart' hide debugPrint;
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:roads_map/models/menu_helpers.dart';
import 'package:roads_map/providers/map_page_notifier.riverpod.dart';
import 'package:roads_map/providers/network_selection_provider.riverpod.dart';
import 'package:roads_map/providers/on_feature_tapped.riverpod.dart';
import 'package:roads_map/utils/icons.riverpod.dart';
import 'package:roads_map/widgets/feature_display/feature_display_providers.dart';
import 'package:roads_map/widgets/map_page.dart';
import 'package:roads_map/widgets/navigation_widget/sheet_body_widget.dart';
import 'package:roads_map/widgets/navigation_widget/sliding_box_widget.dart';

// Create providers for the navigational state
final boxControllerProvider = Provider<BoxController>((ref) => BoxController());
final selectedIndexProvider = StateProvider<int>((ref) => 0);
final showAllLayersProvider = StateProvider<bool>((ref) => true);
final textControllerProvider =
    StateProvider<TextEditingController>((ref) => TextEditingController());
final savedSelectionsLoadedProvider = StateProvider<bool>((ref) => false);

/// Provider to track content height measurements
final contentHeightProvider = StateProvider<double>((ref) => 0.0);

class NavigationWidget extends HookConsumerWidget {
  const NavigationWidget({super.key});
  Widget buildBox(
      BoxController boxController, WidgetRef ref, BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final minHeight =
        screenHeight * 0.12; // Height for the header/collapsed state
    final maxHeight = screenHeight *
        0.65; // Stable maxHeight to prevent bounce during animation
    final textController = ref.watch(textControllerProvider);

    return SlidingBox(
      controller: boxController,
      minHeight: minHeight,
      maxHeight: maxHeight,
      color: Theme.of(context).bottomSheetTheme.backgroundColor,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      style: BoxStyle.shadow,
      collapsed: true,
      iconsVisible: true,
      draggableIcon: Icons.remove_rounded,
      closeIcon: Icons.cancel_rounded,
      draggableIconBackColor: Colors.transparent,
      animationDuration: const Duration(milliseconds: 400),
      collapsedBody: buildSheetHeader(context, ref),
      body: SheetBodyWidget(),
      onBoxSlide: (value) {
        final mapPageController =
            ref.read(mapPageNotifierProvider.notifier).mapController;
        if (mapPageController != null) {
          final availableHeight = maxHeight - minHeight;
          final pixelValue = (value * availableHeight + minHeight) / 2;

          mapPageController.updateContentInsets(
            EdgeInsets.only(bottom: pixelValue),
            true,
          );
        }
      },
      onBoxClose: () {
        // Handle sliding position if needed
        debugPrint('onBoxClose called - clearing feature and resetting state');
        ref.read(featureTapStateProvider.notifier).clearTappedFeature();
        ref.read(selectedIndexProvider.notifier).state =
            1; // Default to Road Networks tab
        ref.read(activeTabIndexProvider.notifier).state = 0;
        ref.read(showFeatureDetailsProvider.notifier).state = false;

        // If the parking menu was active (index 2), reset it
        if (ref.read(selectedIndexProvider) == 2) {
          ref.read(selectedIndexProvider.notifier).state = 1;
        }
      },
      backdrop: Backdrop(
        appBar: BackdropAppBar(
          searchBox: SearchBox(
            controller: textController,
            color: Theme.of(context).colorScheme.surface,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
            // height: maxHeight,
            body: Center(
              child: Text(
                "what?",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20),
              ),
            ),
            draggableBody: true,
          ),
        ),
        body: _buildScaffoldBody(),
        overlay: false,
        overlayOpacity: 0.1,
        moving: true,
        fading: false,
        // appBar: null,
      ),
    );
  }

  Widget buildSheetHeader(BuildContext context, WidgetRef ref) {
    // We'll use a simplified header without the activeOnlineLayer for now
    final controller = ref.watch(boxControllerProvider);

    return Consumer(builder: (context, ref, child) {
      // Watch the network layer selection to make header reactive
      final networkLayerSelection = ref.watch(networkLayerSelectionProvider);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton.filled(
                    onPressed: () {
                      ref.read(selectedIndexProvider.notifier).state = 5;
                      controller.openBox();
                      debugPrint(
                          'Search button pressed - opening location search');
                    },
                    icon: const Icon(Icons.search)),
                GestureDetector(
                    onTap: () {
                      ref.read(selectedIndexProvider.notifier).state =
                          1; // Default to Road Networks tab
                      ref.read(activeTabIndexProvider.notifier).state =
                          0; // First tab
                      controller.openBox();
                    },
                    child: Text(networkLayerSelection ?? 'Map Navigation',
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton.filled(
                    onPressed: () {
                      ref.read(selectedIndexProvider.notifier).state = 4;
                      controller.openBox();
                      debugPrint('Settings button pressed - opening settings');
                    },
                    icon: const Icon(Icons.settings_rounded)),
              ],
            ),
          ), /* 
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: customDivider,
          ),
          buttonRow(context, ref), */
        ]),
      );
    });
  }

  Widget buttonRow(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(boxControllerProvider);
    final isParkingLayerVisible = ref.watch(selectedIndexProvider);

    // In the refactored version, we've simplified the state management
    // Additional functionality will be added later

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filled(
          onPressed: () {
            // We would implement this functionality in MapPageNotifierProvider
            debugPrint(
                'Toggle incidents layer - functionality to be implemented');
          },
          icon: SvgIconWidget(
            iconName: 'emergency',
            size: 20,
            color: Colors.grey,
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
          ),
          tooltip: 'Toggle traffic incidents',
        ),
        IconButton.filled(
          onPressed: () {
            // We would implement this functionality in MapPageNotifierProvider
            debugPrint('Toggle travel layer - functionality to be implemented');
          },
          icon: Icon(
            Icons.warning_rounded,
            color: Colors.grey,
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
          ),
        ),
        IconButton.filled(
          onPressed: () {
            // We would implement this functionality in MapPageNotifierProvider
            debugPrint(
                'Toggle satellite layer - functionality to be implemented');
          },
          icon: Icon(
            Icons.satellite_rounded,
            color: Colors.grey,
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
          ),
        ),
        IconButton.filled(
          onPressed: () {
            final selectedIndex = ref.read(selectedIndexProvider);
            if (controller.isBoxClosed) {
              ref.read(selectedIndexProvider.notifier).state = 2; // POI tab
              ref.read(activeTabIndexProvider.notifier).state = 1; // Second tab
              controller.openBox();
            } else if (selectedIndex != 2) {
              ref.read(selectedIndexProvider.notifier).state = 2; // POI tab
              ref.read(activeTabIndexProvider.notifier).state = 1; // Second tab
            } else {
              controller.closeBox();
              ref.read(selectedIndexProvider.notifier).state = 0;
            }
          },
          icon: Icon(
            Icons.local_parking_rounded,
            color: isParkingLayerVisible == 2 ? Colors.blue : Colors.grey,
          ),
          style: TextButton.styleFrom(
            backgroundColor: isParkingLayerVisible == 2
                ? Colors.blue.withAlpha(51)
                : Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _buildScaffoldBody() {
    return const MapPage();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxController = ref.watch(boxControllerProvider);

    // Load saved selections once after app initialization
    final savedSelectionsLoaded = ref.watch(savedSelectionsLoadedProvider);
    if (!savedSelectionsLoaded) {
      // Load saved selections asynchronously
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          debugPrint('🔄 Loading saved POI and network selections...');
          await loadSavedSelections(ref);
          ref.read(savedSelectionsLoadedProvider.notifier).state = true;
          debugPrint('✅ Saved selections loaded successfully');
        } catch (e) {
          debugPrint('❌ Error loading saved selections: $e');
          // Still mark as loaded to avoid infinite retry
          ref.read(savedSelectionsLoadedProvider.notifier).state = true;
        }
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: buildBox(boxController, ref, context),
    );
  }
}
