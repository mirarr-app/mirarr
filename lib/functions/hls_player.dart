import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_subtitle/flutter_subtitle.dart' hide Subtitle;
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;

class HLSPlayer extends StatefulWidget {
  final String videoUrl;
  final Map<String, String> subtitleUrls;

  const HLSPlayer(
      {Key? key, required this.videoUrl, required this.subtitleUrls})
      : super(key: key);

  @override
  _HLSPlayerState createState() => _HLSPlayerState();
}

class _HLSPlayerState extends State<HLSPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  late Map<String, SubtitleController> _subtitleControllers;
  String? _currentSubtitleKey;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    _subtitleControllers = {};
    for (var entry in widget.subtitleUrls.entries) {
      final body =
          utf8.decode((await http.get(Uri.parse(entry.value))).bodyBytes);
      _subtitleControllers[entry.key] =
          SubtitleController.string(body, format: SubtitleFormat.webvtt);
    }

    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _videoPlayerController.initialize();

    _currentSubtitleKey = widget.subtitleUrls.keys.first;

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: true,
      aspectRatio: 16 / 9,
      subtitleBuilder: (context, subtitle) {
        return IgnorePointer(
          child: SubtitleView(
            text: subtitle,
            subtitleStyle: SubtitleStyle(
              fontSize: _chewieController!.isFullScreen ? 20 : 16,
            ),
          ),
        );
      },
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
      allowMuting: true,
      showOptions: false,
      fullScreenByDefault: true,
    );
    _setSubtitles(_currentSubtitleKey!);
    setState(() {});
  }

  void _setSubtitles(String key) {
    if (_subtitleControllers.containsKey(key)) {
      _chewieController!.setSubtitle(
        _subtitleControllers[key]!
            .subtitles
            .map(
              (e) => Subtitle(
                index: e.number,
                start: Duration(milliseconds: e.start),
                end: Duration(milliseconds: e.end),
                text: e.text,
              ),
            )
            .toList(),
      );
      setState(() {
        _currentSubtitleKey = key;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 200),
          _chewieController != null
              ? AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Chewie(controller: _chewieController!),
                )
              : const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: _currentSubtitleKey,
            items: widget.subtitleUrls.keys.map((String key) {
              return DropdownMenuItem<String>(
                value: key,
                child: Text(
                  key,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                _setSubtitles(newValue);
              }
            },
          ),
          const SizedBox(height: 20),
          const Text('SubtitleControllView'),
          if (_chewieController != null && _currentSubtitleKey != null)
            SubtitleControllView(
              subtitleController: _subtitleControllers[_currentSubtitleKey]!,
              inMilliseconds: _chewieController!
                  .videoPlayerController.value.position.inMilliseconds,
            ),
          const SizedBox(height: 20),
          const Text('ClosedCaption'),
          if (_chewieController != null)
            ClosedCaption(
              text: _chewieController!.videoPlayerController.value.caption.text,
              textStyle: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}

class MyWebVTTCaptionFile extends ClosedCaptionFile {
  MyWebVTTCaptionFile(this.captions);

  @override
  List<Caption> captions = [];
}
