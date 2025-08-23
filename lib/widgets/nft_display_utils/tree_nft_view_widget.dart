// ignore: file_names
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';

class NewNFTWidget extends StatefulWidget {
  const NewNFTWidget({super.key});

  @override
  State<NewNFTWidget> createState() => _NewNFTWidgetState();
}

class _NewNFTWidgetState extends State<NewNFTWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
        ),
        child: Consumer<MintNftProvider>(
          builder: (ctx, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latitude: ${provider.getLatitude()}',
                  style: const TextStyle(fontSize: 18),
                  softWrap: true,
                ),
                Text(
                  'Longitude: ${provider.getLongitude()}',
                  style: const TextStyle(fontSize: 18),
                  softWrap: true,
                ),
                Text(
                  'GeoHash: ${provider.getGeoHash()}',
                  style: const TextStyle(fontSize: 18),
                  softWrap: true,
                ),
                Text(
                  'Species: ${provider.getSpecies()}',
                  style: const TextStyle(fontSize: 18),
                  softWrap: true,
                ),
                Text(
                  'Description: ${_formatDescription(provider.getDetails())}',
                  style: const TextStyle(fontSize: 18),
                  softWrap: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _formatDescription(String description) {
  return description.length > 80
      ? '${description.substring(0, 80)}...'
      : description;
}
