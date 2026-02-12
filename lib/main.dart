import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:tree_planting_protocol/pages/home_page.dart';
import 'package:tree_planting_protocol/pages/mint_nft/mint_nft_details.dart';
import 'package:tree_planting_protocol/pages/mint_nft/mint_nft_images.dart';
import 'package:tree_planting_protocol/pages/mint_nft/mint_nft_organisation.dart';
import 'package:tree_planting_protocol/pages/mint_nft/submit_nft_page.dart';
import 'package:tree_planting_protocol/pages/organisations_pages/create_organisation.dart';
import 'package:tree_planting_protocol/pages/organisations_pages/organisation_details_page.dart';
import 'package:tree_planting_protocol/pages/organisations_pages/user_organisations_page.dart';
import 'package:tree_planting_protocol/pages/register_user_page.dart';
import 'package:tree_planting_protocol/pages/settings_page.dart';
import 'package:tree_planting_protocol/pages/tree_details_page.dart';
import 'package:tree_planting_protocol/pages/trees_page.dart';
import 'package:tree_planting_protocol/pages/user_profile_page.dart';
import 'package:tree_planting_protocol/pages/mint_nft/mint_nft_coordinates.dart';
import 'package:tree_planting_protocol/pages/nearby_trees_map_page.dart';

import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/providers/theme_provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';

import 'package:tree_planting_protocol/utils/constants/route_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

void main() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    logger.d("No .env file found or error loading it: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          path: '/register-user',
          name: 'Register_user',
          builder: (BuildContext context, GoRouterState state) {
            return const RegisterUserPage();
          },
        ),
        GoRoute(
          path: '/settings',
          name: 'settings_page',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsPage();
          },
        ),
        GoRoute(
          path: '/organisations',
          name: 'organisations_page',
          builder: (BuildContext context, GoRouterState state) {
            return const OrganisationsPage();
          },
          routes: [
            GoRoute(
              path: ':address',
              name: 'organisation_details',
              builder: (BuildContext context, GoRouterState state) {
                final address = state.pathParameters['address'];
                return OrganisationDetailsPage(organisationAddress: address!);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/create-organisation',
          name: 'create_organisation_page',
          builder: (BuildContext context, GoRouterState state) {
            return const CreateOrganisationPage();
          },
        ),
        GoRoute(
          path: '/user-profile/:address',
          name: 'user_profile',
          builder: (BuildContext context, GoRouterState state) {
            final address = state.pathParameters['address'].toString();
            return UserProfilePage(
                userAddress: address.isNotEmpty ? address : '');
          },
        ),
        GoRoute(
          path: RouteConstants.mintNftOrganisationPath,
          name: RouteConstants.mintNftOrganisation,
          builder: (BuildContext context, GoRouterState state) {
            return const MintNftOrganisationPage();
          },
        ),
        GoRoute(
            path: RouteConstants.mintNftPath,
            name: RouteConstants.mintNft,
            builder: (context, state) => const MintNftCoordinatesPage(),
            routes: [
              GoRoute(
                path: 'details',
                name: '${RouteConstants.mintNft}_details',
                builder: (BuildContext context, GoRouterState state) {
                  return const MintNftDetailsPage();
                },
              ),
              GoRoute(
                path: 'images',
                name: '${RouteConstants.mintNft}_images',
                builder: (BuildContext context, GoRouterState state) {
                  return const MultipleImageUploadPage();
                },
              ),
              GoRoute(
                path: 'submit-nft',
                name: '${RouteConstants.mintNft}_submit',
                builder: (BuildContext context, GoRouterState state) {
                  return const SubmitNFTPage();
                },
              ),
            ]),
        GoRoute(
          path: '/nearby-trees',
          name: 'nearby_trees',
          builder: (BuildContext context, GoRouterState state) {
            return const NearbyTreesMapPage();
          },
        ),
        GoRoute(
          path: RouteConstants.allTreesPath,
          name: RouteConstants.allTrees,
          builder: (BuildContext context, GoRouterState state) {
            return const AllTreesPage();
          },
          routes: [
            GoRoute(
              path: ':id',
              name: '${RouteConstants.allTrees}_details',
              builder: (BuildContext context, GoRouterState state) {
                final id = state.pathParameters['id']; // read the dynamic ID
                return TreeDetailsPage(treeId: id!);
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
        ChangeNotifierProvider(create: (context) => MintNftProvider()),
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
