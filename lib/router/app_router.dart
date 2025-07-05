import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tree_planting_protocol/pages/home_page.dart';
import 'package:tree_planting_protocol/pages/trees_page.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: RouteConstants.homePath,
    routes: [
      GoRoute(
        path: RouteConstants.homePath,
        name: RouteConstants.home,
        builder: (BuildContext context, GoRouterState state) {
          return const HomePage();
        },
      ),
      GoRoute(
        path: RouteConstants.allTreesPath,
        name: RouteConstants.allTrees,
        builder: (BuildContext context, GoRouterState state) {
          return const AllTreesPage();
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
  );

  static GoRouter get router => _router;
}