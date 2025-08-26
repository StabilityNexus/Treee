import 'package:flutter/material.dart';

class TreeDetailsPage extends StatelessWidget {
  final String treeId;

  const TreeDetailsPage({super.key, required this.treeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tree Details - $treeId')),
      body: Center(
        child: Text('Showing details for tree ID: $treeId'),
      ),
    );
  }
}