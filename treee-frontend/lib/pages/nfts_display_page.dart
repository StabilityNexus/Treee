import 'package:flutter/material.dart';
import 'package:treee/services/treee_functions.dart';
import 'package:web3dart/web3dart.dart';

const WALLET_ADDRESS = "0x3592638Dbe19AF5005A847CC0881876c87B50D29";

class NFTPage extends StatefulWidget {
  final Web3Client ethClient;

  NFTPage({required this.ethClient});

  @override
  _NFTPageState createState() => _NFTPageState();
}

class _NFTPageState extends State<NFTPage> {
  Future<List<Map<String, dynamic>>> fetchNFTs() async {
    return await getAllNFTs(widget.ethClient);
  }

  Future<bool> isVerified(int tokenId, String verifier) async {
    final result = await ask(
        "isVerified",
        [BigInt.from(tokenId), EthereumAddress.fromHex(verifier)],
        widget.ethClient);
    return result[0];
  }

  Future<void> verifyNFT(int tokenId) async {
    await verifyTree(tokenId, widget.ethClient, WALLET_ADDRESS);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("NFT Collection", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
      ),
      backgroundColor: Colors.green[50],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchNFTs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error fetching NFTs", style: TextStyle(color: Colors.red)));
          }
          final nfts = snapshot.data ?? [];

          return ListView.builder(
            itemCount: nfts.length,
            itemBuilder: (context, index) {
              final nft = nfts[index];
              return FutureBuilder<bool>(
                future: isVerified(int.parse(nft["tokenId"].toString()), WALLET_ADDRESS),
                builder: (context, verifySnapshot) {
                  bool isVerified = verifySnapshot.data ?? false;
                  return Card(
                    margin: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    color: Colors.green[100],
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(nft["imageUri"], fit: BoxFit.cover),
                          ),
                          SizedBox(height: 10),
                          Text("Tree NFT #${nft["tokenId"]}",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
                          SizedBox(height: 5),
                          Text("Species: ${nft["species"]}",
                              style: TextStyle(fontSize: 16, color: Colors.green[900])),
                          Text("Location: ${nft["latitude"]}, ${nft["longitude"]}",
                              style: TextStyle(fontSize: 14, color: Colors.green[700])),
                          Text("Planted: ${DateTime.fromMillisecondsSinceEpoch(int.parse(nft["planting"].toString()) * 1000)}",
                              style: TextStyle(fontSize: 14, color: Colors.green[700])),
                          Text(
                            "Death: ${nft["death"] == "115792089237316195423570985008687907853269984665640564039457584007913129639935" ? "Alive" : DateTime.fromMillisecondsSinceEpoch(int.parse(nft["death"].toString()) * 1000).toString()}",
                            style: TextStyle(fontSize: 14, color: Colors.green[700]),
                          ),
                          Text("Verifiers: ${nft["verifiers"]}",
                              style: TextStyle(fontSize: 14, color: Colors.green[700])),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: isVerified
                                ? null
                                : () => verifyNFT(int.parse(nft["tokenId"].toString())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isVerified ? Colors.grey : Colors.green[600],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(isVerified ? "Verified" : "Verify", style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
