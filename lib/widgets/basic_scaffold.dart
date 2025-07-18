import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tree_planting_protocol/components/universal_navbar.dart';
import 'package:tree_planting_protocol/components/bottom_navigation_widget.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool showBottomNavigation;

  const BaseScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
    this.showBottomNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    
    return Scaffold(
      
      appBar: UniversalNavbar(title: title, actions: actions),
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: SafeArea(
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNavigation 
          ? BottomNavigationWidget(currentRoute: currentRoute)
          : null,
    );
  }
}