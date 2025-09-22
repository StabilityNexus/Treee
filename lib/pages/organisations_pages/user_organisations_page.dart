import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class OrganisationsPage extends StatefulWidget {
  const OrganisationsPage({super.key});

  @override
  State<OrganisationsPage> createState() => _OrganisationsPageState();
}

class _OrganisationsPageState extends State<OrganisationsPage> {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
        title: 'Organisations',
        body: const Center(
          child: Text("Organisations Page"),
        ));
  }
}
