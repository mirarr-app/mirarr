import 'package:Mirarr/widgets/check_updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Mirarr/moviesPage/mainPage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
    WindowManager.instance.setMinimumSize(const Size(1500, 900));
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Search App',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Colors.orange,
          onPrimary: Colors.blue,
          secondary: Colors.purple,
          onSecondary: Colors.deepPurple,
          error: Colors.red,
          onError: Colors.orange,
          background: Colors.black,
          onBackground: Colors.black,
          surface: Colors.black,
          onSurface: Colors.black,
        ),
        cardColor: Theme.of(context).primaryColor,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const Scaffold(
        body: ConnectivityWidget(), // Use ConnectivityWidget as the home screen
      ),
    );
  }
}

class ConnectivityWidget extends StatelessWidget {
  const ConnectivityWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, AsyncSnapshot<ConnectivityResult> snapshot) {
        if (!snapshot.hasData || snapshot.data == ConnectivityResult.none) {
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
