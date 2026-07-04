import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ShareContent {
  static void shareMovie(int movieId) {
    final url = 'https://www.themoviedb.org/movie/$movieId';
    Share.share(url);
  }

  static void shareTVShow(int serieId) {
    final url = 'https://www.themoviedb.org/tv/$serieId';
    Share.share(url);
  }

  static Future<void> sharePartialScreenshot(
      ScreenshotController screenshotController,
      Widget widget,
      int movieId) async {
    final capturedImage = await screenshotController.captureFromWidget(
      Material(
        color: Colors.black,
        child: widget,
      ),
      context: null,
      delay: const Duration(milliseconds: 100),
    );
    final url = 'https://www.themoviedb.org/movie/$movieId';

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(capturedImage, mimeType: 'image/png', name: 'screenshot.png')],
        text: '$url\nCheck out this movie!',
      );
    } else {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/screenshot.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(capturedImage);
      await Share.shareXFiles([XFile(imagePath)],
          text: '$url\nCheck out this movie!');
    }
  }

  static Future<void> sharePartialScreenshotTV(
      ScreenshotController screenshotController,
      Widget widget,
      int serieId) async {
    final capturedImage = await screenshotController.captureFromWidget(
      Material(
        color: Colors.black,
        child: widget,
      ),
      context: null,
      delay: const Duration(milliseconds: 100),
    );
    final url = 'https://www.themoviedb.org/tv/$serieId';

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(capturedImage, mimeType: 'image/png', name: 'screenshot.png')],
        text: '$url\nCheck out this TV show!',
      );
    } else {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/screenshot.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(capturedImage);
      await Share.shareXFiles([XFile(imagePath)],
          text: '$url\nCheck out this TV show!');
    }
  }
}
