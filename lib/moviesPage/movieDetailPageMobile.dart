part of 'movieDetailPage.dart';

class _MovieDetailPageMobile extends StatelessWidget {
  final _MovieDetailPageState state;

  const _MovieDetailPageMobile(this.state);

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final moviedetails = state.moviedetails;
    final duration = state.duration;
    final releaseDate = state.releaseDate;
    final imdbRating = state.imdbRating;
    final rottenTomatoesRating = state.rottenTomatoesRating;
    final isWatched = state.isWatched;
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
    final availabilityFuture = state._availabilityFuture;
    final creditsFuture = state._creditsFuture;
    final directorMoviesFuture = state._directorMoviesFuture;
    final castImagesFuture = state._castImagesFuture;
    final screenshotController = state.screenshotController;
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
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Stack(
                      children: [
                        TvFocusWrapper(
                          onTap: () {
                            castImagesFuture.then((imageUrls) {
                              state._openImageGallery(imageUrls);
                            });
                          },
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl:
                                    '${getImageBaseUrl(region)}/t/p/original$backdrops',
                                placeholder: (context, url) => Skeletonizer(
                                  enabled: true,
                                  containersColor: Colors.white.withOpacity(0.05),
                                  effect: ShimmerEffect(
                                    baseColor: Colors.white.withOpacity(0.05),
                                    highlightColor: Colors.white.withOpacity(0.15),
                                  ),
                                  child: Container(
                                    height: 300,
                                    width: double.infinity,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                imageBuilder: (context, imageProvider) => Container(
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
                              Container(
                                height: 320,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black, Colors.transparent],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 70,
                          left: 10,
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                                color: Colors.black38,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30))),
                            child: Text(
                              'TMDB⭐ ${score?.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: imdbRating != null && imdbRating.isNotEmpty,
                          child: Positioned(
                            bottom: 70,
                            left: 110,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              child: Text(
                                'IMDB⭐ $imdbRating',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: rottenTomatoesRating != 'N/A',
                          child: Positioned(
                            bottom: 70,
                            left: 210,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              child: Text(
                                'Rotten Tomatoes🍅 $rottenTomatoesRating',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 28,
                          left: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                ),
                                width: MediaQuery.of(context).size.width - 20,
                                child: Text(
                                  widget.movieTitle,
                                  softWrap: true,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: getMovieTitleTextStyle(widget.movieId),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: AppPlatform.isAndroid,
                          child: Positioned(
                            top: 190,
                            right: 30,
                            child: TvFocusWrapper(
                              borderRadius: 30.0,
                              onTap: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: '',
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                  pageBuilder:
                                      (context, animation1, animation2) =>
                                          Container(),
                                  transitionBuilder:
                                      (context, animation1, animation2, child) {
                                    final curvedValue = Curves.easeInOut
                                            .transform(animation1.value) -
                                        1.0;
                                    return Transform(
                                      transform: Matrix4.translationValues(
                                          curvedValue * 300, 0, 0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          height: 200,
                                          width: 60,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              bottomLeft: Radius.circular(20),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    ShareContent.shareMovie(
                                                        widget.movieId);
                                                  },
                                                  icon: const Icon(
                                                    Icons.share,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                IconButton(
                                                  onPressed: () {
                                                    ShareContent
                                                        .sharePartialScreenshot(
                                                      screenshotController,
                                                      _buildScreenShotImage(context),
                                                      widget.movieId,
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.image,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.share,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: isUserLoggedIn == true,
                          child: Positioned(
                            top: 140,
                            right: 30,
                            child: TvFocusWrapper(
                              borderRadius: 30.0,
                              onTap: () async {
                                if (isMovieWatchlist == null) {
                                  return;
                                }
                                final movieId = widget.movieId;
                                final openbox =
                                    Hive.box('sessionBox');
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
                                      accountId, sessionData, movieId, context);
                                  profileRefreshNotifier.value++;
                                } else {
                                  // Add to watchlist
                                  state.updateState(() {
                                    state.isMovieWatchlist = true;
                                  });
                                  await addWatchList(
                                      accountId, sessionData, movieId, context);
                                  profileRefreshNotifier.value++;
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  isMovieWatchlist == null
                                      ? Icons.bookmark_border
                                      : isMovieWatchlist
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: isUserLoggedIn == true,
                          child: Positioned(
                            top: 90,
                            right: 30,
                            child: TvFocusWrapper(
                              borderRadius: 30.0,
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
                                  state.updateState(() {
                                    state.isMovieFavorite = false;
                                  });
                                  await removeFromFavorite(
                                      accountId, sessionData, movieId, context);
                                  profileRefreshNotifier.value++;
                                } else {
                                  state.updateState(() {
                                    state.isMovieFavorite = true;
                                  });
                                  await addFavorite(
                                      accountId, sessionData, movieId, context);
                                  profileRefreshNotifier.value++;
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  isMovieFavorite == null
                                      ? Icons.favorite_border
                                      : isMovieFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // logged in and rated
                        if (isUserLoggedIn == true &&
                            isMovieRated != false &&
                            userRating != null)
                          Positioned(
                            top: 40,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              child: TvFocusWrapper(
                                borderRadius: 30.0,
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: RatingBar.builder(
                                            initialRating: userRating,
                                            minRating: 1,
                                            maxRating: 10,
                                            itemSize: 35,
                                            unratedColor: Colors.grey,
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            itemCount: 10,
                                            itemPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 0),
                                            itemBuilder: (context, _) =>
                                                const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            onRatingUpdate: (rating) async {
                                              final movieId = widget.movieId;
                                              final openbox =
                                                  Hive.box('sessionBox');

                                              final String sessionData =
                                                  openbox.get('sessionData');
                                              addRating(sessionData, movieId,
                                                  rating, context);
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
                                            final openbox = Hive.box('sessionBox');

                                            final String sessionData =
                                                openbox.get('sessionData');
                                            removeRating(sessionData,
                                                widget.movieId, context);
                                            Navigator.of(context).pop();
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
                                                fontWeight: FontWeight.bold,
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                            ),
                          ),

                        Positioned(
                          top: 40,
                          left: 20,
                          child: TvFocusWrapper(
                            borderRadius: 30.0,
                            onTap: isWatched ? state._removeFromWatched : state._markAsWatched,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isWatched ? Colors.green.withValues(alpha: 0.7) : Colors.black38,
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
                        ),
                        //logged in not rated
                        if (isUserLoggedIn == true &&
                            isMovieRated == false &&
                            userRating == null)
                          Positioned(
                            top: 40,
                            right: 30,
                            child: TvFocusWrapper(
                                  borderRadius: 30.0,
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            RatingBar.builder(
                                              initialRating: 5,
                                              minRating: 1,
                                              maxRating: 10,
                                              itemSize: 35,
                                              unratedColor: Colors.grey,
                                              direction: Axis.horizontal,
                                              allowHalfRating: true,
                                              itemCount: 10,
                                              itemPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 0),
                                              itemBuilder: (context, _) =>
                                                  const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                              onRatingUpdate: (rating) async {
                                                final movieId =
                                                    widget.movieId;
                                                final openbox =
                                                    Hive.box('sessionBox');

                                                final String sessionData =
                                                    openbox
                                                        .get('sessionData');
                                                addRating(sessionData,
                                                    movieId, rating, context);
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
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.add_reaction,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          ),
                      ],
                    ),
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            (genres as List<dynamic>).map<Widget>((genre) {
                          return Text(
                            genre['name'] + ' | ',
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w200),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const CustomDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          about!,
                          style:
                              getMovieAboutTextStyle(context, widget.movieId),
                          textAlign: TextAlign.left,
                        )),
                  ),
                  const CustomDivider(),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                            decoration: BoxDecoration(
                              color: getMovieBackgroundColor(
                                  context, widget.movieId),
                              borderRadius: BorderRadius.circular(10),
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
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${hours}H ${minutes}M",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
                            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                            decoration: BoxDecoration(
                              color: getMovieBackgroundColor(
                                  context, widget.movieId),
                              borderRadius: BorderRadius.circular(10),
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
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    year,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
                            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                            decoration: BoxDecoration(
                              color: getMovieBackgroundColor(
                                  context, widget.movieId),
                              borderRadius: BorderRadius.circular(10),
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
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    language != null
                                        ? language.toUpperCase()
                                        : 'N/A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: FutureBuilder(
                              future: availabilityFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // Display loading indicator while fetching data
                                  return const SizedBox();
                                } else if (snapshot.hasError) {
                                  // Display error message if fetching data fails
                                  return const Text('Error loading data');
                                } else {
                                  // Display check mark if results are not empty
                                  return snapshot.data == true
                                      ? SizedBox(
                                          width: double.maxFinite,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.max,

                                            children: [
                                              Expanded(
                                                child: FloatingActionButton(
                                                  heroTag: null,
                                                  backgroundColor: getMovieColor(
                                                      context, widget.movieId),
                                                  onPressed: () => showWatchOptions(
                                                      context,
                                                      widget.movieId,
                                                      widget.movieTitle,
                                                      releaseDate ?? '',
                                                      imdbId ?? ''),
                                                  child: Text(
                                                    'Watch',
                                                    style: getMovieButtonTextStyle(
                                                        widget.movieId),
                                                  ),
                                                ),
                                              ),

                                            ],
                                          ),
                                        )
                                      : const SizedBox();
                                }
                              }),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: SizedBox(
                                width: double.maxFinite,
                                child: FloatingActionButton(
                                  heroTag: null,
                                  backgroundColor:
                                      getMovieColor(context, widget.movieId),
                                  onPressed: () => showTorrentOptions(
                                      context,
                                      widget.movieId,
                                      widget.movieTitle,
                                      releaseDate,
                                      imdbId),
                                  child: Text(
                                    'Torrent Search',
                                    style:
                                        getMovieButtonTextStyle(widget.movieId),
                                  ),
                                )))
                      ],
                    ),
                  ),
                  FutureBuilder(
                    future: creditsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (castList.isNotEmpty) ...[
                              Row(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(25, 15, 0, 0),
                                    child: Text(
                                      'Cast',
                                      textAlign: TextAlign.justify,
                                      style:
                                          getMovieTitleTextStyle(widget.movieId),
                                    ),
                                  ),
                                ],
                              ),
                              const CustomDivider(),
                              buildCastRow(castList, context),
                            ],
                            if (crewList.isNotEmpty) ...[
                              Row(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(25, 15, 0, 0),
                                    child: Text(
                                      'Crew',
                                      textAlign: TextAlign.justify,
                                      style:
                                          getMovieTitleTextStyle(widget.movieId),
                                    ),
                                  ),
                                ],
                              ),
                              const CustomDivider(),
                              buildCrewRow(crewList, context),
                            ],
                          ],
                        );
                      }
                    },
                  ),
                  const CustomDivider(),
                  FutureBuilder(
                    future: creditsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                                      const EdgeInsets.fromLTRB(25, 15, 10, 0),
                                  child: Text(
                                    "Movies by ${director['name']}",
                                    style:
                                        getMovieTitleTextStyle(widget.movieId),
                                  ),
                                ),
                              ),
                              directorMoviesFuture == null
                                  ? const Center(child: CircularProgressIndicator())
                                  : FutureBuilder(
                                      future: directorMoviesFuture,
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
                                                  TvFocusWrapper(
                                                     onTap: () => state.onTapMovie(
                                                         movie['title'],
                                                         movie['id']),
                                                     child: Card(
                                                       child: SizedBox(
                                                          height: 200,
                                                          width: 100,
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(20),
                                                            child: movie['poster_path'].isNotEmpty
                                                                ? CachedNetworkImage(
                                                                    imageUrl: '${getImageBaseUrl(region)}/t/p/w200${movie['poster_path']}',
                                                                    fit: BoxFit.cover,
                                                                    placeholder: (context, url) => Skeletonizer(
                                                                      enabled: true,
                                                                      containersColor: Colors.white.withOpacity(0.05),
                                                                      effect: ShimmerEffect(
                                                                        baseColor: Colors.white.withOpacity(0.05),
                                                                        highlightColor: Colors.white.withOpacity(0.15),
                                                                      ),
                                                                      child: Container(
                                                                        color: Colors.grey[900],
                                                                      ),
                                                                    ),
                                                                    errorWidget: (context, url, error) => Container(
                                                                      color: Colors.grey[900],
                                                                      child: const Icon(Icons.error),
                                                                    ),
                                                                  )
                                                                : Container(
                                                                    color: Colors.grey[900],
                                                                  ),
                                                          ),
                                                        ),
                                                     ),
                                                   ),
                                                  SizedBox(
                                                    width: 70,
                                                    child: Text(
                                                      movie['title'],
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 10,
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
                        title: Text(
                          'Other Info',
                          style: getMovieTitleTextStyle(widget.movieId),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(25, 10, 0, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      children:
                                          (productionCountries as List<dynamic>)
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
                                              .map<Widget>((productionCompany) {
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
            );

    return Scaffold(
      extendBody: true,
      //only show appbar on ios and web
      appBar: AppPlatform.isIOS || AppPlatform.isWeb ?
      AppBar(
        automaticallyImplyLeading: true,
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
      )
      : null,
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

  Widget _buildScreenShotImage(BuildContext context) {
    final widget = state.widget;
    final duration = state.duration;
    final releaseDate = state.releaseDate;
    final backdrops = state.backdrops;
    final genres = state.genres;
    final about = state.about;

    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;

    int? hours = duration != null ? duration ~/ 60 : null;
    int? minutes = duration != null ? duration % 60 : null;
    String year = releaseDate != null && releaseDate.isNotEmpty
        ? releaseDate.substring(0, 4)
        : 'NA';

    return Container(
      constraints: const BoxConstraints(maxHeight: 800),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        color: Colors.black,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(children: [
            CachedNetworkImage(
              imageUrl: '${getImageBaseUrl(region)}/t/p/original$backdrops',
              placeholder: (context, url) => Skeletonizer(
                enabled: true,
                containersColor: Colors.white.withOpacity(0.05),
                effect: ShimmerEffect(
                  baseColor: Colors.white.withOpacity(0.05),
                  highlightColor: Colors.white.withOpacity(0.15),
                ),
                child: Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.grey[900],
                ),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              imageBuilder: (context, imageProvider) => Container(
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
            Container(
              height: 320,
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
              bottom: 28,
              left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    width: MediaQuery.of(context).size.width - 20,
                    child: Text(
                      widget.movieTitle,
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: (genres as List<dynamic>).map<Widget>((genre) {
                return Text(
                  genre['name'] + ' | ',
                  softWrap: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'RobotoMono'),
                );
              }).toList(),
            ),
          ),
          const CustomDivider(),
          Container(
            alignment: Alignment.center,
            child: Text(
              about!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w200,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.left,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const CustomDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: 110,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: BoxDecoration(
                    color: getMovieBackgroundColor(context, widget.movieId),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "${hours}H ${minutes}M",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
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
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: BoxDecoration(
                    color: getMovieBackgroundColor(context, widget.movieId),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Year',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          year,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
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
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: BoxDecoration(
                    color: getMovieBackgroundColor(context, widget.movieId),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Language',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          state.language != null ? state.language!.toUpperCase() : 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
