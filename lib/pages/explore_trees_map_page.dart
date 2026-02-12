import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/services/tree_map_service.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/get_current_location.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/map_filter_widget.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/map_search_widget.dart';

class ExploreTreesMapPage extends StatefulWidget {
  const ExploreTreesMapPage({super.key});

  @override
  State<ExploreTreesMapPage> createState() => _ExploreTreesMapPageState();
}

class _ExploreTreesMapPageState extends State<ExploreTreesMapPage> {
  late MapController _mapController;
  final TreeMapService _treeMapService = TreeMapService();
  final LocationService _locationService = LocationService();

  List<TreeCluster> _clusters = [];
  List<MapTreeData> _visibleTrees = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  LatLng? _userLocation;
  double _currentZoom = 10.0;
  MapTreeData? _selectedTree;
  bool _showTreeDetails = false;
  MapFilterOptions _filterOptions = const MapFilterOptions();
  List<String> _availableSpecies = [];

  // Map ready state to prevent race conditions
  bool _mapReady = false;
  LatLng? _pendingCenter;
  double? _pendingZoom;

  // Default center (can be changed based on user location)
  static const LatLng _defaultCenter = LatLng(28.6139, 77.2090); // Delhi, India

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      // Try to get user location
      await _getUserLocation();
      
      // Load initial trees
      await _loadTrees();
    } catch (e) {
      logger.e('Error initializing map: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final locationInfo = await _locationService.getCurrentLocationWithTimeout(
        timeout: const Duration(seconds: 10),
      );

      if (!mounted) return;

      if (locationInfo.isValid) {
        final location = LatLng(locationInfo.latitude!, locationInfo.longitude!);
        setState(() {
          _userLocation = location;
        });

        // Move map to user location if ready, otherwise defer
        _moveMapTo(location, 12.0);
      }
    } catch (e) {
      logger.w('Could not get user location: $e');
      // Use default center
    }
  }

  /// Safely move the map, deferring if not ready
  void _moveMapTo(LatLng center, double zoom) {
    if (_mapReady) {
      _mapController.move(center, zoom);
    } else {
      // Defer until map is ready
      _pendingCenter = center;
      _pendingZoom = zoom;
    }
  }

  /// Called when the map is ready
  void _onMapReady() {
    if (!mounted) return;

    setState(() {
      _mapReady = true;
    });

    // Apply any pending move
    if (_pendingCenter != null) {
      _mapController.move(_pendingCenter!, _pendingZoom ?? 12.0);
      _pendingCenter = null;
      _pendingZoom = null;
    }

    _updateVisibleTrees();
  }

  Future<void> _loadTrees() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    if (!walletProvider.isConnected) {
      setState(() {
        _errorMessage = 'Please connect your wallet to view trees';
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch all trees initially
      await _treeMapService.fetchAllTrees(
        walletProvider: walletProvider,
        limit: 100,
      );

      _updateVisibleTrees();
    } catch (e) {
      logger.e('Error loading trees: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load trees: $e';
        });
      }
    }
  }

  void _updateVisibleTrees() {
    if (!mounted) return;

    // Guard: don't access camera before map is ready
    if (!_mapReady) return;

    final bounds = _mapController.camera.visibleBounds;
    final zoom = _mapController.camera.zoom;

    // Filter trees in visible bounds
    var treesInBounds = _treeMapService.allTrees.where((tree) {
      return tree.latitude >= bounds.south &&
             tree.latitude <= bounds.north &&
             tree.longitude >= bounds.west &&
             tree.longitude <= bounds.east;
    }).toList();

    // Apply filters
    treesInBounds = _applyFilters(treesInBounds);

    // Update available species for filter dropdown
    _updateAvailableSpecies();

    // Cluster trees based on zoom level
    final clusters = _treeMapService.clusterTrees(treesInBounds, zoom);

    setState(() {
      _visibleTrees = treesInBounds;
      _clusters = clusters;
      _currentZoom = zoom;
    });
  }

  List<MapTreeData> _applyFilters(List<MapTreeData> trees) {
    return trees.where((tree) {
      // Status filter
      if (_filterOptions.showAliveOnly && !tree.isAlive) return false;
      if (_filterOptions.showDeceasedOnly && tree.isAlive) return false;

      // Species filter
      if (_filterOptions.speciesFilter != null &&
          tree.species != _filterOptions.speciesFilter) {
        return false;
      }

      // Care count filter
      if (_filterOptions.minCareCount != null &&
          tree.careCount < _filterOptions.minCareCount!) {
        return false;
      }

      // Date filters
      if (_filterOptions.plantedAfter != null) {
        final plantedDate = DateTime.fromMillisecondsSinceEpoch(tree.plantingDate * 1000);
        if (plantedDate.isBefore(_filterOptions.plantedAfter!)) return false;
      }

      if (_filterOptions.plantedBefore != null) {
        final plantedDate = DateTime.fromMillisecondsSinceEpoch(tree.plantingDate * 1000);
        if (plantedDate.isAfter(_filterOptions.plantedBefore!)) return false;
      }

      return true;
    }).toList();
  }

  void _updateAvailableSpecies() {
    final species = _treeMapService.allTrees
        .map((t) => t.species)
        .where((s) => s.isNotEmpty && s != 'Unknown')
        .toSet()
        .toList()
      ..sort();
    
    if (_availableSpecies.length != species.length) {
      _availableSpecies = species;
    }
  }

  void _onFilterChanged(MapFilterOptions newOptions) {
    setState(() {
      _filterOptions = newOptions;
    });
    _updateVisibleTrees();
  }

  void _onSearchResultSelected(MapSearchResult result) {
    // Move map to the result location
    _moveMapTo(
        result.location, result.type == SearchResultType.tree ? 16.0 : 14.0);

    // If it's a tree, show its details
    if (result.tree != null) {
      setState(() {
        _selectedTree = result.tree;
        _showTreeDetails = true;
      });
    }
  }

  Future<void> _onMapMove() async {
    _updateVisibleTrees();
    
    // Load more trees if needed
    if (!_isLoadingMore && _treeMapService.allTrees.length < _treeMapService.totalTreeCount) {
      setState(() => _isLoadingMore = true);
      
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      await _treeMapService.fetchAllTrees(
        walletProvider: walletProvider,
        offset: _treeMapService.allTrees.length,
        limit: 50,
      );
      
      _updateVisibleTrees();
      
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onClusterTap(TreeCluster cluster) {
    if (cluster.isSingleTree) {
      // Show tree details
      setState(() {
        _selectedTree = cluster.singleTree;
        _showTreeDetails = true;
      });
    } else {
      // Zoom in to cluster
      _moveMapTo(cluster.center, _currentZoom + 2);
    }
  }

  void _centerOnUserLocation() async {
    if (_userLocation != null) {
      _moveMapTo(_userLocation!, 14.0);
    } else {
      await _getUserLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return BaseScaffold(
          title: 'Explore Trees',
          body: walletProvider.isConnected
              ? _buildMapContent(context)
              : _buildConnectWalletPrompt(context),
        );
      },
    );
  }

  Widget _buildMapContent(BuildContext context) {
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation ?? _defaultCenter,
            initialZoom: 10.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                _onMapMove();
              }
            },
            onMapReady: _onMapReady,
          ),
          children: [
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'tree_planting_protocol',
            ),
            
            // User location marker
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.my_location, color: Colors.blue, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            
            // Tree clusters/markers
            MarkerLayer(
              markers: _clusters.map((cluster) => _buildClusterMarker(cluster)).toList(),
            ),
          ],
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
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
                    'Loading trees...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Error message
        if (_errorMessage != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getThemeColors(context)['error'],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          ),

        // Stats overlay
        Positioned(
          top: 16,
          left: 16,
          child: _buildStatsCard(context),
        ),

        // Filter widget
        Positioned(
          top: 16,
          right: 70,
          child: MapFilterWidget(
            initialOptions: _filterOptions,
            availableSpecies: _availableSpecies,
            onFilterChanged: _onFilterChanged,
          ),
        ),

        // Quick filters bar
        if (_filterOptions.hasActiveFilters)
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: QuickFilterBar(
              options: _filterOptions,
              onFilterChanged: _onFilterChanged,
            ),
          ),

        // Search widget
        Positioned(
          bottom: _showTreeDetails ? 300 : 120,
          left: 16,
          right: 70,
          child: MapSearchWidget(
            trees: _treeMapService.allTrees,
            onResultSelected: _onSearchResultSelected,
          ),
        ),

        // Control buttons
        Positioned(
          right: 16,
          bottom: _showTreeDetails ? 280 : 100,
          child: _buildControlButtons(context),
        ),

        // Loading more indicator
        if (_isLoadingMore)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: getThemeColors(context)['background'],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          getThemeColors(context)['primary']!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading more trees...',
                      style: TextStyle(
                        color: getThemeColors(context)['textPrimary'],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Tree details panel
        if (_showTreeDetails && _selectedTree != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildTreeDetailsPanel(context),
          ),
      ],
    );
  }

  Marker _buildClusterMarker(TreeCluster cluster) {
    final isSingle = cluster.isSingleTree;
    final tree = cluster.singleTree;
    final isSelected = _selectedTree?.id == tree?.id;

    return Marker(
      point: cluster.center,
      width: isSingle ? 50 : 60,
      height: isSingle ? 50 : 60,
      child: GestureDetector(
        onTap: () => _onClusterTap(cluster),
        child: isSingle
            ? _buildSingleTreeMarker(tree!, isSelected)
            : _buildClusterBubble(cluster),
      ),
    );
  }

  Widget _buildSingleTreeMarker(MapTreeData tree, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: tree.isAlive 
            ? (isSelected ? Colors.green.shade700 : Colors.green)
            : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : Colors.green.shade900,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.park,
          color: Colors.white,
          size: isSelected ? 28 : 24,
        ),
      ),
    );
  }

  Widget _buildClusterBubble(TreeCluster cluster) {
    final count = cluster.totalTreeCount;
    final color = count > 50 
        ? Colors.red 
        : count > 20 
            ? Colors.orange 
            : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color.shade900, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.park, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background']!.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getThemeColors(context)['border']!),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco,
                color: getThemeColors(context)['primary'],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_treeMapService.totalTreeCount} Trees',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: getThemeColors(context)['textPrimary'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_visibleTrees.length} visible',
            style: TextStyle(
              fontSize: 12,
              color: getThemeColors(context)['textPrimary']!.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom in
        _buildControlButton(
          context,
          icon: Icons.add,
          onTap: () {
            final newZoom = (_currentZoom + 1).clamp(3.0, 18.0);
            _mapController.move(_mapController.camera.center, newZoom);
          },
        ),
        const SizedBox(height: 8),
        // Zoom out
        _buildControlButton(
          context,
          icon: Icons.remove,
          onTap: () {
            final newZoom = (_currentZoom - 1).clamp(3.0, 18.0);
            _mapController.move(_mapController.camera.center, newZoom);
          },
        ),
        const SizedBox(height: 16),
        // Center on user location
        _buildControlButton(
          context,
          icon: Icons.my_location,
          onTap: _centerOnUserLocation,
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        // Refresh
        _buildControlButton(
          context,
          icon: Icons.refresh,
          onTap: () {
            _treeMapService.clearCache();
            _initializeMap();
          },
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: getThemeColors(context)['background'],
      borderRadius: BorderRadius.circular(8),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: getThemeColors(context)['border']!),
          ),
          child: Icon(
            icon,
            color: color ?? getThemeColors(context)['icon'],
          ),
        ),
      ),
    );
  }

  Widget _buildTreeDetailsPanel(BuildContext context) {
    final tree = _selectedTree!;
    
    return Container(
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: getThemeColors(context)['border'],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Tree image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: getThemeColors(context)['border']!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: tree.imageUri.isNotEmpty
                            ? Image.network(
                                tree.imageUri,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.park,
                                  color: getThemeColors(context)['primary'],
                                  size: 30,
                                ),
                              )
                            : Icon(
                                Icons.park,
                                color: getThemeColors(context)['primary'],
                                size: 30,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Tree info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: getThemeColors(context)['primary'],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ID: ${tree.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tree.isAlive ? Colors.green : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tree.isAlive ? 'Alive' : 'Deceased',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tree.species,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: getThemeColors(context)['textPrimary'],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Close button
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: getThemeColors(context)['icon'],
                      ),
                      onPressed: () {
                        setState(() {
                          _showTreeDetails = false;
                          _selectedTree = null;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Details row
                Row(
                  children: [
                    _buildDetailChip(
                      context,
                      icon: Icons.location_on,
                      label: '${tree.latitude.toStringAsFixed(4)}, ${tree.longitude.toStringAsFixed(4)}',
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      context,
                      icon: Icons.favorite,
                      label: '${tree.careCount} care',
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    _buildDetailChip(
                      context,
                      icon: Icons.nature,
                      label: '${tree.numberOfTrees} trees',
                    ),
                    const SizedBox(width: 8),
                    if (tree.geoHash.isNotEmpty)
                      _buildDetailChip(
                        context,
                        icon: Icons.grid_on,
                        label: tree.geoHash.length >= 6
                            ? tree.geoHash.substring(0, 6)
                            : tree.geoHash,
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/trees/${tree.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getThemeColors(context)['primary'],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonCircularRadius),
                      ),
                      side: const BorderSide(color: Colors.black, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Full Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(BuildContext context, {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: getThemeColors(context)['secondary']!.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: getThemeColors(context)['border']!.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: getThemeColors(context)['textPrimary']),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectWalletPrompt(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: getThemeColors(context)['primary'],
            ),
            const SizedBox(height: 24),
            Text(
              'Connect to Explore',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['textPrimary'],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect your wallet to explore trees on the map and discover trees planted around you.',
              style: TextStyle(
                fontSize: 16,
                color: getThemeColors(context)['textPrimary'],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final walletProvider = Provider.of<WalletProvider>(
                  context,
                  listen: false,
                );
                try {
                  await walletProvider.connectWallet();
                  if (mounted && walletProvider.isConnected) {
                    _initializeMap();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to connect: $e'),
                        backgroundColor: getThemeColors(context)['error'],
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text(
                'Connect Wallet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: getThemeColors(context)['primary'],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonCircularRadius),
                ),
                side: const BorderSide(color: Colors.black, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
