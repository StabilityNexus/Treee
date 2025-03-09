import 'package:flutter/material.dart';
import 'package:treee/services/treee_functions.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:convert';

const USER_ADDRESS = "0x3592638Dbe19AF5005A847CC0881876c87B50D29";
const USER_NAME = "John Doe";

class UserProfilePage extends StatefulWidget {
  final Web3Client ethClient;

  UserProfilePage({required this.ethClient});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Future<List<Map<String, dynamic>>> fetchUserNFTs() async {
    return await getUsersNFTs(widget.ethClient, USER_ADDRESS);
  }

  Future<void> markTreeDead(int tokenId) async {
    await markTreeAsDead(tokenId, widget.ethClient);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUserNFTs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error fetching NFTs"));
          }
          final nfts = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("User Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("Name: $USER_NAME", style: TextStyle(fontSize: 16)),
                        Text("Address: $USER_ADDRESS", style: TextStyle(fontSize: 16, overflow: TextOverflow.ellipsis)),
                        Text("Total NFTs: ${nfts.length}", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text("MY NFTs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: nfts.length,
                  itemBuilder: (context, index) {
                    final nft = nfts[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                            child: Image.network(nft["imageUri"], height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Tree NFT #${nft["tokenId"]}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 5),
                                Text("Species: ${nft["species"]}"),
                                Text("Location: ${nft["latitude"]}, ${nft["longitude"]}"),
                                Text("Planted: ${DateTime.fromMillisecondsSinceEpoch(int.parse(nft["planting"].toString()) * 1000)}"),
                                Text("Death: ${nft["death"] == "115792089237316195423570985008687907853269984665640564039457584007913129639935" ? "Alive" : DateTime.fromMillisecondsSinceEpoch(int.parse(nft["death"].toString()) * 1000).toString()}"),
                                Text("Verifiers: ${nft["verifiers"]}"),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => markTreeDead(int.parse(nft["tokenId"].toString())),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                  ),
                                  child: Text("Mark Tree Dead", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}