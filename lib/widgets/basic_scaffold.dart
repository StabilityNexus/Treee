import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/components/universal_navbar.dart';
import 'package:tree_planting_protocol/components/bottom_navigation_widget.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/widgets/wrong_chain_widget.dart'
    show buildWrongChainWidget;
import 'package:tree_planting_protocol/widgets/wallet_not_connected_widget.dart'
    show buildWalletNotConnectedWidget;

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool showBottomNavigation;
  final Widget? leading;

  const BaseScaffold(
      {super.key,
      required this.body,
      this.title,
      this.actions,
      this.floatingActionButton,
      this.extendBodyBehindAppBar = false,
      this.showBottomNavigation = true,
      this.leading});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        final bool isWalletConnecting = provider.isConnecting;
        final bool isWalletConnected = provider.isConnected;
        final bool isCorrectChain = provider.isValidCurrentChain;

        Widget bodyContent;

        if (isWalletConnecting) {
          bodyContent = Center(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const Text("Connecting"),
            ],
          ));
        } else if (!isWalletConnected) {
          bodyContent = buildWalletNotConnectedWidget(context);
        } else if (!isCorrectChain) {
          bodyContent = buildWrongChainWidget(context);
        } else {
          bodyContent = SafeArea(child: body);
        }

        return Scaffold(
          appBar:
              UniversalNavbar(title: title, actions: actions, leading: leading),
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          body: bodyContent,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: showBottomNavigation
              ? BottomNavigationWidget(currentRoute: currentRoute)
              : null,
        );
      },
    );
  }
}
