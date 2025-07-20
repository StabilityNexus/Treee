import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class MintNftDetailsPage extends StatefulWidget {
  const MintNftDetailsPage ({super.key});

  @override
  State<MintNftDetailsPage> createState() => _MintNftCoordinatesPageState();
}

class _MintNftCoordinatesPageState extends State<MintNftDetailsPage> {
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  void submitCoordinates() {
    final latitude = latitudeController.text;
    final longitude = longitudeController.text;

    if (latitude.isEmpty || longitude.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter both latitude and longitude.")),
      );
      return;
    }
    Provider.of<MintNftProvider>(context, listen: false)
        .setLatitude(double.parse(latitude));
    Provider.of<MintNftProvider>(context, listen: false)
        .setLongitude(double.parse(longitude));
    latitudeController.clear();
    longitudeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Coordinates submitted successfully.")),
    );
    context.push(RouteConstants.mintNftDetailsPath);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Mint NFT Coordinates",
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "This is the Mint NFT Coordinates page.",
              style: TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: latitudeController,
              decoration: const InputDecoration(
                labelText: "Latitude",
                border: OutlineInputBorder(),
                constraints: BoxConstraints(maxWidth: 300),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: longitudeController,
              decoration: const InputDecoration(
                labelText: "Longitude",
                border: OutlineInputBorder(),
                constraints: BoxConstraints(maxWidth: 300),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitCoordinates,
              child: const Text(
                "->",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }
}
