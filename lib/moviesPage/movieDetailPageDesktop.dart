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
    final availabilityFuture = state._availabilityFuture;
    final creditsFuture = state._creditsFuture;
    final directorMoviesFuture = state._directorMoviesFuture;
    final castImagesFuture = state._castImagesFuture;
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
                                placeholder: (context, url) => Skeletonizer(
                                  enabled: true,
                                  containersColor: Colors.white.withOpacity(0.05),
                                  effect: ShimmerEffect(
                                    baseColor: Colors.white.withOpacity(0.05),
                                    highlightColor: Colors.white.withOpacity(0.15),
                                  ),
                                  child: Container(
                                    height: 800,
                                    width: 600,
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20)),
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
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
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.movieTitle,
                                        style: getMovieTitleTextStyle(widget.movieId),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            year,
                                            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                                          ),
                                          if (hours != null) ...[
                                            const Text('•', style: TextStyle(color: Colors.white38, fontSize: 16)),
                                            Text(
                                              "${hours}H ${minutes}M",
                                              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                          if (genres != null && (genres).isNotEmpty) ...[
                                            const Text('•', style: TextStyle(color: Colors.white38, fontSize: 16)),
                                            Text(
                                              (genres).map((g) => g['name']).join(', '),
                                              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w300),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          if (score != null)
                                            _buildRatingBadge(
                                              label: 'TMDB',
                                              score: score.toStringAsFixed(1),
                                              icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                              context: context,
                                            ),
                                          if (imdbRating != null && imdbRating.isNotEmpty)
                                            _buildRatingBadge(
                                              label: 'IMDb',
                                              score: imdbRating,
                                              icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                              context: context,
                                            ),
                                          if (rottenTomatoesRating != 'N/A')
                                            _buildRatingBadge(
                                              label: 'Rotten Tomatoes',
                                              score: rottenTomatoesRating,
                                              icon: const Text('🍅', style: TextStyle(fontSize: 14)),
                                              context: context,
                                            ),
                                          if (isUserLoggedIn == true && isMovieRated != false && userRating != null)
                                            GestureDetector(
                                              onTap: () => showModalBottomSheet(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const SizedBox(height: 20),
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
                                                          itemPadding: const EdgeInsets.symmetric(horizontal: 0),
                                                          itemBuilder: (context, _) => const Icon(
                                                            Icons.star,
                                                            color: Colors.amber,
                                                          ),
                                                          onRatingUpdate: (rating) async {
                                                            final movieId = widget.movieId;
                                                            final openbox = Hive.box('sessionBox');
                                                            final String sessionData = openbox.get('sessionData');
                                                            addRating(sessionData, movieId, rating, context);
                                                            state.updateState(() {
                                                              state.isMovieRated = {'value': rating};
                                                              state.userRating = rating;
                                                              profileRefreshNotifier.value++;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      const CustomDivider(),
                                                      const SizedBox(height: 10),
                                                      GestureDetector(
                                                        onTap: () async {
                                                          final openbox = Hive.box('sessionBox');
                                                          final String sessionData = openbox.get('sessionData');
                                                          removeRating(sessionData, widget.movieId, context);
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
                                                      const SizedBox(height: 20),
                                                    ],
                                                  );
                                                },
                                              ),
                                              child: _buildRatingBadge(
                                                label: 'User',
                                                score: userRating.toStringAsFixed(1),
                                                icon: const Icon(Icons.person_rounded, color: Colors.blueAccent, size: 18),
                                                context: context,
                                              ),
                                            ),
                                          _buildWatchedButton(
                                            isWatched: isWatched,
                                            onTap: isWatched ? state._removeFromWatched : state._markAsWatched,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        spacing: 12,
                                        children: [
                                          _buildActionButton(
                                            icon: Icons.image_rounded,
                                            iconColor: Colors.white,
                                            tooltip: 'View Gallery',
                                            onTap: () {
                                              castImagesFuture.then((imageUrls) {
                                                state._openImageGallery(imageUrls);
                                              });
                                            },
                                          ),
                                          if (isUserLoggedIn == true) ...[
                                            _buildActionButton(
                                              icon: isMovieWatchlist == true ? Icons.bookmark : Icons.bookmark_border,
                                              iconColor: isMovieWatchlist == true ? Theme.of(context).primaryColor : Colors.white,
                                              tooltip: isMovieWatchlist == true ? 'Remove from Watchlist' : 'Add to Watchlist',
                                              onTap: () async {
                                                if (isMovieWatchlist == null) return;
                                                final movieId = widget.movieId;
                                                final openbox = Hive.box('sessionBox');
                                                final String accountId = openbox.get('accountId');
                                                final String sessionData = openbox.get('sessionData');
                                                if (isMovieWatchlist) {
                                                  state.updateState(() {
                                                    state.isMovieWatchlist = false;
                                                  });
                                                  await removeFromWatchList(accountId, sessionData, movieId, context);
                                                  profileRefreshNotifier.value++;
                                                } else {
                                                  state.updateState(() {
                                                    state.isMovieWatchlist = true;
                                                  });
                                                  await addWatchList(accountId, sessionData, movieId, context);
                                                  profileRefreshNotifier.value++;
                                                }
                                              },
                                            ),
                                            _buildActionButton(
                                              icon: isMovieFavorite == true ? Icons.favorite : Icons.favorite_border,
                                              iconColor: isMovieFavorite == true ? Colors.redAccent : Colors.white,
                                              tooltip: isMovieFavorite == true ? 'Remove from Favorites' : 'Add to Favorites',
                                              onTap: () async {
                                                if (isMovieFavorite == null) return;
                                                final movieId = widget.movieId;
                                                final openbox = Hive.box('sessionBox');
                                                final String accountId = openbox.get('accountId');
                                                final String sessionData = openbox.get('sessionData');
                                                if (isMovieFavorite) {
                                                  removeFromFavorite(accountId, sessionData, movieId, context);
                                                  state.updateState(() {
                                                    state.isMovieFavorite = false;
                                                    profileRefreshNotifier.value++;
                                                  });
                                                } else {
                                                  addFavorite(accountId, sessionData, movieId, context);
                                                  state.updateState(() {
                                                    state.isMovieFavorite = true;
                                                    profileRefreshNotifier.value++;
                                                  });
                                                }
                                              },
                                            ),
                                            if (isMovieRated == false && userRating == null)
                                              _buildActionButton(
                                                icon: Icons.add_reaction_rounded,
                                                iconColor: Colors.white,
                                                tooltip: 'Rate Movie',
                                                onTap: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const SizedBox(height: 20),
                                                          RatingBar.builder(
                                                            initialRating: 5,
                                                            minRating: 1,
                                                            maxRating: 10,
                                                            itemSize: 35,
                                                            unratedColor: Colors.grey,
                                                            direction: Axis.horizontal,
                                                            allowHalfRating: true,
                                                            itemCount: 10,
                                                            itemPadding: const EdgeInsets.symmetric(horizontal: 0),
                                                            itemBuilder: (context, _) => const Icon(
                                                              Icons.star,
                                                              color: Colors.amber,
                                                            ),
                                                            onRatingUpdate: (rating) async {
                                                              final movieId = widget.movieId;
                                                              final openbox = Hive.box('sessionBox');
                                                              final String sessionData = openbox.get('sessionData');
                                                              addRating(sessionData, movieId, rating, context);
                                                              state.updateState(() {
                                                                state.isMovieRated = '"value":$rating';
                                                                state.userRating = rating;
                                                                profileRefreshNotifier.value++;
                                                              });
                                                            },
                                                          ),
                                                          const SizedBox(height: 40),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: [
                                          FutureBuilder(
                                            future: availabilityFuture,
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError || snapshot.data != true) {
                                                return const SizedBox();
                                              }
                                              return _buildPrimaryButton(
                                                text: 'Watch',
                                                backgroundColor: getMovieColor(context, widget.movieId),
                                                textStyle: getMovieButtonTextStyle(widget.movieId),
                                                icon: Icons.play_arrow_rounded,
                                                onPressed: () => showWatchOptions(
                                                  context,
                                                  widget.movieId,
                                                  widget.movieTitle,
                                                  releaseDate ?? '',
                                                  imdbId ?? '',
                                                ),
                                              );
                                            },
                                          ),
                                          _buildSecondaryButton(
                                            text: 'Torrent Search',
                                            textStyle: getMovieButtonTextStyle(widget.movieId),
                                            icon: Icons.search_rounded,
                                            onPressed: () => showTorrentOptions(
                                              context,
                                              widget.movieId,
                                              widget.movieTitle,
                                              releaseDate,
                                              imdbId,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (about != null && about.isNotEmpty) ...[
                                        const SizedBox(height: 24),
                                        const Text(
                                          'Overview',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 800),
                                          child: Text(
                                            about,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.8),
                                              fontSize: 16,
                                              height: 1.5,
                                              fontWeight: FontWeight.w300,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: [
                                          if (hours != null)
                                            _buildInfoCard(
                                              title: 'DURATION',
                                              value: "${hours}H ${minutes}M",
                                            ),
                                          _buildInfoCard(
                                            title: 'YEAR',
                                            value: year,
                                          ),
                                          _buildInfoCard(
                                            title: 'LANGUAGE',
                                            value: language != null ? language.toUpperCase() : 'N/A',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    FutureBuilder(
                      future: creditsFuture,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (castList.isNotEmpty) ...[
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
                              ],
                              if (crewList.isNotEmpty) ...[
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
                                buildCrewRowDesktop(crewList, context),
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
                                                    Card(
                                                      elevation: 4,
                                                      child: GestureDetector(
                                                        onTap: () => state.onTapMovie(
                                                            movie['title'],
                                                            movie['id']),
                                                        child: SizedBox(
                                                          height: 300,
                                                          width: 200,
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

  Widget _buildRatingBadge({
    required String label,
    required String score,
    required Widget icon,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            label.isNotEmpty ? "$label $score" : score,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildWatchedButton({
    required bool isWatched,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isWatched ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWatched ? Colors.green.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWatched ? Icons.check_circle_rounded : Icons.visibility_outlined,
              color: isWatched ? Colors.green : Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isWatched ? 'Watched' : 'Mark as Watched',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isWatched ? Colors.green : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required Color backgroundColor,
    required TextStyle textStyle,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textStyle.color, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: textStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required TextStyle textStyle,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
