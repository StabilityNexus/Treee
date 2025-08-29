import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_read_services.dart';
import 'package:tree_planting_protocol/utils/services/contract_write_functions.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/static_map_display_widget.dart';
import 'package:tree_planting_protocol/widgets/nft_display_utils/tree_nft_details_verifiers_widget.dart';


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
    logger.d("Tree Details: ${treeDetails?.verifiers}");
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
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Icon(Icons.verified, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text("Verify Tree"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Are you sure you want to verify this tree? This action will:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildVerificationPoint("• Record verification on blockchain"),
              _buildVerificationPoint("• Require gas fees for transaction"),
              _buildVerificationPoint("• Cannot be undone once confirmed"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performVerification();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text("Verify"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerificationPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Future<void> _performVerification() async {
    logger.d("Starting tree verification process");
    logger.d("Logged in user: $loggedInUser");
    logger.d("Tree ID: ${treeDetails!.id}");

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
        description: "Tree verified by user",
        photos: ["verification_photo"],
      );

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.success) {
        // ignore: use_build_context_synchronously
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
        // ignore: use_build_context_synchronously
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
      // ignore: use_build_context_synchronously
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

      // ignore: use_build_context_synchronously
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
                      const SizedBox(height: 20), // Extra bottom padding
                    ],
                  ),
                ),
              ));
  }
}
