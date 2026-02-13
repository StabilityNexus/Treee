import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/widgets/image_loader_widget.dart';
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
                  color: Colors.black,
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
            decoration: BoxDecoration(
              border: Border.all(
                color: getThemeColors(context)['border']!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16.0),
              color: getThemeColors(context)['background'],
              boxShadow: [
                BoxShadow(
                  color: getThemeColors(context)['shadow']!,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['primary'],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: getThemeColors(context)['background'],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: getThemeColors(context)['border']!,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.preview,
                          color: getThemeColors(context)['primary'],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'NFT Preview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: getThemeColors(context)['textSecondary'],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Consumer<MintNftProvider>(
                    builder: (ctx, provider, _) {
                      final organisationAddress = provider.organisationAddress;
                      final hasOrganisation = organisationAddress.isNotEmpty;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasOrganisation) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: getThemeColors(context)['secondary']!,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: getThemeColors(context)['border']!,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    color: getThemeColors(context)['primary'],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Organisation Minting',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: getThemeColors(
                                                context)['textPrimary'],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${organisationAddress.substring(0, 6)}...${organisationAddress.substring(organisationAddress.length - 4)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                            color: getThemeColors(
                                                context)['textPrimary']!,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          _buildInfoRow(
                            'Latitude:',
                            provider.getLatitude().toString(),
                            screenWidth,
                            icon: Icons.north,
                            color: getThemeColors(context)['primary']!,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Longitude:',
                            provider.getLongitude().toString(),
                            screenWidth,
                            icon: Icons.east,
                            color: getThemeColors(context)['primary']!,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'GeoHash:',
                            provider.getGeoHash(),
                            screenWidth,
                            icon: Icons.tag,
                            color: getThemeColors(context)['secondary']!,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Species:',
                            provider.getSpecies(),
                            screenWidth,
                            icon: Icons.park,
                            color: getThemeColors(context)['primary']!,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Number of Trees:',
                            provider.getNumberOfTrees().toString(),
                            screenWidth,
                            icon: Icons.format_list_numbered,
                            color: getThemeColors(context)['secondary']!,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Description:',
                            _formatDescription(
                                provider.getDetails(), screenWidth),
                            screenWidth,
                            isDescription: true,
                            icon: Icons.description,
                            color: getThemeColors(context)['primary']!,
                          ),
                          if (provider.getInitialPhotos().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: getThemeColors(context)['primary']!,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          getThemeColors(context)['primary']!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.photo_library,
                                    color: getThemeColors(context)['primary'],
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Uploaded Photos (${provider.getInitialPhotos().length})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: getThemeColors(context)['primary'],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.getInitialPhotos().length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          getThemeColors(context)['primary']!,
                                      width: 2,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      ImageLoaderWidget(
                                        imageUrl: provider.getInitialPhotos()[index],
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getThemeColors(
                                                context)['primary'],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            'Photo ${index + 1}',
                                            style: TextStyle(
                                              color: getThemeColors(
                                                  context)['textSecondary'],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    double screenWidth, {
    bool isDescription = false,
    IconData? icon,
    Color? color,
  }) {
    final fontSize = screenWidth < 360 ? 14.0 : 16.0;
    final labelColor = color ?? getThemeColors(context)['primary']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: labelColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: labelColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: labelColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: getThemeColors(context)['textPrimary']!,
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
