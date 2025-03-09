import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:treee/pages/mint_nft_page.dart';
import 'package:treee/pages/nfts_display_page.dart';
import 'package:treee/pages/user_profile_page.dart';
import 'package:treee/utils/constants.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State createState() => _HomeState();
}

class _HomeState extends State {
  Client? httpClient;
  Web3Client? ethClient;

  @override
  void initState() {
    httpClient = Client();
    ethClient = Web3Client(alchemy_rpc_url, httpClient!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Treee",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UserProfilePage(ethClient: ethClient!)),
              );
            },
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to Treee",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildButton("Mint Treee NFT", Icons.nature, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MintTreeNFTPage(ethClient: ethClient!)),
              );
            }),
            _buildButton("Check Minted Treee NFTs", Icons.eco, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NFTPage(ethClient: ethClient!)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: Icon(icon, color: Colors.white),
          label: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}