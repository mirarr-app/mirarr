import 'package:Mirarr/functions/themeprovider_class.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/supabase_provider.dart';
import 'package:Mirarr/functions/url_parser.dart';
import 'package:Mirarr/functions/navigation_provider.dart';
import 'package:Mirarr/widgets/main_shell.dart';
import 'package:Mirarr/widgets/check_updates.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TvFocusModeManager.init();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('sessionBox');
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowManager.instance.setMinimumSize(const Size(360, 500));
  }

  final themeProvider = ThemeProvider(AppThemes.orangeTheme);
  await themeProvider.loadTheme();

  final regionProvider = RegionProvider('worldwide');
  await regionProvider.loadRegion();

  final supabaseProvider = SupabaseProvider();
  await supabaseProvider.loadSupabaseConfig();
  supabaseProvider.prefetchRemoteData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: regionProvider),
        ChangeNotifierProvider.value(value: supabaseProvider),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  Future<void> _initAppLinks() async {
    if (!_isInitialized && (kIsWeb || !Platform.isLinux)) {
      _appLinks = AppLinks();

      // Handle initial URI if the app was launched from a link
      try {
        final uri = await _appLinks.getInitialAppLink();
        if (uri != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (navigatorKey.currentContext != null) {
              await TMDBUrlParser.handleUrl(
                  uri.toString(), navigatorKey.currentContext!);
            }
          });
        }
      } catch (e) {
        debugPrint('Error handling initial app link: $e');
      }

      // Handle incoming links while the app is running
      _appLinks.uriLinkStream.listen((uri) async {
        if (navigatorKey.currentContext != null) {
          await TMDBUrlParser.handleUrl(
              uri.toString(), navigatorKey.currentContext!);
        }
      }, onError: (err) {
        debugPrint('Error handling app links: $err');
      });

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Listener(
        onPointerDown: (_) => TvFocusModeManager.onPointerDown(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Mirarr',
          theme: themeProvider.currentTheme,
          home: const Scaffold(
            body: AppInitWidget(),
          ),
        ),
      );
    });
  }
}

class AppInitWidget extends StatefulWidget {
  const AppInitWidget({Key? key}) : super(key: key);

  @override
  State<AppInitWidget> createState() => _AppInitWidgetState();
}

class _AppInitWidgetState extends State<AppInitWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        UpdateChecker.checkForUpdate(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainShellPage();
  }
}
