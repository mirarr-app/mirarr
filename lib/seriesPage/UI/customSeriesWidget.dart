import 'package:flutter/material.dart';
import 'package:Mirarr/seriesPage/models/serie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CustomSeriesWidget extends StatelessWidget {
  final Serie serie;

  const CustomSeriesWidget({super.key, required this.serie});
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
    return Card(
      elevation: 4,
      child: Container(
        height: 500,
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: serie.posterPath.isNotEmpty
              ? DecorationImage(
                  image: CachedNetworkImageProvider(
                    'https://tmdbpics.maybeparsa.top/t/p/w500${serie.posterPath}',
                  ),
                  fit: BoxFit.cover,
                )
              : null, // No image if there's no poster path
        ),
        child: Stack(
          children: [
            if (serie.posterPath.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent]),

                  borderRadius: BorderRadius.circular(20), // Amber overlay
                ),
              ),
            Container(
              margin: const EdgeInsets.only(top: 8, left: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(),
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
    );
  }
}
