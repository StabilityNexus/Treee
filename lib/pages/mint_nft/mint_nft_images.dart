import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/utils/services/ipfs_services.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/tree_NFT_view_widget.dart';

class MultipleImageUploadPage extends StatefulWidget {
  const MultipleImageUploadPage({Key? key}) : super(key: key);

  @override
  _MultipleImageUploadPageState createState() => _MultipleImageUploadPageState();
}

class _MultipleImageUploadPageState extends State<MultipleImageUploadPage> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false;
  int _uploadingIndex = -1;
  List<String> _uploadedHashes = [];

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

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting images: $e');
    }
  }

  Future<void> _uploadAllImages() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please select images first');
      return;
    }

    final provider = Provider.of<MintNftProvider>(context, listen: false);
    List<String> newHashes = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      setState(() {
        _uploadingIndex = i;
      });

      try {
        String? hash = await uploadToIPFS(_selectedImages[i], (isUploading) {
          setState(() {
            _isUploading = isUploading;
          });
        });

        if (hash != null) {
          newHashes.add(hash);
          setState(() {
            _uploadedHashes.add(hash);
          });
        } else {
          _showSnackBar('Failed to upload image ${i + 1}');
        }
      } catch (e) {
        _showSnackBar('Error uploading image ${i + 1}: $e');
      }
    }

    setState(() {
      _uploadingIndex = -1;
    });
    provider.setInitialPhotos(_uploadedHashes);
    
    if (newHashes.isNotEmpty) {
      _showSnackBar('Successfully uploaded ${newHashes.length} images');
    }
  }

  Future<void> _uploadSingleImage(int index) async {
    if (index >= _selectedImages.length) return;

    setState(() {
      _uploadingIndex = index;
    });

    try {
      String? hash = await uploadToIPFS(_selectedImages[index], (isUploading) {
        setState(() {
          _isUploading = isUploading;
        });
      });

      if (hash != null) {
        setState(() {
          _uploadedHashes.add(hash);
          _uploadingIndex = -1;
        });

        final provider = Provider.of<MintNftProvider>(context, listen: false);
        provider.setInitialPhotos(_uploadedHashes);

        _showSnackBar('Image ${index + 1} uploaded successfully');
      } else {
        _showSnackBar('Failed to upload image ${index + 1}');
        setState(() {
          _uploadingIndex = -1;
        });
      }
    } catch (e) {
      _showSnackBar('Error uploading image ${index + 1}: $e');
      setState(() {
        _uploadingIndex = -1;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeUploadedHash(int index) {
    setState(() {
      _uploadedHashes.removeAt(index);
    });
    final provider = Provider.of<MintNftProvider>(context, listen: false);
    provider.setInitialPhotos(_uploadedHashes);
  }

  void _clearAll() {
    setState(() {
      _selectedImages.clear();
      _uploadedHashes.clear();
    });
    final provider = Provider.of<MintNftProvider>(context, listen: false);
    provider.setInitialPhotos([]);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: SingleChildScrollView(
        child: 
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const NewNFTWidget(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Select Images'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_selectedImages.isEmpty || _isUploading)
                            ? null
                            : _uploadAllImages,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Upload All'),
                      ),
                    ),
                  ],
                ),
          
                const SizedBox(height: 16),
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
                                ? 'Uploading image ${_uploadingIndex + 1} of ${_selectedImages.length}...'
                                : 'Uploading...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
          
                const SizedBox(height: 16),
                if (_selectedImages.isNotEmpty) ...[
                  Text(
                    'Selected Images (${_selectedImages.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          child: Card(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 120,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  right: 4,
                                  child: SizedBox(
                                    height: 28,
                                    child: ElevatedButton(
                                      onPressed: (_isUploading && _uploadingIndex == index)
                                          ? null
                                          : () => _uploadSingleImage(index),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: (_isUploading && _uploadingIndex == index)
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.upload, size: 16),
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
                if (_uploadedHashes.isNotEmpty) ...[
                  Text(
                    'Uploaded Images (${_uploadedHashes.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: _uploadedHashes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No images uploaded yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _uploadedHashes.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green,
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
                                        // You can implement opening the IPFS link here
                                        _showSnackBar('IPFS Hash: ${_uploadedHashes[index]}');
                                      },
                                      tooltip: 'View on IPFS',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
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
          ),
      ),
    );
  }
}