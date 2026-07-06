part of 'serieDetailPage.dart';

class _SerieDetailPageMobile extends StatelessWidget {
  final _SerieDetailPageState state;

  const _SerieDetailPageMobile(this.state);

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final serieDetails = state.serieDetails;
    final backdrops = state.backdrops;
    final posterPath = state.posterPath;
    final score = state.score;
    final imdbRating = state.imdbRating;
    final rottenTomatoesRating = state.rottenTomatoesRating;
    final isUserLoggedIn = state.isUserLoggedIn;
    final isSerieWatchlist = state.isSerieWatchlist;
    final isSerieFavorite = state.isSerieFavorite;
    final isSerieRated = state.isSerieRated;
    final userRating = state.userRating;
    final genres = state.genres;
    final about = state.about;
    final seasons = state.seasons;
    final episodes = state.episodes;
    final language = state.language;
    final imdbId = state.imdbId;
    final _creditsFuture = state._creditsFuture;
    final _showWatchToggleKey = state._showWatchToggleKey;
    final screenShotController = state.screenShotController;

    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;

    final bool isTv = TvFocusModeManager.isTvDevice;

    final Widget bodyContent = serieDetails == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl:
                            '${getImageBaseUrl(region)}/t/p/original$backdrops',
                        placeholder: (context, url) => const Center(
                            child:
                                CircularProgressIndicator()), // Placeholder widget while loading.
                        errorWidget: (context, url, error) => const Icon(Icons
                            .error), // Widget to display when there's an error loading the image.
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
                              fontSize: 13,
                              color: Colors
                                  .white, // Text color on top of the image
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: imdbRating != null &&
                            imdbRating.isNotEmpty &&
                            imdbRating != 'N/A',
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
                                fontSize: 13,
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
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
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
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                              ),
                              width: MediaQuery.of(context).size.width - 20,
                              child: Text(
                                widget.serieName,
                                softWrap: true,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: getSeriesTitleTextStyle(widget.serieId),
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
                                          borderRadius: const BorderRadius.only(
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
                                                  ShareContent.shareTVShow(
                                                      widget.serieId);
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
                                                      .sharePartialScreenshotTV(
                                                    screenShotController,
                                                    _buildScreenShotImage(context),
                                                    widget.serieId,
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
                              if (isSerieWatchlist == null) {
                                  return;
                              }
                              final movieId = widget.serieId;
                              final openbox = Hive.box('sessionBox');
                              final String accountId = openbox.get('accountId');
                              final String sessionData =
                                  openbox.get('sessionData');
                              if (isSerieWatchlist) {
                                // Remove from watchlist
                                state.updateState(() {
                                  state.isSerieWatchlist = false;
                                });
                                await removeFromWatchList(
                                    accountId, sessionData, movieId, context);
                                profileRefreshNotifier.value++;
                              } else {
                                // Add to watchlist
                                state.updateState(() {
                                  state.isSerieWatchlist = true;
                                });
                                await addWatchList(
                                    accountId, sessionData, movieId, context);
                                profileRefreshNotifier.value++;
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                isSerieWatchlist == null
                                    ? Icons.bookmark_border
                                    : isSerieWatchlist
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
                              if (isSerieFavorite == null) {
                                return;
                              }
                              final movieId = widget.serieId;
                              final openbox = Hive.box('sessionBox');
                              final String accountId = openbox.get('accountId');
                              final String sessionData =
                                  openbox.get('sessionData');
                              if (isSerieFavorite) {
                                state.updateState(() {
                                  state.isSerieFavorite = false;
                                });
                                await removeFromFavorite(
                                    accountId, sessionData, movieId, context);
                                profileRefreshNotifier.value++;
                              } else {
                                state.updateState(() {
                                  state.isSerieFavorite = true;
                                });
                                await addFavorite(
                                    accountId, sessionData, movieId, context);
                                profileRefreshNotifier.value++;
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                isSerieFavorite == null
                                    ? Icons.favorite_border
                                    : isSerieFavorite
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
                          isSerieRated != false &&
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
                                            final movieId = widget.serieId;
                                            final openbox = Hive.box('sessionBox');
                                            final String sessionData =
                                                openbox.get('sessionData');
                                            addRating(sessionData, movieId,
                                                rating, context);
                                            state.updateState(() {
                                              state.isSerieRated = {'value': rating};
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

                                          final String sessionData =
                                              openbox.get('sessionData');
                                          removeRating(sessionData,
                                              widget.serieId, context);
                                          Navigator.of(context).pop();
                                          state.updateState(() {
                                            state.isSerieRated = false;
                                            state.userRating = null;
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
                      //logged in not rated
                      if (isUserLoggedIn == true &&
                          isSerieRated == false &&
                          userRating == null)
                        Positioned(
                          top: 40,
                          right: 30,
                          child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
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
                                                final movieId = widget.serieId;
                                                final openbox = Hive.box('sessionBox');

                                                final String sessionData =
                                                    openbox.get('sessionData');
                                                state.updateState(() {
                                                  state.isSerieRated = '"value":$rating';
                                                  state.userRating = rating;
                                                });
                                                await addRating(sessionData, movieId,
                                                    rating, context);
                                                profileRefreshNotifier.value++;
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
                            ),


                        Positioned(
                          top: 40,
                          left: 20,
                          child: ShowWatchToggle(
                            key: _showWatchToggleKey,
                            serieId: widget.serieId,
                            serieName: widget.serieName,
                            posterPath: posterPath,
                            onToggle: () {
                              // The widget handles its own state, no need to call _checkShowWatchedStatus
                            },
                          ),
                        ),
                    ],
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
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
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Divider(color: Colors.white60, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          about!,
                          style:
                              getSeriesAboutTextStyle(context, widget.serieId),
                          textAlign: TextAlign.left,
                        )),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Divider(color: Colors.white60, thickness: 1),
                  ),
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
                              color: getSeriesBackgroundColor(
                                  context, widget.serieId),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Seasons',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '$seasons',
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
                              color: getSeriesBackgroundColor(
                                  context, widget.serieId),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Episodes',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '$episodes',
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
                              color: getSeriesBackgroundColor(
                                  context, widget.serieId),
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
                            child: SizedBox(
                          width: double.maxFinite,
                          child: FloatingActionButton(
                            heroTag: null,
                            backgroundColor:
                                getSeriesColor(context, widget.serieId),
                            onPressed: () => seasonsAndEpisodes(context,
                                widget.serieId, widget.serieName, imdbId!,
                                imagePath: backdrops,
                                onWatchStatusChanged: state._refreshShowWatchStatus),
                            child: Text(
                              'Details',
                              style: getSeriesButtonTextStyle(widget.serieId),
                            ),
                          ),
                        ))
                      ],
                    ),
                  ),
                  FutureBuilder(
                    future: _creditsFuture,
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
                          children: [
                            Row(
                              children: [
                                Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(25, 10, 0, 0),
                                    child: Text(
                                      'Cast',
                                      textAlign: TextAlign.justify,
                                      style: getSeriesTitleTextStyle(
                                          widget.serieId),
                                    )),
                              ],
                            ),
                            const CustomDivider(),
                            buildCastRow(castList, context),
                            Row(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(25, 10, 0, 0),
                                  child: Text(
                                    'Crew',
                                    textAlign: TextAlign.justify,
                                    style:
                                        getSeriesTitleTextStyle(widget.serieId),
                                  ),
                                ),
                              ],
                            ),
                            const CustomDivider(),
                            buildCrewRow(crewList, context)
                          ],
                        );
                      }
                    },
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
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: Text(
              widget.serieName,
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
    final backdrops = state.backdrops;
    final genres = state.genres;
    final about = state.about;
    final seasons = state.seasons;
    final episodes = state.episodes;
    final language = state.language;

    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;

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
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
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
                      widget.serieName,
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
                    color: getSeriesBackgroundColor(context, widget.serieId),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Seasons',
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
                          '$seasons',
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
                    color: getSeriesBackgroundColor(context, widget.serieId),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Episodes',
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
                          '$episodes',
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
                    color: getSeriesBackgroundColor(context, widget.serieId),
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
                          language != null ? language.toUpperCase() : 'N/A',
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
