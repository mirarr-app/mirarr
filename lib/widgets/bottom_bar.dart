import 'package:Mirarr/functions/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return BottomNavigationBar(
      selectedItemColor: Theme.of(context).highlightColor,
      selectedIconTheme: IconThemeData(color: Theme.of(context).highlightColor),
      selectedFontSize: 16,
      unselectedItemColor: Theme.of(context).primaryColor,
      currentIndex: navProvider.currentIndex,
      onTap: (int index) {
        navProvider.setIndex(index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.movie),
          label: 'Movies',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_movies),
          label: 'Series',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shelves),
          label: 'Shelf',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}
