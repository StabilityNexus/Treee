import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_read_services.dart';

class RecentTreesWidget extends StatefulWidget {
  const RecentTreesWidget({super.key});

  @override
  State<RecentTreesWidget> createState() => _RecentTreesWidgetState();
}

class _RecentTreesWidgetState extends State<RecentTreesWidget> {
  List<Map<String, dynamic>> _trees = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentOffset = 0;
  final int _itemsPerPage = 10;
  int _totalCount = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  Future<void> _loadTrees({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (!loadMore) {
        _errorMessage = null;
        _trees.clear();
        _currentOffset = 0;
      }
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      final result = await ContractReadFunctions.getRecentTreesPaginated(
        walletProvider: walletProvider,
        offset: loadMore ? _currentOffset : 0,
        limit: _itemsPerPage,
      );

      if (result.success && result.data != null) {
        final List<dynamic> treesData = result.data['trees'] ?? [];
        final int totalCount = result.data['totalCount'] ?? 0;
        final bool hasMore = result.data['hasMore'] ?? false;

        final List<Map<String, dynamic>> newTrees =
            List<Map<String, dynamic>>.from(treesData);

        setState(() {
          if (loadMore) {
            _trees.addAll(newTrees);
            _currentOffset += newTrees.length;
          } else {
            _trees = newTrees;
            _currentOffset = newTrees.length;
          }
          _totalCount = totalCount;
          _hasMore = hasMore;
        });

        logger.d("Loaded ${newTrees.length} trees, total: ${_trees.length}");
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to load recent trees';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading recent trees: $e';
      });
      logger.e("Error loading recent trees: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTrees() async {
    await _loadTrees();
  }

  double _convertCoordinate(int coordinate) {
    // Convert from fixed-point representation to decimal degrees
    return (coordinate / 1000000.0) - 90.0;
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return "Unknown";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildTreeCard(Map<String, dynamic> tree) {
    final bool isAlive = tree['death'] == 0 ||
        tree['death'] > DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: buttonborderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: buttonBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tree Image
            if (tree['imageUri'] != null &&
                tree['imageUri'].toString().isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: getThemeColors(context)['border']!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    tree['imageUri'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: getThemeColors(context)['secondary'],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: getThemeColors(context)['textPrimary'],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: getThemeColors(context)['secondary'],
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                getThemeColors(context)['primary']!),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Tree ID and Status Row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['primary'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    'ID: ${tree['id']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAlive
                        ? getThemeColors(context)['success'] ?? Colors.green
                        : getThemeColors(context)['error']!,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    isAlive ? 'Alive' : 'Deceased',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Species
            Text(
              tree['species'] ?? 'Unknown Species',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),

            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: getThemeColors(context)['secondary'],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Location: ${_convertCoordinate(tree['latitude']).toStringAsFixed(6)}, ${_convertCoordinate(tree['longitude']).toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Planting Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: getThemeColors(context)['secondary'],
                ),
                const SizedBox(width: 4),
                Text(
                  'Planted: ${_formatDate(tree['planting'])}',
                  style: TextStyle(
                    fontSize: 14,
                    color: getThemeColors(context)['textPrimary'],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Care Information
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 16,
                  color: getThemeColors(context)['secondary'],
                ),
                const SizedBox(width: 4),
                Text(
                  'Care Count: ${tree['careCount'] ?? 0}',
                  style: TextStyle(
                    fontSize: 14,
                    color: getThemeColors(context)['textPrimary'],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.nature,
                  size: 16,
                  color: getThemeColors(context)['primary'],
                ),
                const SizedBox(width: 4),
                Text(
                  'Trees: ${tree['numberOfTrees'] ?? 1}',
                  style: TextStyle(
                    fontSize: 14,
                    color: getThemeColors(context)['textPrimary'],
                  ),
                ),
              ],
            ),

            if (tree['geoHash'] != null &&
                tree['geoHash'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.map,
                    size: 16,
                    color: getThemeColors(context)['primary'],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'GeoHash: ${tree['geoHash']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: getThemeColors(context)['textPrimary'],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/trees/${tree['id']}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getThemeColors(context)['primary'],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                      ),
                      side: const BorderSide(color: Colors.black, width: 2),
                      elevation: buttonBlurRadius,
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement map view functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Map view coming soon!'),
                          backgroundColor: getThemeColors(context)['secondary'],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getThemeColors(context)['secondary'],
                      foregroundColor: getThemeColors(context)['textPrimary'],
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                      ),
                      side: BorderSide(
                        color: getThemeColors(context)['border']!,
                        width: buttonborderWidth,
                      ),
                      elevation: buttonBlurRadius,
                    ),
                    child: const Text(
                      'View on Map',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: getThemeColors(context)['error'],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshTrees,
            style: ElevatedButton.styleFrom(
              backgroundColor: getThemeColors(context)['primary'],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonCircularRadius),
              ),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
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
          Icon(
            Icons.eco,
            size: 64,
            color: getThemeColors(context)['secondary'],
          ),
          const SizedBox(height: 16),
          Text(
            "No recent trees found",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Be the first to plant a tree and contribute to our ecosystem!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshTrees,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: getThemeColors(context)['primary'],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonCircularRadius),
              ),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  getThemeColors(context)['primary']!),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more trees...',
              style: TextStyle(
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tree count badge
        if (_totalCount > 0)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['secondary'],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: getThemeColors(context)['border']!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$_totalCount trees planted',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Content
        Expanded(
          child: _errorMessage != null
              ? _buildErrorWidget()
              : _trees.isEmpty && !_isLoading
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: _refreshTrees,
                      color: getThemeColors(context)['primary'],
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!_isLoading &&
                              _hasMore &&
                              scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent) {
                            _loadTrees(loadMore: true);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _trees.length +
                              (_hasMore && !_isLoading ? 0 : 0) +
                              (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _trees.length) {
                              return _buildTreeCard(_trees[index]);
                            } else if (_isLoading) {
                              return _buildLoadingIndicator();
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
        ),

        // Loading indicator at bottom when loading more
        if (_isLoading && _trees.isNotEmpty) _buildLoadingIndicator(),
      ],
    );
  }
}
