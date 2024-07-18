import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpdateChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    final currentVersion = await _getCurrentVersion();
    final latestVersion = await _getLatestVersion();

    if (latestVersion != null &&
        _isNewerVersion(currentVersion, latestVersion)) {
      _showUpdateDialog(context, latestVersion);
    }
  }

  static Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static Future<String?> _getLatestVersion() async {
    final response = await http.get(Uri.parse(
        'https://api.github.com/repos/mirarr-app/mirarr/releases/latest'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['tag_name'];
    }
    return null;
  }

  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String newVersion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Update Available',
            style: TextStyle(color: Colors.orange),
          ),
          content: Text(
              'A new version ($newVersion) is available. Would you like to update?',
              style: const TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Later', style: TextStyle(color: Colors.orange)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child:
                  const Text('Update', style: TextStyle(color: Colors.orange)),
              onPressed: () {
                _launchURL(
                    'https://github.com/mirarr-app/mirarr/releases/latest');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> _launchURL(String url) async {
    if (await canLaunchUrlString(url.toString())) {
      await launchUrlString(url.toString());
    } else {
      throw 'Could not launch $url';
    }
  }
}
