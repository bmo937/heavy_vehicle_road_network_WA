// Beautiful splash screen for Western Australian truck drivers
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roads_map/providers/map_page_notifier.riverpod.dart';
import 'package:roads_map/providers/splash_screen_provider.dart';
import 'package:roads_map/utils/icons.riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _progressController;
  late AnimationController _truckController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _truckAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _truckController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _truckAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _truckController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      _progressController.forward();
      _truckController.repeat();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    _truckController.dispose();
    super.dispose();
  }

  String _getLoadingMessage(SplashState state) {
    switch (state) {
      case SplashState.initializing:
        return 'Starting your journey...';
      case SplashState.loadingMenuAssets:
        return 'Loading road networks...';
      case SplashState.loadingMapTheme:
        return 'Preparing your map...';
      case SplashState.loadingMapLayers:
        return 'Loading heavy vehicle routes...';
      case SplashState.completed:
        return 'Ready to roll!';
    }
  }

  double _getProgress(SplashState state) {
    switch (state) {
      case SplashState.initializing:
        return 0.25;
      case SplashState.loadingMenuAssets:
        return 0.65;
      case SplashState.loadingMapTheme:
        return 0.85;
      case SplashState.loadingMapLayers:
        return 0.95;
      case SplashState.completed:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch both splash state and map state for more accurate progress
    final splashState = ref.watch(splashScreenProvider);
    final mapState = ref.watch(mapPageNotifierProvider);

    // Determine current state and progress based on actual loading
    SplashState currentState;
    if (mapState.isMapFullyLoaded) {
      currentState = SplashState.completed;
    } else if (mapState.currentStyleUrl.isNotEmpty) {
      currentState = SplashState.loadingMapLayers;
    } else {
      currentState = splashState;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a4d66), // WA road sign blue
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _fadeAnimation,
          _scaleAnimation,
          _progressAnimation,
          _truckAnimation,
        ]),
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2AA198),
                  Color(0xFF156D65),
                  Color(0xFF084A44),

                  /* Color(0xFF1a4d66), // WA blue
                  Color(0xFF0d3a52), // Darker blue
                  Color(0xFF162b37), // Darkest */
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Western Australia branding
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            // State emblem placeholder
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: context.svgIcon(
                                  'wa',
                                  color: Colors.white,
                                  fit: BoxFit.contain,
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'WESTERN AUSTRALIAN',
                              style: GoogleFonts.overpass(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              'HEAVY VEHICLE',
                              style: GoogleFonts.overpass(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'ROAD NETWORKS',
                              style: GoogleFonts.overpass(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFffd700), // Gold
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Animated truck icon
                      AnimatedBuilder(
                        animation: _truckAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              math.sin(_truckAnimation.value * math.pi * 2) * 20,
                              0,
                            ),
                            child: Transform.rotate(
                              angle: math.sin(_truckAnimation.value * math.pi * 2) * 0.1,
                              child: Icon(
                                Icons.local_shipping,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 48), // Loading message
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _getLoadingMessage(currentState),
                          key: ValueKey(currentState),
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Progress bar
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            final progress = _getProgress(currentState) * _progressAnimation.value;
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFffd700), // Gold
                                      Color(0xFFffed4a), // Light gold
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFffd700).withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Footer
                      Column(
                        children: [
                          Text(
                            'Your trusted guide for',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            'safe and efficient trucking routes',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Safety first badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shield,
                                  color: Color(0xFFffd700),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SAFETY FIRST',
                                  style: GoogleFonts.overpass(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
