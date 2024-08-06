import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Mirarr/widgets/bottom_bar.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webfeed_plus/domain/rss_category.dart';
import 'package:webfeed_plus/domain/rss_feed.dart';

class RssScreen extends StatefulWidget {
  RssScreen({Key? key}) : super(key: key);

  @override
  _RssScreenState createState() => _RssScreenState();
}

class _RssScreenState extends State<RssScreen> with TickerProviderStateMixin {
  late Future<RssFeed> _feedFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _feedFuture = _loadFeed();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrlString(url.toString())) {
      await launchUrlString(url.toString());
    } else {
      throw Exception('Could not launch url');
    }
  }

  Future<RssFeed> _loadFeed() async {
    final response = await http.get(Uri.parse('https://www.scnsrc.me/feed'));
    if (response.statusCode == 200) {
      return RssFeed.parse(response.body);
    } else {
      throw Exception('Failed to load RSS feed');
    }
  }

  Icon _getCategoryIcon(List<RssCategory>? categories) {
    if (categories != null) {
      for (var category in categories) {
        if (category.value.contains("Movies")) {
          return Icon(
            Icons.movie,
            color: Theme.of(context).secondaryHeaderColor,
          );
        } else if (category.value.contains("TV")) {
          return Icon(
            Icons.tv,
            color: Theme.of(context).secondaryHeaderColor,
          );
        }
      }
    }
    return const Icon(Icons.info);
  }

  Widget _buildFeedList(RssFeed feed, String category) {
    final filteredItems = feed.items!.where((item) {
      final categories = item.categories ?? [];
      return categories.any((cat) => cat.value.contains(category));
    }).toList();

    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return ListTile(
          leading: _getCategoryIcon(item.categories),
          title: Text(
            item.title ?? '',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            item.pubDate.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          onTap: () {
            _launchUrl(Uri.parse(item.link!));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'RSS Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          labelColor: Colors.black,
          indicatorSize: TabBarIndicatorSize.tab,
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Movies',
            ),
            Tab(text: 'TV'),
          ],
        ),
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(),
          scrollbars: true,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: FutureBuilder(
          future: _feedFuture,
          builder: (context, AsyncSnapshot<RssFeed> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final feed = snapshot.requireData;
              return Builder(
                builder: (context) => TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFeedList(feed, "Movies"),
                    _buildFeedList(feed, "TV"),
                  ],
                ),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
