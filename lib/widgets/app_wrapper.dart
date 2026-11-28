// App wrapper that manages splash screen and main app transition
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roads_map/providers/map_page_notifier.riverpod.dart';
import 'package:roads_map/widgets/navigation_widget/navigation_widget.dart';
import 'package:roads_map/widgets/splash_screen.dart';

class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _splashFadeController;
  late Animation<double> _splashFadeAnimation;
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();

    _splashFadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _splashFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _splashFadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _splashFadeController.dispose();
    super.dispose();
  }

  void _hideSplashScreen() {
    if (!_splashRemoved) {
      debugPrint('🎉 Hiding splash screen - map is fully loaded!');

      // Add a small delay to show "Ready to roll!" message
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _splashFadeController.forward().then((_) {
            if (mounted) {
              setState(() {
                _splashRemoved = true;
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the map state to know when layers are fully loaded
    final mapState = ref.watch(mapPageNotifierProvider);

    // Hide splash when map is fully loaded
    if (mapState.isMapFullyLoaded && !_splashRemoved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hideSplashScreen();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main app - always present, loading in background
          const NavigationWidget(),

          // Splash screen overlay - fades out when map is ready
          if (!_splashRemoved)
            AnimatedBuilder(
              animation: _splashFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _splashFadeAnimation.value,
                  child: const SplashScreen(),
                );
              },
            ),
        ],
      ),
    );
  }
}
