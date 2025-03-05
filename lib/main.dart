import 'package:Mirarr/functions/themeprovider_class.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/functions/url_parser.dart';
import 'package:Mirarr/widgets/check_updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Mirarr/moviesPage/mainPage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('sessionBox');
  await Hive.box('sessionBox').close();
  await Hive.close();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowManager.instance.setMinimumSize(const Size(1600, 900));
  }

  final themeProvider = ThemeProvider(AppThemes.orangeTheme);
  await themeProvider.loadTheme();

  final regionProvider = RegionProvider('worldwide');
  await regionProvider.loadRegion();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: regionProvider),
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
    if (!_isInitialized && !Platform.isLinux) {
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
        if (uri != null && navigatorKey.currentContext != null) {
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
      return MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Mirarr',
        theme: themeProvider.currentTheme,
        home: const Scaffold(
          body: ConnectivityWidget(),
        ),
      );
    });
  }
}

class ConnectivityWidget extends StatelessWidget {
  const ConnectivityWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConnectivityResult>>(
      future: Connectivity().checkConnectivity(),
      builder: (context, AsyncSnapshot<List<ConnectivityResult>> snapshot) {
        if (!snapshot.hasData ||
            snapshot.data?.isEmpty == true ||
            snapshot.data
                    ?.every((result) => result == ConnectivityResult.none) ==
                true) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'No internet connection detected.\n Please check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
        return Builder(
          builder: (BuildContext context) {
            // Check for updates
            WidgetsBinding.instance.addPostFrameCallback((_) {
              UpdateChecker.checkForUpdate(context);
            });
            return const MovieSearchScreen();
          },
        );
      },
    );
  }
}
