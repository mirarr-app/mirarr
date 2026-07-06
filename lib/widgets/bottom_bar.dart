import 'dart:ui';
import 'package:Mirarr/functions/navigation_provider.dart';
import 'package:Mirarr/widgets/tv_focus_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final bool isTv = TvFocusModeManager.isTvDevice;

    if (isTv) {
      // Keep the current native BottomNavigationBar logic for TV
      return Focus(
        focusNode: TvFocusModeManager.bottomBarFocusNode,
        canRequestFocus: false,
        child: BottomNavigationBar(
          selectedItemColor: Theme.of(context).highlightColor,
          selectedIconTheme: IconThemeData(color: Theme.of(context).highlightColor),
          selectedFontSize: 16,
          unselectedItemColor: Theme.of(context).primaryColor,
          currentIndex: navProvider.currentIndex,
          onTap: (int index) {
            navProvider.setIndex(index);
            Navigator.popUntil(context, (route) => route.isFirst);
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
        ),
      );
    }

    // For any other case: Modern Hovering Island Navigation Bar (Glassmorphic & Dynamic Width)!
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Center(
      heightFactor: 1.0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, bottomPadding > 0 ? bottomPadding : 16.0),
        child: IntrinsicWidth(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(
                    color: Theme.of(context).cardColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIslandItem(context, navProvider, 0, Icons.movie, 'Movies'),
                    _buildIslandItem(context, navProvider, 1, Icons.local_movies, 'Series'),
                    _buildIslandItem(context, navProvider, 2, Icons.search, 'Search'),
                    _buildIslandItem(context, navProvider, 3, Icons.shelves, 'Shelf'),
                    _buildIslandItem(context, navProvider, 4, Icons.person, 'Account'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIslandItem(
    BuildContext context,
    NavigationProvider navProvider,
    int index,
    IconData iconData,
    String label,
  ) {
    final bool isSelected = navProvider.currentIndex == index;
    final Color itemColor = isSelected
        ? Theme.of(context).highlightColor
        : Theme.of(context).primaryColor;

    return SizedBox(
      width: 68, // Fixed item width to support shrink-wrap dynamic sizing
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          navProvider.setIndex(index);
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).highlightColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                iconData,
                color: itemColor,
                size: isSelected ? 24 : 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
