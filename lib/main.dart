import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:roads_map/widgets/app_wrapper.dart';

import 'initialization_provider.dart';
import 'providers/settings_notifier.riverpod.dart';
import 'utils/app_themes.riverpod.dart';

void main() async {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  GoogleFonts.config.allowRuntimeFetching = false;
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint = (String? message, {int? wrapWidth}) {
    if (kDebugMode) {
      debugPrintThrottled(message, wrapWidth: wrapWidth);
    }
  };
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Hive.initFlutter();


  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      systemNavigationBarIconBrightness: MediaQuery.platformBrightnessOf(context),
      // statusBarColor: Colors.transparent,
      statusBarIconBrightness: MediaQuery.platformBrightnessOf(context) == Brightness.light ? Brightness.dark : Brightness.light,
    ));
    final initialization = ref.watch(initializationProvider);
    final themeMode = ref.watch(settingsNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      title: 'Heavy Vehicles Road Network WA',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      home: initialization.when(
        data: (_) => const AppWrapper(),
        loading: () => Scaffold(
          backgroundColor: ref.watch(primaryColorProvider),
        ),
        error: (error, stack) => Scaffold(
          body: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}
