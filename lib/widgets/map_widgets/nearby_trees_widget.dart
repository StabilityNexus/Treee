import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/services/geohash_service.dart';
import 'package:tree_planting_protocol/services/tree_map_service.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/get_current_location.dart';
import 'package:latlong2/latlong.dart';

/// Widget that displays trees near the user's current location
class NearbyTreesWidget extends StatefulWidget {
  final double radiusMeters;
  final int maxTrees;

  const NearbyTreesWidget({
    super.key,
    this.radiusMeters = 5000,
    this.maxTrees = 10,
  });

  @override
  State<NearbyTreesWidget> createState() => _NearbyTreesWidgetState();
}

class _NearbyTreesWidgetState extends State<NearbyTreesWidget> {
  final TreeMapService _treeMapService = TreeMapService();
  final LocationService _locationService = LocationService();
  final GeohashService _geohashService = GeohashService();

  List<MapTreeData> _nearbyTrees = [];
  bool _isLoading = true;
  String? _errorMessage;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadNearbyTrees();
  }

  Future<void> _loadNearbyTrees() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user location
      final locationInfo = await _locationService.getCurrentLocationWithTimeout(
        timeout: const Duration(seconds: 15),
      );

      // Check mounted after await
      if (!mounted) return;

      if (!locationInfo.isValid) {
        setState(() {
          _errorMessage = 'Could not determine your location';
          _isLoading = false;
        });
        return;
      }

      _userLocation = LatLng(locationInfo.latitude!, locationInfo.longitude!);

      // Get wallet provider (safe to use context now since we checked mounted)
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      if (!walletProvider.isConnected) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Please connect your wallet';
          _isLoading = false;
        });
        return;
      }

      // Fetch nearby trees
      final trees = await _treeMapService.getTreesNearLocation(
        walletProvider: walletProvider,
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        radiusMeters: widget.radiusMeters,
      );

      // Check mounted after await
      if (!mounted) return;

      setState(() {
        _nearbyTrees = trees.take(widget.maxTrees).toList();
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading nearby trees: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load nearby trees';
        _isLoading = false;
      });
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_nearbyTrees.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildTreesList(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              getThemeColors(context)['primary']!,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Finding trees near you...',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: getThemeColors(context)['error'],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNearbyTrees,
            style: ElevatedButton.styleFrom(
              backgroundColor: getThemeColors(context)['primary'],
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.park_outlined,
            size: 48,
            color: getThemeColors(context)['secondary'],
          ),
          const SizedBox(height: 16),
          Text(
            'No trees found nearby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to plant a tree in your area!',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push('/mint-nft'),
                icon: const Icon(Icons.add),
                label: const Text('Plant Tree'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: getThemeColors(context)['primary'],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/explore-map'),
                icon: const Icon(Icons.map),
                label: const Text('Explore Map'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreesList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.near_me,
                color: getThemeColors(context)['primary'],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Trees Near You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: getThemeColors(context)['textPrimary'],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/explore-map'),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: getThemeColors(context)['primary'],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal list of nearby trees
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _nearbyTrees.length,
            itemBuilder: (context, index) {
              final tree = _nearbyTrees[index];
              final distance = _userLocation != null
                  ? _geohashService.calculateDistance(_userLocation!, tree.position)
                  : 0.0;

              return _buildTreeCard(context, tree, distance);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTreeCard(BuildContext context, MapTreeData tree, double distance) {
    return GestureDetector(
      onTap: () => context.push('/trees/${tree.id}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: getThemeColors(context)['background'],
          borderRadius: BorderRadius.circular(buttonCircularRadius),
          border: Border.all(
            color: getThemeColors(context)['border']!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: getThemeColors(context)['secondary']!.withValues(alpha: 0.3),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: tree.imageUri.isNotEmpty
                    ? Image.network(
                        tree.imageUri,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.park,
                            color: getThemeColors(context)['primary'],
                            size: 32,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.park,
                          color: getThemeColors(context)['primary'],
                          size: 32,
                        ),
                      ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tree.species,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: getThemeColors(context)['primary'],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatDistance(distance),
                        style: TextStyle(
                          fontSize: 11,
                          color: getThemeColors(context)['textPrimary']!.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tree.isAlive ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tree.isAlive ? 'Alive' : 'Deceased',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '#${tree.id}',
                        style: TextStyle(
                          fontSize: 10,
                          color: getThemeColors(context)['textPrimary']!.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
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
