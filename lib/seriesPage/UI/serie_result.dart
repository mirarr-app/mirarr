import 'package:flutter/material.dart';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SerieSearchResult extends StatelessWidget {
  final Serie serie;

  const SerieSearchResult({super.key, required this.serie});
  Future<bool> checkAvailability(int movieId) async {
    final apiKey = dotenv.env['TMDB_API_KEY']; // Replace with your TMDB API Key
    final response = await http.get(
      Uri.parse(
        'https://tmdb.maybeparsa.top/tmdb/movie/$movieId/watch/providers?api_key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, dynamic> results = data['results'];

      return results.isNotEmpty;
    } else {
      // Handle error here
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 5, 3, 5),
      child: Card(
        elevation: 4,
        child: Container(
          height: 200,
          width: 250,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            image: serie.backdropPath != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://tmdbpics.maybeparsa.top/t/p/original${serie.backdropPath}',
                    ),
                    fit: BoxFit.cover,
                    opacity: 0.8)
                : null,
          ),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, left: 10),
                padding: const EdgeInsets.all(10),
                child: Text(
                  '⭐ ${serie.score?.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white, // Text color on top of the image
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Text(
                        serie.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Text color on top of the image
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
