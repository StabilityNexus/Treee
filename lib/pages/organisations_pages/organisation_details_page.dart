import 'package:flutter/material.dart';

class OrganisationDetailsPage extends StatelessWidget {
  final String organisationAddress;

  const OrganisationDetailsPage({super.key, required this.organisationAddress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organisation Details"),
      ),
      body: Center(
        child: Text(
          "Organisation Address: $organisationAddress",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
