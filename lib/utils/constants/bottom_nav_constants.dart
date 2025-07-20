import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';

class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class BottomNavConstants {
  static const List<BottomNavItem> items = [
    BottomNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: RouteConstants.homePath,
    ),
    BottomNavItem(
      label: 'Trees',
      icon: Icons.forest_outlined,
      activeIcon: Icons.forest,
      route: RouteConstants.allTreesPath,
    ),
    BottomNavItem(
      label: 'Mint NFT',
      icon: Icons.nature_people_outlined,
      activeIcon: Icons.nature_people,
      route: RouteConstants.mintNftPath,
    ),
  ];
}