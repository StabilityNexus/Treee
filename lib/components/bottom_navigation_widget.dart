import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tree_planting_protocol/utils/constants/bottom_nav_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';

class BottomNavigationWidget extends StatelessWidget {
  final String currentRoute;

  const BottomNavigationWidget({
    super.key,
    required this.currentRoute,
  });

  int _getCurrentIndex() {
    for (int i = 0; i < BottomNavConstants.items.length; i++) {
      if (BottomNavConstants.items[i].route == currentRoute) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: getThemeColors(context)['secondary'],
      unselectedItemColor: getThemeColors(context)['textSecondary'],
      backgroundColor: getThemeColors(context)['primary'],
      elevation: 8,
      onTap: (index) {
        final route = BottomNavConstants.items[index].route;
        if (route != currentRoute) {
          context.go(route);
        }
      },
      items: BottomNavConstants.items.map((item) {
        final isSelected = item.route == currentRoute;
        return BottomNavigationBarItem(
          icon: Icon(isSelected ? item.activeIcon : item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }
}
