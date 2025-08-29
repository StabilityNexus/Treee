// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_read_services.dart';
import 'package:tree_planting_protocol/utils/services/contract_write_functions.dart';
import 'package:tree_planting_protocol/utils/services/ipfs_services.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/static_map_display_widget.dart';
import 'package:tree_planting_protocol/widgets/nft_display_utils/tree_nft_details_verifiers_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ignore: constant_identifier_names
const TREE_VERIFIERS_OFFSET = 0;
// ignore: constant_identifier_names
const TREE_VERIFIERS_LIMIT = 10;

class TreeDetailsPage extends StatefulWidget {
  final String treeId;
  const TreeDetailsPage({super.key, required this.treeId});

  @override
  State<TreeDetailsPage> createState() => _TreeDetailsPageState();
}

class _TreeDetailsPageState extends State<TreeDetailsPage> {
  String? loggedInUser = "";
  bool canVerify = false;
  bool _isLoading = false;
  Tree? treeDetails;

  @override
  void initState() {
    super.initState();
    loadTreeDetails();
  }

  static int _toInt(dynamic value) {
    if (value is BigInt) return value.toInt();
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> loadTreeDetails() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    loggedInUser = walletProvider.currentAddress.toString();
    setState(() {
      _isLoading = true;
    });
    final result = await ContractReadFunctions.getTreeNFTInfo(
        walletProvider: walletProvider,
        id: _toInt(widget.treeId),
        offset: TREE_VERIFIERS_OFFSET,
        limit: TREE_VERIFIERS_LIMIT);
    if (result.success && result.data != null) {
      final List<dynamic> treesData = result.data['details'] ?? [];
      final List<dynamic> verifiersData = result.data['verifiers'] ?? [];
      final String owner = result.data['owner'].toString();
      treeDetails = Tree.fromContractData(treesData, verifiersData, owner);
      logger.d("Verifiers data: $verifiersData");
      canVerify = true;
      for (var verifier in verifiersData) {
        if (verifier[0].toString().toLowerCase() ==
            loggedInUser?.toLowerCase()) {
          canVerify = false;
          break;
        }
      }
    }
    logger.d("Tree Details hot: ${treeDetails?.verifiers}");
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildMapSection(double screenHeight, double screenWidth) {
    final mapHeight = (screenHeight * 0.35).clamp(250.0, 350.0);
    final mapWidth = (screenWidth * 0.9);

    return Center(
      child: Container(
        height: mapHeight,
        width: mapWidth.toDouble(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: StaticCoordinatesMap(
          lat: (treeDetails!.latitude / 1e6) - 90.0,
          lng: (treeDetails!.longitude / 1e6) - 180.0,
        ),
      ),
    );
  }

  Widget _buildTreeNFTDetailsSection(
      double screenHeight, double screenWidth, BuildContext context) {
    final componentWidth = (screenWidth * 0.9);
    return SizedBox(
      width: componentWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(width: 2.0),
                    color: const Color.fromARGB(255, 28, 211, 129),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      ((treeDetails!.latitude / 1e6) - 90.0).toStringAsFixed(6),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9, height: 1, color: Colors.white),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(width: 2.0),
                    color: Color.fromARGB(255, 251, 251, 99),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      ((treeDetails!.longitude / 1e6) - 180.0)
                          .toStringAsFixed(6),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9, height: 1, color: Colors.black),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(width: 2.0),
                    color: const Color(0xFFFF4E63),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      (treeDetails!.species.toString()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9, height: 1, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailCard("Description", treeDetails!.metadata),
                const SizedBox(height: 12),
                _buildDetailCard(
                    "Care Taken", "${treeDetails!.careCount} times"),
                const SizedBox(height: 12),
                _buildDetailCard("Last Care",
                    _formatTimestamp(treeDetails!.lastCareTimestamp)),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canVerify
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  canVerify ? Icons.verified : Icons.lock,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  canVerify ? "Tree Verification" : "Verification Disabled",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canVerify
                      ? "Confirm this tree's authenticity"
                      : "You cannot verify this tree",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: canVerify
                      ? () async {
                          _showVerificationDialog();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        canVerify ? Colors.green.shade600 : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        canVerify ? Icons.check_circle : Icons.cancel,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Verify Tree",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          treeVerifiersSection(
              loggedInUser, treeDetails, loadTreeDetails, context),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildDetailCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => _VerificationModal(
        treeDetails: treeDetails!,
        onVerify: _performVerification,
      ),
    );
  }

  Future<void> _performVerification({
    required String description,
    required List<String> proofHashes,
  }) async {
    logger.d("Starting tree verification process");
    logger.d("Logged in user: $loggedInUser");
    logger.d("Tree ID: ${treeDetails!.id}");
    logger.d("Description: $description");
    logger.d("Proof hashes: $proofHashes");

    try {
      // Get wallet provider
      WalletProvider walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      // Validate wallet connection
      if (!walletProvider.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please connect your wallet first"),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text("Processing verification..."),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 10),
        ),
      );

      final result = await ContractWriteFunctions.verifyTree(
        walletProvider: walletProvider,
        treeId: treeDetails!.id,
        description: description,
        photos: proofHashes,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text("Tree verification submitted successfully!"),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await loadTreeDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                    child: Text("Verification failed: ${result.errorMessage}")),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      String errorMessage = "Verification failed";
      if (e.toString().contains("No element")) {
        errorMessage =
            "Wallet connection issue. Please reconnect your wallet and try again.";
      } else if (e.toString().contains("timeout")) {
        errorMessage = "Transaction timeout. Please try again.";
      } else if (e.toString().contains("user rejected")) {
        errorMessage = "Transaction was cancelled by user.";
      } else if (e.toString().contains("insufficient funds")) {
        errorMessage = "Insufficient funds for gas fees.";
      } else {
        errorMessage = "Error: ${e.toString()}";
      }

      logger.e("Verification error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return BaseScaffold(
        title: "Tree NFT Details",
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildMapSection(screenHeight, screenWidth),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildTreeNFTDetailsSection(
                            screenHeight, screenWidth, context),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ));
  }
}

class _VerificationModal extends StatefulWidget {
  final Tree treeDetails;
  final Function(
      {required String description,
      required List<String> proofHashes}) onVerify;

  const _VerificationModal({
    required this.treeDetails,
    required this.onVerify,
  });

  @override
  State<_VerificationModal> createState() => _VerificationModalState();
}

class _VerificationModalState extends State<_VerificationModal> {
  final TextEditingController _descriptionController = TextEditingController();
  final List<File> _selectedImages = [];
  final List<String> _uploadedHashes = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Maximum 3 images allowed"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Maximum 3 images allowed"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadedHashes.clear();
    });

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        File image = _selectedImages[i];
        logger.d("Uploading image ${i + 1} of ${_selectedImages.length}");

        final hash = await uploadToIPFS(image, (uploading) {});

        if (hash != null) {
          _uploadedHashes.add(hash);
          logger.d("Successfully uploaded image ${i + 1}: $hash");
        } else {
          logger.e("Failed to upload image ${i + 1}");
          throw Exception("Failed to upload image ${i + 1}");
        }
      }

      logger.d(
          "All images uploaded successfully. Total hashes: ${_uploadedHashes.length}");
    } catch (e) {
      logger.e("Error uploading images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading images: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Image Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth =
        screenSize.width * 0.9 > 500 ? 500.0 : screenSize.width * 0.9;
    final dialogHeight =
        screenSize.height * 0.8 > 700 ? 700.0 : screenSize.height * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: dialogHeight,
          maxWidth: dialogWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green.shade600, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Verify Tree",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Verification Description",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            "Describe your verification (e.g., tree health, location accuracy, etc.)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                "Proof Images (Optional)",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Flexible(
                              child: TextButton.icon(
                                onPressed: _selectedImages.length < 3
                                    ? _showImageSourceDialog
                                    : null,
                                icon: const Icon(Icons.add_photo_alternate,
                                    size: 18),
                                label: const Text("Add",
                                    style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImages[index],
                                      width: 80,
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
                                        padding: const EdgeInsets.all(2),
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
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (_isUploading)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    Colors.blue.shade600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text("Uploading images to IPFS..."),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isUploading ||
                              _descriptionController.text.trim().isEmpty
                          ? null
                          : () async {
                              if (_selectedImages.isNotEmpty &&
                                  _uploadedHashes.length !=
                                      _selectedImages.length) {
                                await _uploadImages();
                              }
                              Navigator.pop(context);
                              widget.onVerify(
                                description: _descriptionController.text.trim(),
                                proofHashes: _uploadedHashes,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _selectedImages.isNotEmpty &&
                                _uploadedHashes.length != _selectedImages.length
                            ? "Upload & Verify"
                            : "Verify Tree",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
