import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/nft_display_utils/tree_nft_view_details_with_map.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_write_functions.dart';

class SubmitNFTPage extends StatefulWidget {
  const SubmitNFTPage({super.key});

  @override
  State<SubmitNFTPage> createState() => _SubmitNFTPageState();
}

class _SubmitNFTPageState extends State<SubmitNFTPage> {
  bool isLoading = false;
  bool isMinting = false;
  String? errorMessage;
  String? lastTransactionHash;
  Map<String, dynamic>? lastTransactionData;

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mintTreeNft() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final mintNftProvider =
        Provider.of<MintNftProvider>(context, listen: false);

    setState(() {
      isMinting = true;
      errorMessage = null;
    });

    try {
      final result = await ContractWriteFunctions.mintNft(
        walletProvider: walletProvider,
        latitude: mintNftProvider.getLatitude(),
        longitude: mintNftProvider.getLongitude(),
        species: mintNftProvider.getSpecies(),
        photos: mintNftProvider.getInitialPhotos(),
        geoHash: mintNftProvider.getGeoHash(),
        metadata: mintNftProvider.getDetails(),
      );

      setState(() {
        isMinting = false;
        if (result.success) {
          lastTransactionHash = result.transactionHash;
          lastTransactionData = result.data;
          errorMessage = null;
        } else {
          errorMessage = result.errorMessage;
          lastTransactionHash = null;
          lastTransactionData = null;
        }
      });

      if (result.success) {
        _showSuccessDialog(
          'Transaction Sent!',
          'Transaction hash: ${result.transactionHash!.substring(0, 10)}...\n\n'
              'The NFT will be minted once the transaction is confirmed.\n\n'
              'Species: ${result.data['species']}\n'
              'Photos: ${result.data['photos'].length} uploaded',
        );
      } else {
        _showErrorDialog('Transaction Failed', result.errorMessage!);
      }
    } catch (e) {
      logger.e("Unexpected error in _mintTreeNft", error: e);
      setState(() {
        isMinting = false;
        errorMessage = 'Unexpected error: ${e.toString()}';
      });
      _showErrorDialog('Unexpected Error', e.toString());
    }
  }

  Widget _buildTransactionInfo() {
    if (lastTransactionHash == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text(
                "Last Transaction:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Hash: ${lastTransactionHash!.substring(0, 20)}...",
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          if (lastTransactionData != null) ...[
            const SizedBox(height: 8),
            Text(
              "Species: ${lastTransactionData!['species']}",
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              "Photos: ${lastTransactionData!['photos']?.length ?? 0}",
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              "Location: (${lastTransactionData!['latitude']?.toStringAsFixed(6)}, ${lastTransactionData!['longitude']?.toStringAsFixed(6)})",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorInfo() {
    if (errorMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text(
                "Error:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Submit NFT",
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NewNFTMapWidget(),
            const SizedBox(height: 30),

            _buildErrorInfo(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isMinting ? null : _mintTreeNft,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isMinting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text("Minting...", style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Text(
                          "Mint NFT",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Transaction info display
            _buildTransactionInfo(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
