import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:Mirarr/moviesPage/functions/on_tap_movie.dart';
import 'package:Mirarr/moviesPage/functions/on_tap_movie_desktop.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Mirarr/widgets/custom_divider.dart';
import 'package:Mirarr/widgets/image_gallery_page.dart';

class CrewDetailPage extends StatefulWidget {
  const CrewDetailPage({Key? key, required this.castId}) : super(key: key);
  final int castId;

  @override
  _CrewDetailPageState createState() => _CrewDetailPageState();
}

bool _showIcon = true;
final apiKey = dotenv.env['TMDB_API_KEY'];
const baseUrl = 'https://tmdb.maybeparsa.top/tmdb';

class _CrewDetailPageState extends State<CrewDetailPage> {
  late Future<Map<String, dynamic>> _castDetailsFuture;
  late Future<List<String>> _castImagesFuture;
  late Future<List<dynamic>> _otherMoviesFuture;

  @override
  void initState() {
    super.initState();
    _castDetailsFuture = _fetchCastDetails(widget.castId);
    _castImagesFuture = _fetchCastImages(widget.castId);
    _otherMoviesFuture = _fetchOtherMovies(widget.castId);
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _showIcon = false;
      });
    });
  }

  Future<Map<String, dynamic>> _fetchCastDetails(int castId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/person/$castId?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load cast details');
    }
  }

  Future<List<dynamic>> _fetchOtherMovies(int castId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/person/$castId/movie_credits?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> movies = decoded['crew'];

      Set<int> movieIds = {};

      List<dynamic> filteredMovies = [];

      for (var movie in movies) {
        if (movie['poster_path'] != null && movie['poster_path'] != '') {
          if (!movieIds.contains(movie['id'])) {
            filteredMovies.add(movie);
            movieIds.add(movie['id']);
          }
        }
      }
      return filteredMovies;
    } else {
      throw Exception('Failed to load other movies');
    }
  }

  Future<List<String>> _fetchCastImages(int castId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/person/$castId/images?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['profiles'];
      return data.map((image) => image['file_path'] as String).toList();
    } else {
      throw Exception('Failed to load cast images');
    }
  }

  void _openImageGallery(List<String> imageUrls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryPage(imageUrls: imageUrls),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _castDetailsFuture,
      builder: (context, snapshot) {
        String crewName = '';
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            crewName = 'Error';
          } else if (snapshot.hasData) {
            crewName = snapshot.data!['name'];
          }
        }

        return Scaffold(
          appBar: Platform.isLinux || Platform.isWindows || Platform.isMacOS
              ? AppBar(
                  toolbarHeight: 40,
                  backgroundColor: Theme.of(context).primaryColor,
                  iconTheme: const IconThemeData(color: Colors.black),
                  actions: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                        child: Text(
                          crewName,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ])
              : null,
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
                  ? Center(child: Text('Error: ${snapshot.error}'))
                  : _buildContent(snapshot.data!),
        );
      },
    );
  }

  Widget _buildContent(Map<String, dynamic> castData) {
    return Platform.isAndroid || Platform.isIOS
        ? Scaffold(
            body: FutureBuilder<Map<String, dynamic>>(
              future: _castDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  final castData = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _castImagesFuture.then((imageUrls) {
                              _openImageGallery(imageUrls);
                            });
                          },
                          child: Stack(
                            children: [
                              castData['profile_path'] == null
                                  ? Container(
                                      color: Theme.of(context).primaryColor,
                                      width: double.infinity,
                                      height: 300,
                                      child: const SizedBox(),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl:
                                          "https://tmdbpics.maybeparsa.top/t/p/original${castData['profile_path']}",
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                        height: 300,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: imageProvider,
                                          ),
                                        ),
                                      ),
                                    ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                                child: AnimatedOpacity(
                                  opacity: _showIcon ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 500),
                                  child: Center(
                                    child: Container(
                                      color: Colors.transparent,
                                      child: const Icon(
                                        Icons
                                            .touch_app, // You can change the icon as needed
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 300,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black, Colors.transparent],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 30,
                                left: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                      ),
                                      child: Text(
                                        castData['name']!,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const CustomDivider(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Container(
                            alignment: Alignment.center,
                            child: ExpansionTile(
                              collapsedIconColor:
                                  Theme.of(context).primaryColor,
                              title: const Text(
                                'Biography',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                  child: Container(
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                      ),
                                      child: castData['birthday'] == null
                                          ? const SizedBox.shrink()
                                          : Text(
                                              'Born:  ${castData['birthday']}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.white,
                                              ),
                                            )),
                                ),
                                if (castData['biography'] != null)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      castData['biography'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const CustomDivider(),
                        _buildOtherMoviesGrid(),
                      ],
                    ),
                  );
                }
              },
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      40, 0, 20, 20), // Adjusted padding
                  child: GestureDetector(
                    onTap: () {
                      _castImagesFuture.then((imageUrls) {
                        _openImageGallery(imageUrls);
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        castData['profile_path'] == null
                            ? Container(
                                color: Theme.of(context).primaryColor,
                                height: 400, // Adjusted height
                                child: const SizedBox(),
                              )
                            : CachedNetworkImage(
                                imageUrl:
                                    "https://tmdbpics.maybeparsa.top/t/p/original${castData['profile_path']}",
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  height: 400, // Adjusted height
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: imageProvider,
                                    ),
                                  ),
                                ),
                              ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
                          child: Text(
                            castData['name']!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (castData['biography'] != '')
                ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 30, 40, 80), // Adjusted padding
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Biography',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (castData['birthday'] != null)
                              Text(
                                'Born: ${castData['birthday']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            if (castData['biography'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 20, 0, 20),
                                child: Text(
                                  castData['biography'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 40, 20), // Adjusted padding
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: ScrollConfiguration(
                        behavior: const ScrollBehavior().copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: SingleChildScrollView(
                          child: _buildOtherMoviesGrid(),
                        )),
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildOtherMoviesGrid() {
    return FutureBuilder<List<dynamic>>(
      future: _otherMoviesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading movies: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No movies found'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final movie = snapshot.data![index];
            return _buildMovieItem(movie);
          },
        );
      },
    );
  }

  Widget _buildMovieItem(dynamic movie) {
    return GestureDetector(
      onTap: () => Platform.isAndroid || Platform.isIOS
          ? onTapMovie(movie['title'], movie['id'], context)
          : onTapMovieDesktop(movie['title'], movie['id'], context),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl:
                  "https://tmdbpics.maybeparsa.top/t/p/w500${movie['poster_path']}",
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: imageProvider,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  movie['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
