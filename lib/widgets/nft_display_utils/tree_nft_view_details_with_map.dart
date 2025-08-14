import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/flutter_map_widget.dart';

class NewNFTMapWidget extends StatefulWidget {
  const NewNFTMapWidget({super.key});

  @override
  State<NewNFTMapWidget> createState() => _NewNFTMapWidgetState();
}

class _NewNFTMapWidgetState extends State<NewNFTMapWidget> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final mapHeight = screenHeight * 0.35;
    final mapWidth = screenWidth * 0.9;
    final containerMaxWidth = screenWidth * 0.95;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 16.0,
      ),
      child: Column(
        children: [
          Container(
            height: mapHeight.clamp(250.0, 400.0),
            width: mapWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: StaticDisplayMap(
              lat: Provider.of<MintNftProvider>(context)
                  .getLatitude()
                  .toDouble(),
              lng: Provider.of<MintNftProvider>(context)
                  .getLongitude()
                  .toDouble(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: containerMaxWidth,
              minHeight: 120,
            ),
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<MintNftProvider>(
              builder: (ctx, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Latitude:',
                      provider.getLatitude().toString(),
                      screenWidth,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Longitude:',
                      provider.getLongitude().toString(),
                      screenWidth,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'GeoHash:',
                      provider.getGeoHash(),
                      screenWidth,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Species:',
                      provider.getSpecies(),
                      screenWidth,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Description:',
                      _formatDescription(provider.getDetails(), screenWidth),
                      screenWidth,
                      isDescription: true,
                    ),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.getInitialPhotos().length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Image.network(
                              provider.getInitialPhotos()[index],
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double screenWidth,
      {bool isDescription = false}) {
    final fontSize = screenWidth < 360 ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey.shade800,
              height: isDescription ? 1.4 : 1.2,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

String _formatDescription(String description, double screenWidth) {
  int maxLength;
  if (screenWidth < 360) {
    maxLength = 60;
  } else if (screenWidth < 600) {
    maxLength = 100;
  } else {
    maxLength = 150;
  }

  return description.length > maxLength
      ? '${description.substring(0, maxLength)}...'
      : description;
}
