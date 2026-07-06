part of 'movieDetailPage.dart';

class _MovieDetailPageDesktop extends StatelessWidget {
  final _MovieDetailPageState state;

  const _MovieDetailPageDesktop(this.state);

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final moviedetails = state.moviedetails;
    final duration = state.duration;
    final releaseDate = state.releaseDate;
    final imdbRating = state.imdbRating;
    final rottenTomatoesRating = state.rottenTomatoesRating;
    final isWatched = state.isWatched;
    final posterPath = state.posterPath;
    final score = state.score;
    final backdrops = state.backdrops;
    final isUserLoggedIn = state.isUserLoggedIn;
    final isMovieWatchlist = state.isMovieWatchlist;
    final isMovieFavorite = state.isMovieFavorite;
    final isMovieRated = state.isMovieRated;
    final userRating = state.userRating;
    final genres = state.genres;
    final about = state.about;
    final budget = state.budget;
    final revenue = state.revenue;
    final productionCountries = state.productionCountries;
    final productionCompanies = state.productionCompanies;
    final spokenLanguages = state.spokenLanguages;
    final imdbId = state.imdbId;
    final _availabilityFuture = state._availabilityFuture;
    final _creditsFuture = state._creditsFuture;
    final _directorMoviesFuture = state._directorMoviesFuture;
    final _castImagesFuture = state._castImagesFuture;
    final language = state.language;

    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;
    int? hours = duration != null ? duration ~/ 60 : null;
    int? minutes = duration != null ? duration % 60 : null;
    String year = releaseDate != null && releaseDate.isNotEmpty
        ? releaseDate.substring(0, 4)
        : 'NA';

    final bool isTv = TvFocusModeManager.isTvDevice;

    final Widget bodyContent = moviedetails == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(),
              scrollbars: true,
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: CachedNetworkImageProvider(
                                '${getImageBaseUrl(region)}/t/p/w500$backdrops'),
                            fit: BoxFit.fitWidth,
                            opacity: 0.5),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CachedNetworkImage(
                                imageUrl:
                                    '${getImageBaseUrl(region)}/t/p/w500$posterPath',
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  height: 800,
                                  width: 600,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: imageProvider,
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                    ),
                                    child: Text(widget.movieTitle,
                                        style: getMovieTitleTextStyle(
                                            widget.movieId)),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          _castImagesFuture.then((imageUrls) {
                                            state._openImageGallery(imageUrls);
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.image_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Visibility(
                                        visible: isUserLoggedIn == true,
                                        child: GestureDetector(
                                          onTap: () async {
                                            if (isMovieWatchlist == null) {
                                              return;
                                            }
                                            final movieId = widget.movieId;
                                            final openbox = Hive.box('sessionBox');
                                            final String accountId =
                                                openbox.get('accountId');
                                            final String sessionData =
                                                openbox.get('sessionData');
                                            if (isMovieWatchlist) {
                                              // Remove from watchlist
                                              state.updateState(() {
                                                state.isMovieWatchlist = false;
                                              });
                                              await removeFromWatchList(
                                                  accountId,
                                                  sessionData,
                                                  movieId,
                                                  context);
                                              profileRefreshNotifier.value++;
                                            } else {
                                              // Add to watchlist
                                              state.updateState(() {
                                                state.isMovieWatchlist = true;
                                              });
                                              await addWatchList(
                                                  accountId,
                                                  sessionData,
                                                  movieId,
                                                  context);
                                              profileRefreshNotifier.value++;
                                            }
                                          },
                                          child: Icon(
                                            isMovieWatchlist == null
                                                ? Icons.bookmark_border
                                                : isMovieWatchlist
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_border,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                      Visibility(
                                        visible: isUserLoggedIn == true,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 0, 0, 0),
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (isMovieFavorite == null) {
                                                return;
                                              }
                                              final movieId = widget.movieId;
                                              final openbox =
                                                  Hive.box('sessionBox');
                                              final String accountId =
                                                  openbox.get('accountId');
                                              final String sessionData =
                                                  openbox.get('sessionData');
                                              if (isMovieFavorite) {
                                                removeFromFavorite(
                                                    accountId,
                                                    sessionData,
                                                    movieId,
                                                    context);
                                                state.updateState(() {
                                                  state.isMovieFavorite = false;
                                                  profileRefreshNotifier.value++;
                                                });
                                              } else {
                                                addFavorite(
                                                    accountId,
                                                    sessionData,
                                                    movieId,
                                                    context);
                                                state.updateState(() {
                                                  state.isMovieFavorite = true;
                                                  profileRefreshNotifier.value++;
                                                });
                                              }
                                            },
                                            child: Icon(
                                              isMovieFavorite == null
                                                  ? Icons.favorite_border
                                                  : isMovieFavorite
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // logged in and rated
                                      if (isUserLoggedIn == true &&
                                          isMovieRated != false &&
                                          userRating != null)
                                        Container(
                                          margin: const EdgeInsets.all(10),
                                          padding: const EdgeInsets.all(10),
                                          decoration: const BoxDecoration(
                                              color: Colors.black38,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(30))),
                                          child: GestureDetector(
                                            onTap: () => showModalBottomSheet(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(
                                                      height: 20,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: RatingBar.builder(
                                                        initialRating:
                                                            userRating,
                                                        minRating: 1,
                                                        maxRating: 10,
                                                        itemSize: 35,
                                                        unratedColor:
                                                            Colors.grey,
                                                        direction:
                                                            Axis.horizontal,
                                                        allowHalfRating: true,
                                                        itemCount: 10,
                                                        itemPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 0),
                                                        itemBuilder:
                                                            (context, _) =>
                                                                const Icon(
                                                          Icons.star,
                                                          color: Colors.amber,
                                                        ),
                                                        onRatingUpdate:
                                                            (rating) async {
                                                          final movieId =
                                                              widget.movieId;
                                                          final openbox =
                                                              Hive.box('sessionBox');

                                                          final String
                                                              sessionData =
                                                              openbox.get(
                                                                  'sessionData');
                                                          addRating(
                                                              sessionData,
                                                              movieId,
                                                              rating,
                                                              context);
                                                          state.updateState(() {
                                                            state.isMovieRated = {'value': rating};
                                                            state.userRating = rating;
                                                            profileRefreshNotifier.value++;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    const CustomDivider(),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        final openbox =
                                                            Hive.box('sessionBox');

                                                        final String
                                                            sessionData =
                                                            openbox.get(
                                                                'sessionData');
                                                        removeRating(
                                                            sessionData,
                                                            widget.movieId,
                                                            context);
                                                        Navigator.of(context)
                                                            .pop();
                                                        state.updateState(() {
                                                          state.isMovieRated = false;
                                                          state.userRating = null;
                                                          profileRefreshNotifier.value++;
                                                        });
                                                      },
                                                      child: const Text(
                                                        ' 🗑️ Delete Rating',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 20,
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                            child: Text(
                                              '👤 ${userRating.toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w300,
                                                fontSize: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      //logged in not rated
                                      if (isUserLoggedIn == true &&
                                          isMovieRated == false &&
                                          userRating == null)
                                        IconButton(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      RatingBar.builder(
                                                        initialRating: 5,
                                                        minRating: 1,
                                                        maxRating: 10,
                                                        itemSize: 35,
                                                        unratedColor:
                                                            Colors.grey,
                                                        direction:
                                                            Axis.horizontal,
                                                        allowHalfRating: true,
                                                        itemCount: 10,
                                                        itemPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 0),
                                                        itemBuilder:
                                                            (context, _) =>
                                                                const Icon(
                                                          Icons.star,
                                                          color: Colors.amber,
                                                        ),
                                                        onRatingUpdate:
                                                            (rating) async {
                                                          final movieId =
                                                              widget.movieId;
                                                          final openbox =
                                                              Hive.box('sessionBox');

                                                          final String
                                                              sessionData =
                                                              openbox.get(
                                                                  'sessionData');
                                                          addRating(
                                                              sessionData,
                                                              movieId,
                                                              rating,
                                                              context);
                                                          state.updateState(() {
                                                            state.isMovieRated = '"value":$rating';
                                                            state.userRating = rating;
                                                            profileRefreshNotifier.value++;
                                                          });
                                                        },
                                                      ),
                                                      const SizedBox(
                                                        height: 40,
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.add_reaction,
                                              color: Colors.white,
                                            )),
                                      Container(
                                        margin: const EdgeInsets.all(5),
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(30))),
                                        child: Text(
                                          '⭐ ${score?.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Visibility(
                                        visible: imdbRating != null &&
                                            imdbRating.isNotEmpty,
                                        child: Container(
                                          margin: const EdgeInsets.all(5),
                                          padding: const EdgeInsets.all(10),
                                          decoration: const BoxDecoration(
                                              color: Colors.black38,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(30))),
                                          child: Text(
                                            'IMDB⭐ $imdbRating',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w300,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Visibility(
                                        visible: rottenTomatoesRating != 'N/A',
                                        child: Container(
                                          margin: const EdgeInsets.all(5),
                                          padding: const EdgeInsets.all(10),
                                          decoration: const BoxDecoration(
                                              color: Colors.black38,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(30))),
                                          child: Text(
                                            'Rotten Tomatoes🍅 $rottenTomatoesRating',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w300,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Mark as Watched button
                                      GestureDetector(
                                        onTap: isWatched ? state._removeFromWatched : state._markAsWatched,
                                        child: Container(
                                          margin: const EdgeInsets.all(5),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isWatched ? Colors.green.withOpacity(0.7) : Colors.black38,
                                            borderRadius: const BorderRadius.all(Radius.circular(30)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isWatched ? Icons.check_circle : Icons.visibility,
                                                color: Colors.white,
                                                size: 16,

                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isWatched ? 'Watched' : 'Mark as Watched',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w300,
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      Center(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: (genres as List<dynamic>)
                                                .map<Widget>((genre) {
                                              return Text(
                                                genre['name'] + ' | ',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w200),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        25, 10, 25, 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: FutureBuilder(
                                              future: _availabilityFuture,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  // Display loading indicator while fetching data
                                                  return const SizedBox();
                                                } else if (snapshot.hasError) {
                                                  // Display error message if fetching data fails
                                                  return const Text(
                                                      'Error loading data');
                                                } else {
                                                  // Display check mark if results are not empty
                                                  return snapshot.data == true
                                                      ? SizedBox(
                                                          width: 400,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            spacing: 6,
                                                            children: [
                                                              Expanded(
                                                                child: FloatingActionButton(
                                                                  heroTag: null,
                                                                  backgroundColor:
                                                                      getMovieColor(
                                                                          context,
                                                                          widget
                                                                              .movieId),
                                                                  onPressed: () => showWatchOptions(
                                                                      context,
                                                                      widget
                                                                          .movieId,
                                                                      widget
                                                                          .movieTitle,
                                                                      releaseDate ??
                                                                          '',
                                                                      imdbId ??
                                                                          ''),
                                                                  child: Text(
                                                                      'Watch',
                                                                      style: getMovieButtonTextStyle(
                                                                          widget
                                                                              .movieId)),
                                                                ),
                                                              ),

                                                            ],
                                                          ))
                                                      : const SizedBox();
                                                }
                                              }),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        25, 10, 25, 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                            child: SizedBox(
                                          width: 400,
                                          child: FloatingActionButton(
                                            heroTag: null,
                                            backgroundColor: getMovieColor(
                                                context, widget.movieId),
                                            onPressed: () => showTorrentOptions(
                                                context,
                                                widget.movieId,
                                                widget.movieTitle,
                                                releaseDate,
                                                imdbId),
                                            child: Text(
                                              'Torrent Search',
                                              style: getMovieButtonTextStyle(
                                                  widget.movieId),
                                            ),
                                          ),
                                        ))
                                      ],
                                    ),
                                  ),
                                  const CustomDivider(),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                    child: Container(
                                        width: 600,
                                        alignment: Alignment.center,
                                        child: Text(
                                          about!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w300,
                                          ),
                                          textAlign: TextAlign.justify,
                                        )),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          width: 110,
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                5, 5, 5, 5),
                                            margin: const EdgeInsets.fromLTRB(
                                                5, 5, 5, 5),
                                            decoration: BoxDecoration(
                                              color: getMovieBackgroundColor(
                                                  context, widget.movieId),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Duration',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w200,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    "${hours}H ${minutes}M",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 110,
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                5, 5, 5, 5),
                                            margin: const EdgeInsets.fromLTRB(
                                                5, 5, 5, 5),
                                            decoration: BoxDecoration(
                                              color: getMovieBackgroundColor(
                                                  context, widget.movieId),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Year',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w200,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    year,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 110,
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                5, 5, 5, 5),
                                            margin: const EdgeInsets.fromLTRB(
                                                5, 5, 5, 5),
                                            decoration: BoxDecoration(
                                              color: getMovieBackgroundColor(
                                                  context, widget.movieId),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Language',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w200,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    language != null
                                                        ? language
                                                            .toUpperCase()
                                                        : 'N/A',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    FutureBuilder(
                      future: _creditsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Text(
                              'Error loading cast and crew details');
                        } else {
                          final Map<String, List<Map<String, dynamic>>> data =
                              snapshot.data
                                  as Map<String, List<Map<String, dynamic>>>;
                          final List<Map<String, dynamic>> castList =
                              data['cast'] ?? [];
                          final List<Map<String, dynamic>> crewList =
                              data['crew'] ?? [];

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(25, 10, 0, 0),
                                    child: Text(
                                      'Cast',
                                      textAlign: TextAlign.justify,
                                      style: getMovieTitleTextStyle(
                                          widget.movieId),
                                    ),
                                  )
                                ],
                              ),
                              const CustomDivider(),
                              buildCastRowDesktop(castList, context),
                              Row(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(25, 10, 0, 0),
                                    child: Text(
                                      'Crew',
                                      textAlign: TextAlign.justify,
                                      style: getMovieTitleTextStyle(
                                          widget.movieId),
                                    ),
                                  ),
                                ],
                              ),
                              const CustomDivider(),
                              buildCrewRowDesktop(crewList, context)
                            ],
                          );
                        }
                      },
                    ),
                    const CustomDivider(),
                    FutureBuilder(
                      future: _creditsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Text(
                              'Error loading cast and crew details');
                        } else {
                          final Map<String, List<Map<String, dynamic>>> data =
                              snapshot.data
                                  as Map<String, List<Map<String, dynamic>>>;

                          final List<Map<String, dynamic>> crewList =
                              data['crew'] ?? [];

                          Map<String, dynamic>? director;

                          for (var crewMember in crewList) {
                            if (crewMember['job'] == 'Director') {
                              director = crewMember;
                              break;
                            }
                          }

                          if (director != null) {
                            return Column(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(25, 10, 0, 0),
                                    child: Text("Movies by ${director['name']}",
                                        style: getMovieTitleTextStyle(
                                            widget.movieId)),
                                  ),
                                ),
                              _directorMoviesFuture == null
                                  ? const Center(child: CircularProgressIndicator())
                                  : FutureBuilder(
                                      future: _directorMoviesFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return const Text(
                                          'Error loading other movies');
                                    } else {
                                      List<dynamic> movies =
                                          snapshot.data as List<dynamic>;

                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: movies.map((movie) {
                                            return Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  children: [
                                                    Card(
                                                      elevation: 4,
                                                      child: GestureDetector(
                                                        onTap: () => state.onTapMovie(
                                                            movie['title'],
                                                            movie['id']),
                                                        child: Container(
                                                          height: 300,
                                                          width: 200,
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            image: movie[
                                                                        'poster_path']
                                                                    .isNotEmpty
                                                                ? DecorationImage(
                                                                    image:
                                                                        CachedNetworkImageProvider(
                                                                      '${getImageBaseUrl(region)}/t/p/w200${movie['poster_path']}',
                                                                    ),
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  )
                                                                : null, // No image if there's no poster path
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 140,
                                                      child: Text(
                                                        movie['title'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 2,
                                                        softWrap: true,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ));
                                          }).toList(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          } else {
                            return const SizedBox();
                          }
                        }
                      },
                    ),
                    const CustomDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Container(
                        alignment: Alignment.center,
                        child: ExpansionTile(
                          collapsedIconColor: Theme.of(context).primaryColor,
                          title: Text('Other Info',
                              style: getMovieTitleTextStyle(widget.movieId)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(25, 10, 0, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      budget != null && budget != 0
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Budget',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Theme.of(context)
                                                          .primaryColor),
                                                ),
                                                Text(
                                                  '\$${NumberFormat("#,##0").format(budget)}',
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white),
                                                ),
                                              ],
                                            )
                                          : Container(),
                                      const CustomDivider(),
                                      revenue != null && revenue != 0
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Revenue',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Theme.of(context)
                                                          .primaryColor),
                                                ),
                                                Text(
                                                  '\$${NumberFormat("#,##0").format(revenue)}',
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white),
                                                ),
                                              ],
                                            )
                                          : Container(),
                                      const CustomDivider(),
                                      Text(
                                        'Production Countries',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: (productionCountries
                                                as List<dynamic>)
                                            .map<Widget>((productionCountry) {
                                          return Text(
                                            productionCountry['name'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w200,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const CustomDivider(),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Production Companies',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: (productionCompanies
                                                    as List<dynamic>)
                                                .map<Widget>(
                                                    (productionCompany) {
                                              return Text(
                                                productionCompany['name'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w200,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                      const CustomDivider(),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Spoken Languages',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: (spokenLanguages
                                                    as List<dynamic>)
                                                .map<Widget>((spokenLanguage) {
                                              return Text(
                                                spokenLanguage['name'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w200,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: getMovieColor(context, widget.movieId),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: Text(
              widget.movieTitle,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: isTv
          ? Column(
              children: [
                const BottomBar(),
                Expanded(child: bodyContent),
              ],
            )
          : bodyContent,
      bottomNavigationBar: isTv ? null : const BottomBar(),
    );
  }
}
