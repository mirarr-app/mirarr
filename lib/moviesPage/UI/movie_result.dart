import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Mirarr/moviesPage/models/movie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MovieSearchResult extends StatelessWidget {
  final Movie movie;

  const MovieSearchResult({super.key, required this.movie});

  Future<bool> checkAvailability(int movieId) async {
    final apiKey = dotenv.env['TMDB_API_KEY'];
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/movie/$movieId/watch/providers?api_key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, dynamic> results = data['results'];

      return results.isNotEmpty;
    } else {
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
          height: 180,
          width: 250,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            image: movie.backdropPath != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://image.tmdb.org/t/p/original${movie.backdropPath}',
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
                decoration: const BoxDecoration(),
                child: Text(
                  '⭐ ${movie.score?.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: 10,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(),
                  child: FutureBuilder(
                    future: checkAvailability(movie.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: SizedBox(
                              height: 10,
                              width: 10,
                              child: CircularProgressIndicator()),
                        );
                      } else if (snapshot.hasError) {
                        return const Text('Error loading data');
                      } else {
                        return snapshot.data == true
                            ? const Icon(
                                Icons.download_rounded,
                                color: Colors.yellow,
                              )
                            : const Icon(
                                Icons.file_download_off_sharp,
                                color: Colors.yellow,
                              );
                      }
                    },
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
                        movie.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Text(
                        movie.releaseDate,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
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
