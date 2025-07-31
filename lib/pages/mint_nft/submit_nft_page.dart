import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/tree_nft_view_details_with_map.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/constants/contract_abis/tree_nft_contract_abi.dart';

class SubmitNFTPage extends StatefulWidget {
  const SubmitNFTPage({super.key});

  @override
  State<SubmitNFTPage> createState() => _SubmitNFTPageState();
}

class _SubmitNFTPageState extends State<SubmitNFTPage> {
  static final String contractAddress = dotenv.env['CONTRACT_ADDRESS'] ??
      '0xa122109493B90e322824c3444ed8D6236CAbAB7C';

  bool isLoading = false;
  bool isMinting = false;
  String? errorMessage;
  String? lastTransactionHash;

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
          title: Text(title),
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

    if (!walletProvider.isConnected) {
      logger.e("Please connect your wallet before putting this request");
      _showErrorDialog(
          'Wallet Not Connected', 'Please connect your wallet before minting.');
      return;
    }

    setState(() {
      isMinting = true;
      errorMessage = null;
    });

    try {
      final double rawLat = mintNftProvider.getLatitude();
      final double rawLng = mintNftProvider.getLongitude();

      if (rawLat < -90.0 ||
          rawLat > 90.0 ||
          rawLng < -180.0 ||
          rawLng > 180.0) {
        _showErrorDialog(
          'Invalid Coordinates',
          'The selected coordinates are outside the valid range.\nLat: [-90, 90], Lng: [-180, 180].',
        );
        return;
      }
      final lat = BigInt.from((mintNftProvider.getLatitude() + 90.0) * 1e6);
      final lng = BigInt.from((mintNftProvider.getLongitude() + 180.0) * 1e6);
      logger.i("Calculated values being sent: Lat: $lat, Lng: $lng");
      List<dynamic> args = [
        lat,
        lng,
        mintNftProvider.getSpecies(),
        "sampleHash",
        "sameQRIPFSHash",
        mintNftProvider.getGeoHash(),
        mintNftProvider.getInitialPhotos(),
      ];

      final txHash = await walletProvider.writeContract(
        contractAddress: TreeNFtContractAddress,
        functionName: 'mintNft',
        params: args,
        abi: TreeNftContractABI,
        chainId: walletProvider.currentChainId,
      );

      setState(() {
        lastTransactionHash = txHash;
        isMinting = false;
      });

      _showSuccessDialog(
        'Transaction Sent!',
        'Transaction hash: ${txHash.substring(0, 10)}...\n\nThe NFT will be minted once the transaction is confirmed.',
      );
    } catch (e) {
      logger.e("Error occurred", error: e);
      setState(() {
        isMinting = false;
        errorMessage = e.toString();
      });
      _showErrorDialog('Transaction Failed', e.toString());
    }
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
            if (errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ElevatedButton(
              onPressed: isMinting ? null : _mintTreeNft,
              child: isMinting
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text("Minting..."),
                      ],
                    )
                  : const Text("Mint NFT"),
            ),
            if (lastTransactionHash != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Last Transaction:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      lastTransactionHash!.substring(0, 20) + "...",
                      style: const TextStyle(fontFamily: 'monospace'),
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
