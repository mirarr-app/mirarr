import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Mirarr/functions/regionprovider_class.dart';
import 'package:Mirarr/services/api_client.dart';
import 'package:Mirarr/widgets/discover/discover_with_filters.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'TMDB_API_KEY=test_api_key\n');
  });

  Widget createTestWidget({required ApiClient client, Size size = const Size(1200, 900)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: ChangeNotifierProvider(
        create: (_) => RegionProvider('worldwide'),
        child: MaterialApp(
          home: Scaffold(
            body: DiscoverMoviesPage(client: client),
          ),
        ),
      ),
    );
  }

  testWidgets('renders TMDB Rating section and default 0.0 - 10.0 range',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    expect(find.text('TMDB Rating'), findsOneWidget);
    expect(find.text('0.0 - 10.0'), findsOneWidget);
    expect(find.byType(RangeSlider), findsNWidgets(2)); // Year range + Rating range
  });

  testWidgets('loads page 1 and shows Load More button when total_pages > 1',
      (WidgetTester tester) async {
    final List<Uri> requestedUrls = [];

    final mockClient = MockClient((request) async {
      requestedUrls.add(request.url);
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        return http.Response(
          json.encode({
            'page': 1,
            'total_pages': 3,
            'results': [
              {
                'id': 101,
                'title': 'Test Movie 1',
                'release_date': '2024-01-01',
                'poster_path': '',
                'overview': 'Overview 1',
                'vote_average': 8.2,
              },
              {
                'id': 102,
                'title': 'Test Movie 2',
                'release_date': '2024-02-01',
                'poster_path': '',
                'overview': 'Overview 2',
                'vote_average': 7.5,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    // Tap Search Movies button
    final searchButton = find.widgetWithText(ElevatedButton, 'Search Movies');
    expect(searchButton, findsOneWidget);
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    // Verify discover request was made for page 1
    final discoverUrl = requestedUrls.firstWhere((u) => u.path.contains('discover/movie'));
    expect(discoverUrl.queryParameters['page'], '1');
    // Default rating range 0.0-10.0 shouldn't restrict rating params
    expect(discoverUrl.queryParameters.containsKey('vote_average.gte'), isFalse);
    expect(discoverUrl.queryParameters.containsKey('vote_average.lte'), isFalse);

    // Verify movies are displayed
    expect(find.text('Test Movie 1'), findsOneWidget);
    expect(find.text('Test Movie 2'), findsOneWidget);

    // Verify Load More button is shown with next page info
    expect(find.text('Load More (Page 2 of 3)'), findsOneWidget);
  });

  testWidgets('clicking Load More fetches page 2 and appends items',
      (WidgetTester tester) async {
    final List<Uri> requestedUrls = [];

    final mockClient = MockClient((request) async {
      requestedUrls.add(request.url);
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        final page = request.url.queryParameters['page'];
        if (page == '1') {
          return http.Response(
            json.encode({
              'page': 1,
              'total_pages': 2,
              'results': [
                {
                  'id': 201,
                  'title': 'Page One Movie',
                  'release_date': '2023-05-01',
                  'poster_path': '',
                  'overview': 'P1',
                  'vote_average': 7.0,
                },
              ],
            }),
            200,
          );
        } else if (page == '2') {
          return http.Response(
            json.encode({
              'page': 2,
              'total_pages': 2,
              'results': [
                {
                  'id': 202,
                  'title': 'Page Two Movie',
                  'release_date': '2023-06-01',
                  'poster_path': '',
                  'overview': 'P2',
                  'vote_average': 8.0,
                },
              ],
            }),
            200,
          );
        }
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    // Trigger initial search
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    expect(find.text('Page One Movie'), findsOneWidget);
    expect(find.text('Page Two Movie'), findsNothing);

    // Tap Load More
    final loadMoreBtn = find.text('Load More (Page 2 of 2)');
    expect(loadMoreBtn, findsOneWidget);
    await tester.tap(loadMoreBtn);
    await tester.pumpAndSettle();

    // Both movies should now be present
    expect(find.text('Page One Movie'), findsOneWidget);
    expect(find.text('Page Two Movie'), findsOneWidget);

    // All movies loaded footer should now show
    expect(find.text('All 2 movies loaded'), findsOneWidget);
    expect(find.textContaining('Load More'), findsNothing);
  });

  testWidgets('filters by TMDB ratings correctly in discover URL',
      (WidgetTester tester) async {
    final List<Uri> requestedUrls = [];

    final mockClient = MockClient((request) async {
      requestedUrls.add(request.url);
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        return http.Response(
          json.encode({
            'page': 1,
            'total_pages': 1,
            'results': [
              {
                'id': 301,
                'title': 'Rated Movie',
                'release_date': '2022-01-01',
                'poster_path': '',
                'overview': 'Rated',
                'vote_average': 7.5,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    // Change rating slider: Find the rating slider (second RangeSlider on screen)
    final rangeSliders = find.byType(RangeSlider);
    expect(rangeSliders, findsNWidgets(2));
    final ratingSlider = rangeSliders.at(1);

    // Drag the left thumb of rating slider to the right
    final topLeft = tester.getTopLeft(ratingSlider);
    final size = tester.getSize(ratingSlider);
    final startThumb = Offset(topLeft.dx + 24, topLeft.dy + size.height / 2);
    await tester.dragFrom(startThumb, const Offset(100, 0));
    await tester.pumpAndSettle();

    // Tap Search Movies
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    final discoverUrl = requestedUrls.firstWhere((u) => u.path.contains('discover/movie'));
    expect(discoverUrl.queryParameters.containsKey('vote_average.gte'), isTrue);
    final gte = double.parse(discoverUrl.queryParameters['vote_average.gte']!);
    expect(gte, greaterThan(0.0));
  });

  testWidgets('shows empty state when search returns no movies',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        return http.Response(
          json.encode({'page': 1, 'total_pages': 1, 'results': []}),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    // Before searching
    expect(
      find.text('Customize your filters and press Search to discover movies'),
      findsOneWidget,
    );

    // After searching
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    expect(find.text('No movies found matching your filters'), findsOneWidget);
  });

  testWidgets('renders and searches correctly on mobile layout with ExpansionTile',
      (WidgetTester tester) async {
    final List<Uri> requestedUrls = [];
    final mockClient = MockClient((request) async {
      requestedUrls.add(request.url);
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        return http.Response(
          json.encode({
            'page': 1,
            'total_pages': 1,
            'results': [
              {
                'id': 401,
                'title': 'Mobile Movie',
                'release_date': '2023-01-01',
                'poster_path': '',
                'overview': 'Mobile overview',
                'vote_average': 8.0,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    // Mobile width (e.g. 500)
    await tester.pumpWidget(
      createTestWidget(
        client: ApiClient.custom(mockClient),
        size: const Size(500, 900),
      ),
    );
    await tester.pumpAndSettle();

    // ExpansionTile should be present
    expect(find.byType(ExpansionTile), findsOneWidget);
    // Expand the tile
    await tester.tap(find.text('Search Filters'));
    await tester.pumpAndSettle();

    // Verify TMDB Rating is present inside mobile filters
    expect(find.text('TMDB Rating'), findsOneWidget);

    // Tap Search
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    expect(find.text('Mobile Movie'), findsOneWidget);
    expect(requestedUrls.any((u) => u.path.contains('discover/movie')), isTrue);
  });

  testWidgets('deduplicates movies when subsequent pages return already loaded IDs',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        final page = request.url.queryParameters['page'];
        if (page == '1') {
          return http.Response(
            json.encode({
              'page': 1,
              'total_pages': 2,
              'results': [
                {
                  'id': 501,
                  'title': 'Duplicate Movie',
                  'release_date': '2021-01-01',
                  'poster_path': '',
                  'overview': 'Dup',
                  'vote_average': 6.0,
                },
              ],
            }),
            200,
          );
        } else if (page == '2') {
          return http.Response(
            json.encode({
              'page': 2,
              'total_pages': 2,
              'results': [
                {
                  'id': 501, // same ID as page 1
                  'title': 'Duplicate Movie',
                  'release_date': '2021-01-01',
                  'poster_path': '',
                  'overview': 'Dup',
                  'vote_average': 6.0,
                },
                {
                  'id': 502,
                  'title': 'Unique Movie',
                  'release_date': '2021-02-01',
                  'poster_path': '',
                  'overview': 'Uniq',
                  'vote_average': 7.0,
                },
              ],
            }),
            200,
          );
        }
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    expect(find.text('Duplicate Movie'), findsOneWidget);

    await tester.tap(find.text('Load More (Page 2 of 2)'));
    await tester.pumpAndSettle();

    // Duplicate movie is only rendered once, unique movie is added
    expect(find.text('Duplicate Movie'), findsOneWidget);
    expect(find.text('Unique Movie'), findsOneWidget);
    expect(find.text('All 2 movies loaded'), findsOneWidget);
  });

  testWidgets('clamps total_pages to at most 500 (TMDB limit)',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        return http.Response(
          json.encode({
            'page': 1,
            'total_pages': 1500, // Beyond TMDB max 500
            'results': [
              {
                'id': 601,
                'title': 'Clamped Movie',
                'release_date': '2020-01-01',
                'poster_path': '',
                'overview': 'Clamp',
                'vote_average': 8.0,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    // Verify it shows Page 2 of 500, not 1500
    expect(find.text('Load More (Page 2 of 500)'), findsOneWidget);
  });

  testWidgets('recovers gracefully and allows retry when load more fails',
      (WidgetTester tester) async {
    int page2Attempts = 0;
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        final page = request.url.queryParameters['page'];
        if (page == '1') {
          return http.Response(
            json.encode({
              'page': 1,
              'total_pages': 2,
              'results': [
                {
                  'id': 701,
                  'title': 'Original Movie',
                  'release_date': '2019-01-01',
                  'poster_path': '',
                  'overview': 'Orig',
                  'vote_average': 7.0,
                },
              ],
            }),
            200,
          );
        } else if (page == '2') {
          page2Attempts++;
          if (page2Attempts == 1) {
            return http.Response('Server Error', 500);
          }
          return http.Response(
            json.encode({
              'page': 2,
              'total_pages': 2,
              'results': [
                {
                  'id': 702,
                  'title': 'Retry Succeeded Movie',
                  'release_date': '2019-02-01',
                  'poster_path': '',
                  'overview': 'Retry',
                  'vote_average': 8.0,
                },
              ],
            }),
            200,
          );
        }
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    expect(find.text('Original Movie'), findsOneWidget);

    // First attempt fails with 500
    await tester.tap(find.text('Load More (Page 2 of 2)'));
    await tester.pumpAndSettle();

    // Original movie still intact, Load More button still available
    expect(find.text('Original Movie'), findsOneWidget);
    expect(find.text('Load More (Page 2 of 2)'), findsOneWidget);

    // Retry succeeds
    await tester.tap(find.text('Load More (Page 2 of 2)'));
    await tester.pumpAndSettle();

    expect(find.text('Retry Succeeded Movie'), findsOneWidget);
    expect(find.text('All 2 movies loaded'), findsOneWidget);
  });

  testWidgets('filters by upper TMDB rating bound (vote_average.lte)',
      (WidgetTester tester) async {
    final List<Uri> requestedUrls = [];

    final mockClient = MockClient((request) async {
      requestedUrls.add(request.url);
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        return http.Response(
          json.encode({
            'page': 1,
            'total_pages': 1,
            'results': [
              {
                'id': 801,
                'title': 'Low Rated Movie',
                'release_date': '2020-01-01',
                'poster_path': '',
                'overview': 'Low',
                'vote_average': 4.5,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    // Drag the right thumb of rating slider to the left
    final rangeSliders = find.byType(RangeSlider);
    final ratingSlider = rangeSliders.at(1);
    final topLeft = tester.getTopLeft(ratingSlider);
    final size = tester.getSize(ratingSlider);
    final endThumb = Offset(topLeft.dx + size.width - 24, topLeft.dy + size.height / 2);
    await tester.dragFrom(endThumb, const Offset(-100, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    final discoverUrl = requestedUrls.firstWhere((u) => u.path.contains('discover/movie'));
    expect(discoverUrl.queryParameters.containsKey('vote_average.lte'), isTrue);
    final lte = double.parse(discoverUrl.queryParameters['vote_average.lte']!);
    expect(lte, lessThan(10.0));
  });

  testWidgets('infinite scroll triggers pagination automatically on scroll',
      (WidgetTester tester) async {
    int requestedPage = 0;
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        final page = int.parse(request.url.queryParameters['page']!);
        requestedPage = page;
        return http.Response(
          json.encode({
            'page': page,
            'total_pages': 3,
            'results': List.generate(
              10,
              (i) => {
                'id': page * 1000 + i,
                'title': 'Scroll Movie P${page}_$i',
                'release_date': '2022-01-01',
                'poster_path': '',
                'overview': 'Scroll test',
                'vote_average': 7.0,
              },
            ),
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(
        client: ApiClient.custom(mockClient),
        size: const Size(1200, 600),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    expect(requestedPage, 1);
    expect(find.text('Scroll Movie P1_0'), findsOneWidget);

    // Scroll down to trigger pagination
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(requestedPage, 2);
    expect(find.text('Scroll Movie P2_0'), findsOneWidget);
  });

  testWidgets('tapping rating preset chip sets range and updates query URL',
      (WidgetTester tester) async {
    final List<Uri> requestedUrls = [];
    final mockClient = MockClient((request) async {
      requestedUrls.add(request.url);
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        return http.Response(
          json.encode({
            'page': 1,
            'total_pages': 1,
            'results': [
              {
                'id': 901,
                'title': 'High Rated Movie',
                'release_date': '2023-01-01',
                'poster_path': '',
                'overview': 'Preset test',
                'vote_average': 7.8,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    // Verify preset chips are rendered
    expect(find.text('All'), findsOneWidget);
    expect(find.text('7.0+'), findsOneWidget);
    expect(find.text('8.0+'), findsOneWidget);

    // Tap '7.0+' preset
    await tester.tap(find.text('7.0+'));
    await tester.pumpAndSettle();

    // Verify rating display updated to 7.0 - 10.0
    expect(find.text('7.0 - 10.0'), findsOneWidget);

    // Tap Search Movies
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    final discoverUrl = requestedUrls.firstWhere((u) => u.path.contains('discover/movie'));
    expect(discoverUrl.queryParameters['vote_average.gte'], '7.0');
    expect(discoverUrl.queryParameters.containsKey('vote_average.lte'), isFalse);
  });

  testWidgets('tapping All preset resets rating range to 0.0 - 10.0',
      (WidgetTester tester) async {
    final List<Uri> requestedUrls = [];
    final mockClient = MockClient((request) async {
      requestedUrls.add(request.url);
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        return http.Response(
          json.encode({'page': 1, 'total_pages': 1, 'results': []}),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    // First select 8.0+
    await tester.tap(find.text('8.0+'));
    await tester.pumpAndSettle();
    expect(find.text('8.0 - 10.0'), findsOneWidget);

    // Then select All
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('0.0 - 10.0'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    final discoverUrl = requestedUrls.firstWhere((u) => u.path.contains('discover/movie'));
    expect(discoverUrl.queryParameters.containsKey('vote_average.gte'), isFalse);
    expect(discoverUrl.queryParameters.containsKey('vote_average.lte'), isFalse);
  });

  testWidgets('initial fetch failure displays error state and retry succeeds',
      (WidgetTester tester) async {
    int attempts = 0;
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        attempts++;
        if (attempts == 1) {
          return http.Response('Server Error', 500);
        }
        return http.Response(
          json.encode({
            'page': 1,
            'total_pages': 1,
            'results': [
              {
                'id': 950,
                'title': 'Recovered Movie',
                'release_date': '2024-01-01',
                'poster_path': '',
                'backdrop_path': '/backdrop950.jpg',
                'overview': 'Recovered',
                'vote_average': 8.1,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    // First attempt fails
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to load movies'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Tap retry
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered Movie'), findsOneWidget);
    expect(find.text('Failed to load movies'), findsNothing);
  });

  testWidgets('preserves backdropPath across page 1 and paginated pages',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        final page = request.url.queryParameters['page'];
        return http.Response(
          json.encode({
            'page': int.parse(page!),
            'total_pages': 2,
            'results': [
              {
                'id': -int.parse(page),
                'title': 'Movie with Backdrop $page',
                'release_date': '2024-01-01',
                'poster_path': '',
                'backdrop_path': '/backdrop$page.jpg',
                'overview': 'Backdrop test',
                'vote_average': 7.5,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    expect(find.text('Movie with Backdrop 1'), findsOneWidget);

    await tester.tap(find.text('Load More (Page 2 of 2)'));
    await tester.pumpAndSettle();

    expect(find.text('Movie with Backdrop 1'), findsOneWidget);
    expect(find.text('Movie with Backdrop 2'), findsOneWidget);
  });

  testWidgets('does not trigger pagination when user is at top of list',
      (WidgetTester tester) async {
    int requestedPages = 0;
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('genre/movie/list')) {
        return http.Response(json.encode({'genres': []}), 200);
      }
      if (request.url.path.contains('discover/movie')) {
        requestedPages++;
        return http.Response(
          json.encode({
            'page': requestedPages,
            'total_pages': 5,
            'results': [
              {
                'id': 1100 + requestedPages,
                'title': 'Top Test Movie $requestedPages',
                'release_date': '2024-01-01',
                'poster_path': '',
                'overview': 'Overview',
                'vote_average': 7.0,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      createTestWidget(client: ApiClient.custom(mockClient)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Search Movies'));
    await tester.pumpAndSettle();

    expect(requestedPages, 1);
    expect(find.text('Top Test Movie 1'), findsOneWidget);

    // Idle tap on the grid background at the top without scrolling
    await tester.tap(find.byType(CustomScrollView));
    await tester.pumpAndSettle();

    // No extra page should have been fetched
    expect(requestedPages, 1);
  });
}
