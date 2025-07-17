// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:tree_planting_protocol/pages/home_page.dart';
import 'package:tree_planting_protocol/pages/trees_page.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/providers/theme_provider.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

void main() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("No .env file found or error loading it: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize GoRouter inside MyApp
    final GoRouter router = GoRouter(
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
          routes: [
            // Nested route for tree details
            GoRoute(
              path: 'details', // This will be /trees/details
              name: '${RouteConstants.allTrees}_details',
              builder: (BuildContext context, GoRouterState state) {
                return const AllTreesPage();
              },
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri.toString()}'),
        ),
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WalletProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'WalletConnect Demo',
            routerConfig: router,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
            ),
            themeMode: themeProvider.themeMode,
          );
        },
      ),
    );
  }
}