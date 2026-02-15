import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/storage_service.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class MultipleImageUploadPage extends StatefulWidget {
  const MultipleImageUploadPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MultipleImageUploadPageState createState() =>
      _MultipleImageUploadPageState();
}

class _MultipleImageUploadPageState extends State<MultipleImageUploadPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  int _uploadingIndex = -1;
  List<String> _uploadedHashes = [];
  List<File> _processingImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MintNftProvider>(context, listen: false);
      setState(() {
        _uploadedHashes = List.from(provider.getInitialPhotos());
      });
    });
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return;

      logger.d('Selected ${images.length} images for upload');

      // ignore: use_build_context_synchronously
      final provider = Provider.of<MintNftProvider>(context, listen: false);

      setState(() {
        _processingImages = images.map((image) => File(image.path)).toList();
        _isUploading = true;
      });

      List<String> newHashes = [];

      for (int i = 0; i < images.length; i++) {
        setState(() {
          _uploadingIndex = i;
        });

        try {
          File imageFile = File(images[i].path);
          String? hash = await uploadToIPFS(imageFile, (isUploading) {});

          if (hash != null) {
            newHashes.add(hash);
            setState(() {
              _uploadedHashes.add(hash);
            });
            logger.d('Successfully uploaded image ${i + 1}: $hash');
          } else {
            _showSnackBar('Failed to upload image ${i + 1}');
          }
        } catch (e) {
          logger.e('Error uploading image ${i + 1}: $e');
          _showSnackBar('Error uploading image ${i + 1}: $e');
        }
      }

      setState(() {
        _isUploading = false;
        _uploadingIndex = -1;
        _processingImages.clear();
      });
      provider.setInitialPhotos(_uploadedHashes);

      if (newHashes.isNotEmpty) {
        _showSnackBar('Successfully uploaded ${newHashes.length} images');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadingIndex = -1;
        _processingImages.clear();
      });
      _showSnackBar('Error selecting images: $e');
    }
  }

  void _removeUploadedHash(int index) {
    setState(() {
      _uploadedHashes.removeAt(index);
    });
    final provider = Provider.of<MintNftProvider>(context, listen: false);
    provider.setInitialPhotos(_uploadedHashes);
    _showSnackBar('Image removed');
  }

  void _removeAllImages() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove All Images'),
          content: const Text(
              'Are you sure you want to remove all uploaded images? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _uploadedHashes.clear();
                });
                final provider =
                    Provider.of<MintNftProvider>(context, listen: false);
                provider.setInitialPhotos([]);
                Navigator.of(context).pop();
                _showSnackBar('All images removed');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove All'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Mint Tree NFT",
      showBackButton: true,
      body: Column(
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Upload Images',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Material(
                            elevation: 4,
                            borderRadius:
                                BorderRadius.circular(buttonCircularRadius),
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isUploading ? null : _pickAndUploadImages,
                              icon: const Icon(Icons.add_photo_alternate,
                                  size: 20),
                              label: const Text('Add Photos'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    getThemeColors(context)['primary'],
                                foregroundColor:
                                    getThemeColors(context)['textSecondary'],
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      buttonCircularRadius),
                                  side: const BorderSide(
                                      color: Colors.black, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_uploadedHashes.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Material(
                              elevation: 4,
                              borderRadius:
                                  BorderRadius.circular(buttonCircularRadius),
                              child: OutlinedButton.icon(
                                onPressed:
                                    _isUploading ? null : _removeAllImages,
                                icon: const Icon(Icons.delete_sweep, size: 20),
                                label: const Text('Clear All'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      getThemeColors(context)['textSecondary'],
                                  backgroundColor: getThemeColors(
                                      context)['secondaryButton'],
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: getThemeColors(context)['border']!,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        buttonCircularRadius),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_processingImages.isNotEmpty) ...[
                      Text(
                        'Processing Images (${_processingImages.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _processingImages.length,
                          itemBuilder: (context, index) {
                            final isCurrentlyUploading =
                                _isUploading && _uploadingIndex == index;
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 8),
                              child: Card(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _processingImages[index],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (isCurrentlyUploading)
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: getThemeColors(
                                              context)['primary'],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: getThemeColors(
                                                context)['primary'],
                                          ),
                                        ),
                                      ),
                                    if (_uploadingIndex < index && _isUploading)
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: getThemeColors(
                                              context)['secondary'],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.pending,
                                            color:
                                                getThemeColors(context)['icon'],
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    if (_uploadingIndex > index && _isUploading)
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: getThemeColors(
                                              context)['primary'],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.check_circle,
                                            color:
                                                getThemeColors(context)['icon'],
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 4,
                                      left: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: getThemeColors(
                                              context)['secondaryBackground'],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${index + 1}',
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
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_isUploading)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                _uploadingIndex >= 0
                                    ? 'Uploading image ${_uploadingIndex + 1}...'
                                    : 'Processing images...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_uploadedHashes.isNotEmpty)
                      Text(
                        'Uploaded Images (${_uploadedHashes.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    const SizedBox(height: 16),
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(buttonCircularRadius),
                      child: ElevatedButton(
                        onPressed: _uploadedHashes.isEmpty
                            ? null
                            : () {
                                context.push('/mint-nft/submit-nft');
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getThemeColors(context)['primary'],
                          foregroundColor:
                              getThemeColors(context)['textSecondary'],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(buttonCircularRadius),
                            side:
                                const BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        child: Text(
                          "Submit NFT",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: getThemeColors(context)['textSecondary'],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // NewNFTMapWidget(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _uploadedHashes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: getThemeColors(context)['icon'],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No images uploaded yet',
                          style: TextStyle(
                            color: getThemeColors(context)['textPrimary'],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Add Photos" to get started',
                          style: TextStyle(
                            color: getThemeColors(context)['textPrimary'],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _uploadedHashes.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: getThemeColors(context)['primary'],
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            'Image ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _uploadedHashes[index],
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () {
                                  _showSnackBar(
                                      'IPFS Hash: ${_uploadedHashes[index]}');
                                },
                                tooltip: 'View IPFS Hash',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: getThemeColors(
                                        context)['secondaryButton']),
                                onPressed: () => _removeUploadedHash(index),
                                tooltip: 'Remove',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
