import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/flutter_map_widget.dart';
import 'package:tree_planting_protocol/widgets/tree_NFT_view_widget.dart';
import 'package:dart_geohash/dart_geohash.dart';

class MintNftCoordinatesPage extends StatefulWidget {
  const MintNftCoordinatesPage({super.key});

  @override
  State<MintNftCoordinatesPage> createState() => _MintNftCoordinatesPageState();
}

class _MintNftCoordinatesPageState extends State<MintNftCoordinatesPage> {
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  var geoHasher = GeoHasher();

  void submitCoordinates() {
    final latitude = latitudeController.text;
    final longitude = longitudeController.text;
    final geohash = geoHasher.encode(
      double.parse(latitude),
      double.parse(longitude),
      precision: 12,
    );

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
    Provider.of<MintNftProvider>(context, listen: false)
        .setGeoHash(geohash);
        
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const NewNFTWidget(),
              const SizedBox(height: 20),
              const SizedBox(
                height: 300,
                width: 350, 
                child: CoordinatesMap()
              ),
              const Text(
                "Enter your coordinates",
                style: TextStyle(fontSize: 30),
                textAlign: TextAlign.center,
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
                  "Next",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
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
