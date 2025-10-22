// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_read_services.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_write_functions.dart';
import 'package:tree_planting_protocol/utils/services/conversion_functions.dart';
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
  bool _isLoadingMore = false;
  Tree? treeDetails;
  int _verifiersOffset = 0;
  final int _verifiersLimit = 10;
  int _totalVerifiersCount = 0;
  int _visibleVerifiersCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadTreeDetails();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _verifiersOffset + _verifiersLimit < _visibleVerifiersCount) {
      _loadMoreVerifiers();
    }
  }

  Future<void> _loadMoreVerifiers() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _verifiersOffset += _verifiersLimit;
    });

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final result = await ContractReadFunctions.getTreeNFTInfo(
      walletProvider: walletProvider,
      id: toInt(widget.treeId),
      offset: _verifiersOffset,
      limit: _verifiersLimit,
    );

    if (result.success && result.data != null) {
      final List<dynamic> verifiersData = result.data['verifiers'] ?? [];
      // Parse the verifiers using the same method from Tree model
      final List<Verifier> newVerifiers = _parseVerifiers(verifiersData);
      setState(() {
        treeDetails?.verifiers.addAll(newVerifiers);
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  static List<Verifier> _parseVerifiers(List<dynamic> verifiersData) {
    List<Verifier> verifiers = [];
    for (int i = 0; i < verifiersData.length; i++) {
      var verifierEntry = verifiersData[i];

      try {
        if (verifierEntry is String) {
          verifiers.add(Verifier(
            address: verifierEntry,
            timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            proofHashes: [],
            description: "Verified",
            isActive: true,
            verificationId: i,
          ));
        } else if (verifierEntry is List) {
          if (verifierEntry.isNotEmpty) {
            if (verifierEntry.length == 1) {
              verifiers.add(Verifier(
                address: verifierEntry[0].toString(),
                timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                proofHashes: [],
                description: "Verified",
                isActive: true,
                verificationId: i,
              ));
            } else if (verifierEntry.length >= 6) {
              verifiers.add(Verifier.fromList(verifierEntry));
            }
          }
        }
      } catch (e) {
        logger.e("Error parsing verifier at index $i: $e");
      }
    }
    return verifiers;
  }

  Future<void> loadTreeDetails() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    loggedInUser = walletProvider.currentAddress.toString();
    setState(() {
      _isLoading = true;
      _verifiersOffset = 0;
    });
    final result = await ContractReadFunctions.getTreeNFTInfo(
      walletProvider: walletProvider,
      id: toInt(widget.treeId),
      offset: _verifiersOffset,
      limit: _verifiersLimit,
    );
    if (result.success && result.data != null) {
      final List<dynamic> treesData = result.data['details'] ?? [];
      final List<dynamic> verifiersData = result.data['verifiers'] ?? [];
      final String owner = result.data['owner'].toString();
      final int totalCount = result.data['totalCount'] ?? 0;
      final int visibleCount = result.data['visibleCount'] ?? 0;

      treeDetails = Tree.fromContractData(treesData, verifiersData, owner);
      _totalVerifiersCount = totalCount;
      _visibleVerifiersCount = visibleCount;

      canVerify = true;
      for (var verifier in verifiersData) {
        if (verifier[0].toString().toLowerCase() ==
            loggedInUser?.toLowerCase()) {
          canVerify = false;
          break;
        }
      }
    }
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
          lat: (treeDetails!.latitude / 1e6) -
              90.0, // Data stored on the contract is positive in all cases (needs to be converted)
          lng: (treeDetails!.longitude / 1e6) -
              180.0, // Data stored on the contract is positive in all cases (needs to be converted)
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
                    color: getThemeColors(context)['primary'],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      ((treeDetails!.latitude / 1e6) - 90.0).toStringAsFixed(6),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 9,
                          height: 1,
                          color: getThemeColors(context)['textPrimary']),
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
                      style: TextStyle(
                          fontSize: 9,
                          height: 1,
                          color: getThemeColors(context)['textPrimary']),
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
                      style: TextStyle(
                          fontSize: 9,
                          height: 1,
                          color: getThemeColors(context)['textPrimary']),
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
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: canVerify
                    ? getThemeColors(context)['primary']
                    : getThemeColors(context)['secondary'],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    canVerify ? Icons.verified : Icons.lock,
                    color: getThemeColors(context)['textPrimary']!,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canVerify ? "Tree Verification" : "Verification Disabled",
                    style: TextStyle(
                      color: getThemeColors(context)['textPrimary']!,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    canVerify
                        ? "Confirm this tree's authenticity"
                        : "You cannot verify this tree",
                    style: TextStyle(
                      color: getThemeColors(context)['textPrimary'],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: ElevatedButton(
                        onPressed: canVerify
                            ? () async {
                                _showVerificationDialog();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              getThemeColors(context)['background'],
                          foregroundColor: canVerify
                              ? getThemeColors(context)['textPrimary']
                              : getThemeColors(context)['textSecondary'],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          treeVerifiersSection(
            loggedInUser,
            treeDetails,
            loadTreeDetails,
            context,
            currentCount: treeDetails?.verifiers.length ?? 0,
            totalCount: _totalVerifiersCount,
            visibleCount: _visibleVerifiersCount,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildDetailCard(String title, String value) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: getThemeColors(context)['background'],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['textPrimary'],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
          ],
        ),
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
    try {
      WalletProvider walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      if (!walletProvider.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please connect your wallet first"),
            backgroundColor: getThemeColors(context)['primary'],
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                      getThemeColors(context)['textPrimary']!),
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
                Icon(Icons.check_circle,
                    color: getThemeColors(context)['icon']),
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
                Icon(Icons.error, color: getThemeColors(context)['error']),
                const SizedBox(width: 8),
                Expanded(
                    child: Text("Verification failed: ${result.errorMessage}")),
              ],
            ),
            backgroundColor: getThemeColors(context)['error'],
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
          backgroundColor: getThemeColors(context)['error'],
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
                controller: _scrollController,
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
                      if (_isLoadingMore)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Loading more verifiers...",
                                style: TextStyle(
                                  color:
                                      getThemeColors(context)['textSecondary'],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
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
        SnackBar(
          content: Text("Maximum 3 images allowed"),
          backgroundColor: getThemeColors(context)['secondary']!,
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
        SnackBar(
          content: const Text("Maximum 3 images allowed"),
          backgroundColor: getThemeColors(context)['secondary']!,
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
          backgroundColor: getThemeColors(context)['error'],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          backgroundColor: getThemeColors(context)['background'],
          title: Text(
            "Select Image Source",
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['background'],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.camera_alt,
                        color: getThemeColors(context)['primary']),
                    title: Text(
                      "Camera",
                      style: TextStyle(
                        color: getThemeColors(context)['textPrimary'],
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['background'],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.photo_library,
                        color: getThemeColors(context)['primary']),
                    title: Text(
                      "Gallery",
                      style: TextStyle(
                        color: getThemeColors(context)['textPrimary'],
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
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
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: dialogHeight,
          maxWidth: dialogWidth,
        ),
        decoration: BoxDecoration(
          color: getThemeColors(context)['background'],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: getThemeColors(context)['primary'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                border: const Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified,
                      color: getThemeColors(context)['textPrimary'], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Verify Tree",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: getThemeColors(context)['textPrimary'],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close,
                        color: getThemeColors(context)['textPrimary']),
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
                    Text(
                      "Verification Description",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: getThemeColors(context)['textPrimary'],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: TextStyle(
                        color: getThemeColors(context)['textPrimary'],
                      ),
                      decoration: InputDecoration(
                        hintText:
                            "Describe your verification (e.g., tree health, location accuracy, etc.)",
                        hintStyle: TextStyle(
                          color: getThemeColors(context)['textSecondary'],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.black, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.black, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: getThemeColors(context)['primary']!,
                              width: 2),
                        ),
                        filled: true,
                        fillColor: getThemeColors(context)['background'],
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
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: getThemeColors(context)['primary'],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: _selectedImages.length < 3
                                        ? _showImageSourceDialog
                                        : null,
                                    icon: Icon(Icons.add_photo_alternate,
                                        size: 18,
                                        color: getThemeColors(
                                            context)['textPrimary']),
                                    label: Text("Add",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: getThemeColors(
                                              context)['textPrimary'],
                                        )),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
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
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
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
                                        decoration: BoxDecoration(
                                          color:
                                              getThemeColors(context)['error'],
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.black, width: 1),
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
                          color: getThemeColors(context)['secondary'],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    getThemeColors(context)['textPrimary']),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Uploading images to IPFS...",
                              style: TextStyle(
                                color: getThemeColors(context)['textPrimary'],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: getThemeColors(context)['background'],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                                color: getThemeColors(context)['textPrimary']),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
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
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  widget.onVerify(
                                    description:
                                        _descriptionController.text.trim(),
                                    proofHashes: _uploadedHashes,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getThemeColors(context)['primary'],
                            foregroundColor:
                                getThemeColors(context)['textPrimary'],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            _selectedImages.isNotEmpty &&
                                    _uploadedHashes.length !=
                                        _selectedImages.length
                                ? "Upload & Verify"
                                : "Verify Tree",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
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
