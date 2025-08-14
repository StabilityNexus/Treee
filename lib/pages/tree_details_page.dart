import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_read_services.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/static_map_display_widget.dart';

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
  });

  factory Tree.fromContractData(dynamic data) {
    logger.d("The data i am getting here");
    logger.d(data);
    try {
      dynamic actualData = data;
      if (data is List && data.length == 1) {
        actualData = data[0];
      }

      if (actualData is List) {
        return Tree(
          id: _toInt(actualData[0]),
          latitude: _toInt(actualData[1]),
          longitude: _toInt(actualData[2]),
          planting: _toInt(actualData[3]),
          death: _toInt(actualData[4]),
          species: actualData[5]?.toString() ?? '',
          imageUri: actualData[6]?.toString() ?? '',
          qrIpfsHash: actualData[7]?.toString() ?? '',
          metadata: actualData[8]?.toString() ?? '',
          photos: actualData[9] is List
              ? List<String>.from(actualData[9].map((p) => p.toString()))
              : [],
          geoHash: actualData[10]?.toString() ?? '',
          ancestors: actualData[11] is List
              ? List<String>.from(actualData[11].map((a) => a.toString()))
              : [],
          lastCareTimestamp: _toInt(actualData[12]),
          careCount: _toInt(actualData[13]),
        );
      }
      throw Exception("Unexpected data structure: ${actualData.runtimeType}");
    } catch (e) {
      debugPrint("Error parsing Tree data: $e");
      debugPrint("Data received: $data");
      debugPrint("Data type: ${data.runtimeType}");

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
    setState(() {
      _isLoading = true;
    });
    final result = await ContractReadFunctions.getTreeNFTInfo(
        walletProvider: walletProvider, id: _toInt(widget.treeId));
    if (result.success && result.data != null) {
      final List<dynamic> treesData = result.data['details'] ?? [];
      treeDetails = Tree.fromContractData(treesData);
    }
    setState(() {});
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
          Text("Care Taken: ${treeDetails!.careCount}")
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
        body: Padding(
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
                child: _buildTreeNFTDetailsSection(screenHeight, screenWidth),
              )
            ],
          ),
        ));
  }
}
