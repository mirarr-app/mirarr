import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/screenshot.png';

    final capturedImage = await screenshotController.captureFromWidget(
      Material(
        color: Colors.black,
        child: widget,
      ),
      context: null,
      delay: const Duration(milliseconds: 100),
    );
    final url = 'https://www.themoviedb.org/movie/$movieId';

    final imageFile = File(imagePath);

    await imageFile.writeAsBytes(capturedImage);
    await Share.shareXFiles([XFile(imagePath)],
        text: '$url\nCheck out this movie!');
  }

  static Future<void> sharePartialScreenshotTV(
      ScreenshotController screenshotController,
      Widget widget,
      int serieId) async {
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/screenshot.png';

    final capturedImage = await screenshotController.captureFromWidget(
      Material(
        color: Colors.black,
        child: widget,
      ),
      context: null,
      delay: const Duration(milliseconds: 100),
    );
    final url = 'https://www.themoviedb.org/tv/$serieId';

    final imageFile = File(imagePath);

    await imageFile.writeAsBytes(capturedImage);
    await Share.shareXFiles([XFile(imagePath)],
        text: '$url\nCheck out this TV show!');
  }
}
