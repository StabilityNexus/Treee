import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_read_services.dart';

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

class UserNftsWidget extends StatefulWidget {
  final bool isOwnerCalling;
  final String userAddress;

  const UserNftsWidget({
    Key? key,
    required this.isOwnerCalling,
    required this.userAddress,
  }) : super(key: key);

  @override
  State<UserNftsWidget> createState() => _UserNftsWidgetState();
}

class _UserNftsWidgetState extends State<UserNftsWidget> {
  List<Tree> _nfts = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  int _totalCount = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNFTs();
  }

  Future<void> _loadNFTs({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (!loadMore) {
        _errorMessage = null;
        _nfts.clear();
        _currentPage = 0;
      }
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      final result = await ContractReadFunctions.getNFTsByUserPaginated(
        walletProvider: walletProvider,
        offset: 0,
        limit: 10,
      );

      if (result.success && result.data != null) {
        final List<dynamic> treesData = result.data['trees'] ?? [];
        final int totalCount = result.data['totalCount'] ?? 0;

        final List<Tree> newTrees = treesData
            .map((treeData) => Tree.fromContractData(treeData))
            .toList();

        setState(() {
          if (loadMore) {
            _nfts.addAll(newTrees);
          } else {
            _nfts = newTrees;
          }
          _totalCount = totalCount;
          _currentPage++;
          _hasMore = _nfts.length < _totalCount;
        });
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to load NFTs';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading NFTs: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNFTs() async {
    await _loadNFTs();
  }

  Widget _buildNFTCard(Tree tree) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tree.imageUri.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(tree.imageUri),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              tree.species,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Location: ${tree.latitude / 1000000}, ${tree.longitude / 1000000}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Planted: ${DateTime.fromMillisecondsSinceEpoch(tree.planting * 1000).toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Care Count: ${tree.careCount}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tree.death == 0 ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tree.death < DateTime.now().millisecondsSinceEpoch ~/ 1000
                      ? 'Deceased'
                      : 'Alive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.only(right: 6.0, top: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 28, 211, 129),
                        shadowColor: Colors.black,
                        elevation: 4,
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                      onPressed: () {
                        context.push('/trees/${tree.id}');
                      },
                      child: const Text(
                        "View details",
                        style: TextStyle(color: Colors.black),
                      ),
                    )),
                Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 251, 251, 99),
                        shadowColor: Colors.black,
                        elevation: 4,
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "View on the map",
                        style: TextStyle(color: Colors.black),
                      ),
                    ))
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isOwnerCalling ? "Your NFTs" : "User NFTs",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_totalCount > 0)
                  Text(
                    '$_totalCount trees',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _errorMessage != null
                ? _buildErrorWidget()
                : _nfts.isEmpty && !_isLoading
                    ? _buildEmptyWidget()
                    : _buildNFTsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshNFTs,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.eco,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isOwnerCalling
                ? "You don't have any tree NFTs yet"
                : "This user doesn't have any tree NFTs yet",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshNFTs,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildNFTsList() {
    return RefreshIndicator(
      onRefresh: _refreshNFTs,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoading &&
              _hasMore &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _loadNFTs(loadMore: true);
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _nfts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _nfts.length) {
              return _buildNFTCard(_nfts[index]);
            } else {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
