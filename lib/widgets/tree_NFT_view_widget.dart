import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/utils/services/wallet_provider_utils.dart';

class NewNFTWidget extends StatefulWidget {
  const NewNFTWidget({super.key});

  @override
  State<NewNFTWidget> createState() => _NewNFTWidgetState();
}


String _formatDescription(String description) {
  return description.length > 50
      ? '${description.substring(0, 50)}...'
      : description;
}
class _NewNFTWidgetState extends State<NewNFTWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Consumer<MintNftProvider>(builder: (ctx, _, __) {
            return Column(children: [
              Text(
                'Latitude: ${Provider.of<MintNftProvider>(ctx, listen: true).getLatitude()}',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Longitude: ${Provider.of<MintNftProvider>(ctx, listen: true).getLongitude()}',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'GeoHash: ${(Provider.of<MintNftProvider>(ctx, listen: true).getGeoHash())}',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Species: ${Provider.of<MintNftProvider>(ctx, listen: true).getSpecies()}',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                'Description: ${formatAddress(Provider.of<MintNftProvider>(ctx, listen: true).getDescription())}',
                style: const TextStyle(fontSize: 20),
              ),
            ]);
          })
        ]),
      ),
    );
  }
}
