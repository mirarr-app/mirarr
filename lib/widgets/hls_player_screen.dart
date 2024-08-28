import 'package:Mirarr/functions/hls_player.dart';
import 'package:flutter/material.dart';

class HlsPlayerScreen extends StatelessWidget {
  final String videoUrl;
  final Map<String, String> subtitleUrls;

  const HlsPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.subtitleUrls,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mirarr Player (Beta)',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: HLSPlayer(
          videoUrl: videoUrl,
          subtitleUrls: subtitleUrls,
        ),
      ),
    );
  }
}
