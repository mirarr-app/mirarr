import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class SourcererOutput {
  final List<Embed> embeds;

  SourcererOutput({
    required this.embeds,
  });

  factory SourcererOutput.fromJson(Map<String, dynamic> json) {
    return SourcererOutput(
      embeds: [Embed.fromJson(json)],
    );
  }
}

class Embed {
  final String embedId;
  final String url;

  Embed({
    required this.embedId,
    required this.url,
  });

  factory Embed.fromJson(Map<String, dynamic> json) {
    return Embed(
      embedId: json['embedId'],
      url: json['url'],
    );
  }
}

class StreamQuality {
  final String quality;
  final String url;

  StreamQuality({
    required this.quality,
    required this.url,
  });

  factory StreamQuality.fromJson(String quality, Map<String, dynamic> json) {
    return StreamQuality(
      quality: quality,
      url: json['url'],
    );
  }
}

class Subtitle {
  final String language;
  final String url;

  Subtitle({
    required this.language,
    required this.url,
  });

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      language: json['language'],
      url: json['url'],
    );
  }
}

class StreamData {
  final List<StreamQuality> qualities;
  final List<Subtitle> subtitles;

  StreamData({
    required this.qualities,
    required this.subtitles,
  });
}

class WhvxService {
  static const String baseUrl = 'https://api.whvx.net';
  static const Map<String, String> headers = {
    'Origin': 'https://www.vidbinge.com',
    'Referer': 'https://www.vidbinge.com',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
  };

  final http.Client _client = http.Client();

  Future<SourcererOutput> search({
    required String title,
    required String releaseYear,
    required String tmdbId,
    required String imdbId,
    required String type,
    String? season,
    String? episode,
  }) async {
    try {
      final query = {
        'title': title,
        'releaseYear': releaseYear,
        'tmdbId': tmdbId,
        'imdbId': imdbId,
        'type': type,
      };

      if (type == 'show' && season != null && episode != null) {
        query['season'] = season;
        query['episode'] = episode;
      }

      final encodedQuery = Uri.encodeComponent(json.encode(query));
      final searchUrl =
          Uri.parse('$baseUrl/search?query=$encodedQuery&provider=nova');

      log('Search URL: ${searchUrl.toString()}');

      final searchResponse = await _client.get(searchUrl, headers: headers);

      log('Search Response Status: ${searchResponse.statusCode}');
      log('Search Response Body: ${searchResponse.body}');

      if (searchResponse.statusCode == 200) {
        final Map<String, dynamic> searchData =
            json.decode(searchResponse.body);
        return SourcererOutput.fromJson(searchData);
      } else {
        throw Exception('Search failed: ${searchResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during search: $e');
    }
  }

  Future<StreamData> getStreams(Embed embed) async {
    try {
      final resourceId = Uri.encodeComponent(embed.url).replaceAll('"', '');
      final provider = embed.embedId;
      final providerUrl = Uri.parse(
          '$baseUrl/source/?resourceId=$resourceId&provider=$provider');

      log('Provider URL: ${providerUrl.toString()}');
      log('Provider Headers: $headers');

      final providerResponse = await _client.get(
        providerUrl,
        headers: headers,
      );

      log('Provider Response Status: ${providerResponse.statusCode}');
      log('Provider Response Body: ${providerResponse.body}');

      if (providerResponse.statusCode == 200) {
        final Map<String, dynamic> providerData =
            json.decode(providerResponse.body);
        if (providerData['stream'] != null &&
            providerData['stream'][0]['qualities'] != null) {
          final qualities = (providerData['stream'][0]['qualities']
                  as Map<String, dynamic>)
              .entries
              .map((entry) => StreamQuality.fromJson(entry.key, entry.value))
              .toList();

          final subtitles = (providerData['stream'][0]['captions'] as List?)
                  ?.map((caption) => Subtitle.fromJson(caption))
                  .toList() ??
              [];

          return StreamData(qualities: qualities, subtitles: subtitles);
        } else {
          throw Exception('No streams or URL found in the response');
        }
      } else {
        throw Exception(
            'Failed to get streams: ${providerResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting streams: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
