part of 'serieDetailPage.dart';

class _SerieDetailPageDesktop extends StatelessWidget {
  final _SerieDetailPageState state;

  const _SerieDetailPageDesktop(this.state);

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
    final _showWatchToggleRefreshCounter = state._showWatchToggleRefreshCounter;

    final region =
        Provider.of<RegionProvider>(context, listen: false).currentRegion;

    final bool isTv = TvFocusModeManager.isTvDevice;

    final Widget bodyContent = serieDetails == null
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
                              '${getImageBaseUrl(region)}/t/p/original$backdrops',
                            ),
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
                                    '${getImageBaseUrl(region)}/t/p/original$posterPath',
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
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.serieName,
                                        style: getSeriesTitleTextStyle(widget.serieId),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      if (genres != null && (genres as List<dynamic>).isNotEmpty) ...[
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              (genres as List<dynamic>).map((g) => g['name']).join(', '),
                                              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w300),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                      ],
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
                                          if (isUserLoggedIn == true && isSerieRated != false && userRating != null)
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
                                                            final serieId = widget.serieId;
                                                            final openbox = Hive.box('sessionBox');
                                                            final String sessionData = openbox.get('sessionData');
                                                            addRating(sessionData, serieId, rating, context);
                                                            state.updateState(() {
                                                              state.isSerieRated = {'value': rating};
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
                                                          removeRating(sessionData, widget.serieId, context);
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
                                          ShowWatchToggle(
                                            key: ValueKey('show_watch_toggle_$_showWatchToggleRefreshCounter'),
                                            serieId: widget.serieId,
                                            serieName: widget.serieName,
                                            posterPath: posterPath,
                                            onToggle: () {
                                              // The widget handles its own state
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (isUserLoggedIn == true) ...[
                                        Row(
                                          spacing: 12,
                                          children: [
                                            _buildActionButton(
                                              icon: isSerieWatchlist == true ? Icons.bookmark : Icons.bookmark_border,
                                              iconColor: isSerieWatchlist == true ? Theme.of(context).primaryColor : Colors.white,
                                              tooltip: isSerieWatchlist == true ? 'Remove from Watchlist' : 'Add to Watchlist',
                                              onTap: () async {
                                                if (isSerieWatchlist == null) return;
                                                final serieId = widget.serieId;
                                                final openbox = Hive.box('sessionBox');
                                                final String accountId = openbox.get('accountId');
                                                final String sessionData = openbox.get('sessionData');
                                                if (isSerieWatchlist) {
                                                  state.updateState(() {
                                                    state.isSerieWatchlist = false;
                                                  });
                                                  await removeFromWatchList(accountId, sessionData, serieId, context);
                                                  profileRefreshNotifier.value++;
                                                } else {
                                                  state.updateState(() {
                                                    state.isSerieWatchlist = true;
                                                  });
                                                  await addWatchList(accountId, sessionData, serieId, context);
                                                  profileRefreshNotifier.value++;
                                                }
                                              },
                                            ),
                                            _buildActionButton(
                                              icon: isSerieFavorite == true ? Icons.favorite : Icons.favorite_border,
                                              iconColor: isSerieFavorite == true ? Colors.redAccent : Colors.white,
                                              tooltip: isSerieFavorite == true ? 'Remove from Favorites' : 'Add to Favorites',
                                              onTap: () async {
                                                if (isSerieFavorite == null) return;
                                                final serieId = widget.serieId;
                                                final openbox = Hive.box('sessionBox');
                                                final String accountId = openbox.get('accountId');
                                                final String sessionData = openbox.get('sessionData');
                                                if (isSerieFavorite) {
                                                  state.updateState(() {
                                                    state.isSerieFavorite = false;
                                                  });
                                                  await removeFromFavorite(accountId, sessionData, serieId, context);
                                                  profileRefreshNotifier.value++;
                                                } else {
                                                  state.updateState(() {
                                                    state.isSerieFavorite = true;
                                                  });
                                                  await addFavorite(accountId, sessionData, serieId, context);
                                                  profileRefreshNotifier.value++;
                                                }
                                              },
                                            ),
                                            if (isSerieRated == false && userRating == null)
                                              _buildActionButton(
                                                icon: Icons.add_reaction_rounded,
                                                iconColor: Colors.white,
                                                tooltip: 'Rate Show',
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
                                                              final serieId = widget.serieId;
                                                              final openbox = await Hive.openBox('sessionBox');
                                                              final String sessionData = openbox.get('sessionData');
                                                              addRating(sessionData, serieId, rating, context);
                                                              state.updateState(() {
                                                                state.isSerieRated = '"value":$rating';
                                                                state.userRating = rating;
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
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                      _buildPrimaryButton(
                                        text: 'Details',
                                        backgroundColor: getSeriesColor(context, widget.serieId),
                                        textStyle: getSeriesButtonTextStyle(widget.serieId),
                                        icon: Icons.info_outline_rounded,
                                        onPressed: () => seasonsAndEpisodes(
                                          context,
                                          widget.serieId,
                                          widget.serieName,
                                          imdbId!,
                                          imagePath: backdrops,
                                          onWatchStatusChanged: state._refreshShowWatchStatus,
                                        ),
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
                                              color: Colors.white.withOpacity(0.8),
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
                                          _buildInfoCard(
                                            title: 'SEASONS',
                                            value: '$seasons',
                                          ),
                                          _buildInfoCard(
                                            title: 'EPISODES',
                                            value: '$episodes',
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
                                        style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontSize: AppPlatform.isAndroid ||
                                                    AppPlatform.isIOS
                                                ? 18
                                                : 30,
                                            fontWeight: FontWeight.w700),
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
                                        style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontSize: AppPlatform.isAndroid ||
                                                    AppPlatform.isIOS
                                                ? 18
                                                : 30,
                                            fontWeight: FontWeight.w700),
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
                  ],
                ),
              ),
            );

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
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
      ),
      body: isTv
          ? Column(
              children: [
                const BottomBar(),
                Expanded(child: bodyContent),
              ],
            )
          : bodyContent,
      bottomNavigationBar: isTv ? null : BottomBar(),
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
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
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
              color: backgroundColor.withOpacity(0.3),
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

  Widget _buildInfoCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
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
