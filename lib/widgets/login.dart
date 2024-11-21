import 'dart:convert';

import 'package:Mirarr/functions/show_error_dialog.dart';
import 'package:Mirarr/widgets/changecolor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:Mirarr/widgets/profile.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:http/http.dart' as http;

import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final TMDB tmdb;
  final apiKey = dotenv.env['TMDB_API_KEY'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['TMDB_API_KEY'];
    tmdb = TMDB(ApiKeys(apiKey!, ""));
  }

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    setState(() {
      _isLoading = true;
    });

    try {
      var requestToken =
          await tmdb.v3.auth.createSessionWithLogin(email, password) as String?;
      if (requestToken != null) {
        // Step 4: Create session
        var sessionData = await tmdb.v3.auth.createSession(requestToken);

        if (sessionData != null) {
          var accountData = await http.get(Uri.parse(
              'https://api.themoviedb.org/3/account?api_key=$apiKey&session_id=$sessionData'));
          if (accountData.statusCode == 200) {
            final String accountId =
                json.decode(accountData.body)['id'].toString();
            _toProfile(sessionData, accountId);
          } else {
            showErrorDialog('Error',
                'Failed to get account Id. Please try again.', context);
          }
        } else {
          showErrorDialog('Error',
              'Failed to create session. Please try again later.', context);
        }
      } else {
        // Authentication failed
        showErrorDialog('Error',
            'Failed to login. Please check your credentials.', context);
      }
    } catch (e) {
      if (e.toString().contains('401')) {
        showErrorDialog('Error',
            'Invalid username or password. Please try again.', context);
      } else {
        showErrorDialog('Error',
            'An unexpected error occurred. Please try again later.', context);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrlString(url.toString())) {
      await launchUrlString(url.toString());
    } else {
      throw Exception('Could not launch url');
    }
  }

  Future<void> _signup() async {
    final url = Uri.parse('https://www.themoviedb.org/signup');

    try {
      await _launchUrl(url);
    } catch (e) {
      showErrorDialog('Error', 'Failed to launch URL', context);
    }
  }

  Future<void> _forgotpassword() async {
    final url = Uri.parse('https://www.themoviedb.org/reset-password');

    try {
      await _launchUrl(url);
    } catch (e) {
      showErrorDialog('Error', 'Failed to launch URL', context);
    }
  }

  void _toProfile(String sessionData, String accountId) async {
    final box = await Hive.openBox('sessionBox');
    await box.put('sessionData', sessionData);
    await box.put('accountId', accountId);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Login',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            const Column(
              children: [
                Text(
                  'Login or SignUp to MovieDB',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(80, 8, 80, 8),
                  child: Text(
                    textAlign: TextAlign.center,
                    'Notice that this app uses MovieDB for authentication and storing information.',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 60,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    autocorrect: false,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    cursorColor: Colors.black,
                    controller: _emailController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Theme.of(context).hintColor,
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    obscureText: true,
                    autocorrect: false,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    cursorColor: Colors.black,
                    controller: _passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Theme.of(context).hintColor,
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                        child: GestureDetector(
                          onTap: () {
                            _forgotpassword();
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: _isLoading
                            ? ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.black),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                              )
                            : ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Theme.of(context).primaryColor),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                ),
                              ),
                        child: _isLoading
                            ? const RefreshProgressIndicator()
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 80,
                  ),
                  const Center(
                    child: Text(
                      'Don\'t have an account?',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: _signup,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Theme.of(context).primaryColor),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                20.0), // Adjust the value for the roundness you desire
                          ),
                        ),
                      ),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.black, // Text color
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
