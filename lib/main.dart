import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:roads_map/widgets/app_wrapper.dart';

import 'initialization_provider.dart';
import 'providers/settings_notifier.riverpod.dart';
import 'utils/app_config.dart';
import 'utils/app_themes.riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  try {
    AppConfig.initialize(dotenv.env);
  } on ConfigurationException catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(e.toString())))),
    ));
    return;
  }
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  GoogleFonts.config.allowRuntimeFetching = false;
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
      systemNavigationBarColor:
          Theme.of(context).bottomSheetTheme.backgroundColor,
      systemNavigationBarIconBrightness:
          MediaQuery.platformBrightnessOf(context),
      // statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          MediaQuery.platformBrightnessOf(context) == Brightness.light
              ? Brightness.dark
              : Brightness.light,
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
