import 'package:Mirarr/widgets/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:Mirarr/moviesPage/mainPage.dart';
import 'package:Mirarr/seriesPage/seriesPage.dart';
import 'package:Mirarr/widgets/login.dart';
import 'package:Mirarr/widgets/profile.dart';
import 'package:hive/hive.dart';
import 'package:Mirarr/widgets/rss_screen.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  _BottomBarState createState() => _BottomBarState();
}

int _selectedIndex = 0;

class _BottomBarState extends State<BottomBar> {
  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void toSeries() {
    setState(() {
      _selectedIndex = 1;
      _navigateTo(const SerieSearchScreen());
    });
  }

  void toMovies() {
    setState(() {
      _selectedIndex = 0;
      _navigateTo(const MovieSearchScreen());
    });
  }

  void toRSS() {
    setState(() {
      _selectedIndex = 3;
      _navigateTo(RssScreen());
    });
  }

  void toSearch() {
    setState(() {
      _selectedIndex = 2;
      _navigateTo(SearchScreen());
    });
  }

  void toAccount() async {
    final box = await Hive.openBox('sessionBox');
    final sessionData = box.get('sessionData');
    setState(() {
      _selectedIndex = 4;
      if (sessionData != null) {
        _navigateTo(ProfilePage());
      } else {
        _navigateTo(const LoginPage());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: Theme.of(context).highlightColor,
      selectedIconTheme: IconThemeData(color: Theme.of(context).highlightColor),
      selectedFontSize: 16,
      unselectedItemColor: Theme.of(context).primaryColor,
      currentIndex: _selectedIndex,
      onTap: (int index) {
        if (_selectedIndex != index) {
          if (index == 0) {
            toMovies();
          } else if (index == 1) {
            toSeries();
          } else if (index == 4) {
            toAccount();
          } else if (index == 3) {
            toRSS();
          } else if (index == 2) {
            toSearch();
          }
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.movie,
          ),
          label: 'Movies',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.local_movies,
          ),
          label: 'Series',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.search,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.rss_feed,
          ),
          label: 'RSS',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
          ),
          label: 'Account',
        ),
      ],
    );
  }
}
