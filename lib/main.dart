import 'package:Mirarr/functions/themeprovider_class.dart';
import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/widgets/check_updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Mirarr/moviesPage/mainPage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return MaterialApp(
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
