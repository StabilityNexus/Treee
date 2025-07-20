import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class MintNftCoordinatesPage extends StatefulWidget {
  const MintNftCoordinatesPage({super.key});

  @override
  State<MintNftCoordinatesPage> createState() => _MintNftCoordinatesPageState();
}

class _MintNftCoordinatesPageState extends State<MintNftCoordinatesPage> {
  @override
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Mint NFT Coordinates", 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
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
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: longitudeController,
              decoration: InputDecoration(
                labelText: "Longitude",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        )
      )
    );
  }
}
