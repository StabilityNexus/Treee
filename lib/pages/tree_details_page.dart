import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_read_services.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/static_map_display_widget.dart';

final TREE_VERIFIERS_OFFSET = 0;
final TREE_VERIFIERS_LIMIT = 10;

class Tree {
  final int id;
  final int latitude;
  final int longitude;
  final int planting;
  final int death;
  final String species;
  final String imageUri;
  final String qrIpfsHash;
  final String metadata;
  final List<String> photos;
  final String geoHash;
  final List<String> ancestors;
  final int lastCareTimestamp;
  final int careCount;
  final List<String> verifiers;
  final String owner;

  Tree({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.planting,
    required this.death,
    required this.species,
    required this.imageUri,
    required this.qrIpfsHash,
    required this.metadata,
    required this.photos,
    required this.geoHash,
    required this.ancestors,
    required this.lastCareTimestamp,
    required this.careCount,
    required this.verifiers,
    required this.owner,
  });

  factory Tree.fromContractData(
      List<dynamic> userData, List<dynamic> verifiers, String owner) {
    logger.d("User data, Verifiers and Owner");
    logger.d(userData);
    logger.d(verifiers);
    logger.d(owner);
    try {
      if (userData is List && verifiers is List) {
        return Tree(
          id: _toInt(userData[0]),
          latitude: _toInt(userData[1]),
          longitude: _toInt(userData[2]),
          planting: _toInt(userData[3]),
          death: _toInt(userData[4]),
          species: userData[5]?.toString() ?? '',
          imageUri: userData[6]?.toString() ?? '',
          qrIpfsHash: userData[7]?.toString() ?? '',
          metadata: userData[8]?.toString() ?? '',
          photos: userData[9] is List
              ? List<String>.from(userData[9].map((p) => p.toString()))
              : [],
          geoHash: userData[10]?.toString() ?? '',
          ancestors: userData[11] is List
              ? List<String>.from(userData[11].map((a) => a.toString()))
              : [],
          lastCareTimestamp: _toInt(userData[12]),
          careCount: _toInt(userData[13]),
          verifiers: List<String>.from(verifiers.map((a) => a.toString())),
          owner: owner,
        );
      }
      throw Exception("Unexpected data structure: ${userData.runtimeType}");
    } catch (e) {
      return Tree(
        id: 0,
        latitude: 0,
        longitude: 0,
        planting: 0,
        death: 0,
        species: 'Unknown',
        imageUri: '',
        qrIpfsHash: '',
        metadata: '',
        photos: [],
        geoHash: '',
        ancestors: [],
        lastCareTimestamp: 0,
        careCount: 0,
        verifiers: [],
        owner: '',
      );
    }
  }

  static int _toInt(dynamic value) {
    if (value is BigInt) return value.toInt();
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

class TreeDetailsPage extends StatefulWidget {
  final String treeId;
  const TreeDetailsPage({super.key, required this.treeId});

  @override
  State<TreeDetailsPage> createState() => _TreeDetailsPageState();
}

class _TreeDetailsPageState extends State<TreeDetailsPage> {
  String? _errorMessage = "";
  String? loggedInUser = "";
  bool canVerify = false;
  bool _isLoading = false;
  Tree? treeDetails;

  @override
  void initState() {
    super.initState();
    _loadTreeDetails();
  }

  static int _toInt(dynamic value) {
    if (value is BigInt) return value.toInt();
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _loadTreeDetails() async {
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
      canVerify = true;
      for (var verifier in verifiersData) {
        if (verifier.toString().toLowerCase() == loggedInUser) {
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
          lat: treeDetails!.latitude / 1e6,
          lng: treeDetails!.longitude / 1e6,
        ),
      ),
    );
  }

  Widget _buildTreeNFTDetailsSection(double screenHeight, double screenWidth) {
    final componentHeight = (screenHeight * 0.35).clamp(250.0, 350.0);
    final componentWidth = (screenWidth * 0.9);
    return Container(
      height: componentHeight,
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
                      (treeDetails!.latitude / 1e6).toString(),
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
                      (treeDetails!.longitude / 1e6).toString(),
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
          Text("${treeDetails!.metadata}"),
          Text("Care Taken: ${treeDetails!.careCount}"),
          Text("Last Care Taken: ${treeDetails!.lastCareTimestamp}"),
          treeDetails?.owner == loggedInUser
              ? Text("Owner")
              : Text("Not the owner"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return BaseScaffold(
        title: "Tree NFT Details",
        body: _isLoading
            ? Text("Loading")
            : Padding(
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
                          screenHeight, screenWidth),
                    )
                  ],
                ),
              ));
  }
}
