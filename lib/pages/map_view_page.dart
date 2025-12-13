import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/models/tree_details.dart';
import 'package:tree_planting_protocol/providers/map_provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/get_current_location.dart';
import 'package:tree_planting_protocol/utils/services/tree_map_service.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/tree_map_widgets.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  final MapController _mapController = MapController();
  Tree? _selectedTree;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    if (_isInitialized) return;
    
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    
    try {
      // Get user location
      final location = await LocationService().getCurrentLocation();
      if (location.isValid) {
        mapProvider.setUserLocation(LatLng(location.latitude!, location.longitude!));
        logger.d("User location set: ${location.latitude}, ${location.longitude}");
      }
      
      _isInitialized = true;
      
      // Load initial trees
      await _loadTreesInArea();
    } catch (e) {
      logger.e("Error initializing map: $e");
      mapProvider.setError("Failed to initialize map: $e");
    }
  }

  Future<void> _loadTreesInArea() async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    if (!walletProvider.isConnected) {
      mapProvider.setError("Please connect your wallet to view trees");
      return;
    }
    
    mapProvider.setLoading(true);
    mapProvider.clearError();
    
    try {
      final bounds = mapProvider.getBoundingBox();
      
      logger.d("Loading trees in bounds: $bounds");
      
      final trees = await TreeMapService.getTreesInBoundingBox(
        walletProvider: walletProvider,
        minLat: bounds['minLat']!,
        maxLat: bounds['maxLat']!,
        minLng: bounds['minLng']!,
        maxLng: bounds['maxLng']!,
        maxTrees: 100,
      );
      
      mapProvider.setLoadedTrees(trees);
      
      if (trees.isEmpty) {
        mapProvider.setError("No trees found in this area. Try moving the map or zooming out.");
      }
      
      logger.d("Loaded ${trees.length} trees");
    } catch (e) {
      logger.e("Error loading trees: $e");
      mapProvider.setError("Failed to load trees: $e");
    } finally {
      mapProvider.setLoading(false);
    }
  }

  void _onMapEvent(MapEvent event) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    
    if (event is MapEventMove) {
      mapProvider.setCurrentCenter(event.camera.center);
      mapProvider.setCurrentZoom(event.camera.zoom);
    } else if (event is MapEventRotate) {
      mapProvider.setCurrentCenter(event.camera.center);
      mapProvider.setCurrentZoom(event.camera.zoom);
    }
  }

  void _zoomIn() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final newZoom = (mapProvider.currentZoom + 1).clamp(3.0, 18.0);
    _mapController.move(mapProvider.currentCenter, newZoom);
  }

  void _zoomOut() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final newZoom = (mapProvider.currentZoom - 1).clamp(3.0, 18.0);
    _mapController.move(mapProvider.currentCenter, newZoom);
  }

  void _centerOnUser() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    if (mapProvider.hasUserLocation) {
      _mapController.move(mapProvider.userLocation!, mapProvider.currentZoom);
    }
  }

  void _onTreeMarkerTap(Tree tree) {
    setState(() {
      _selectedTree = tree;
    });
  }

  void _closeTreeCard() {
    setState(() {
      _selectedTree = null;
    });
  }

  void _viewTreeDetails(Tree tree) {
    context.push('/trees/${tree.id}');
  }

  double _convertLatitude(int coordinate) {
    // Encoding: (latitude + 90.0) * 1e6
    return (coordinate / 1000000.0) - 90.0;
  }
  
  double _convertLongitude(int coordinate) {
    // Encoding: (longitude + 180.0) * 1e6
    return (coordinate / 1000000.0) - 180.0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MapProvider, WalletProvider>(
      builder: (context, mapProvider, walletProvider, child) {
        return BaseScaffold(
          title: "Tree Map",
          body: walletProvider.isConnected
              ? _buildMapView(mapProvider)
              : _buildConnectWalletPrompt(),
        );
      },
    );
  }

  Widget _buildMapView(MapProvider mapProvider) {
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapProvider.currentCenter,
            initialZoom: mapProvider.currentZoom,
            onMapEvent: _onMapEvent,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.stabilitynexus.treeplantingprotocol',
            ),
            
            // Tree markers
            MarkerLayer(
              markers: mapProvider.loadedTrees.map((tree) {
                final lat = _convertLatitude(tree.latitude);
                final lng = _convertLongitude(tree.longitude);
                
                return Marker(
                  point: LatLng(lat, lng),
                  width: 40,
                  height: 40,
                  child: TreeMarkerWidget(
                    tree: tree,
                    onTap: () => _onTreeMarkerTap(tree),
                  ),
                );
              }).toList(),
            ),
            
            // User location marker
            if (mapProvider.hasUserLocation)
              MarkerLayer(
                markers: [
                  Marker(
                    point: mapProvider.userLocation!,
                    width: 40,
                    height: 40,
                    child: const UserLocationMarker(),
                  ),
                ],
              ),
          ],
        ),
        
        // Map controls
        Positioned(
          right: 16,
          top: 16,
          child: MapControlsWidget(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onCenterUser: _centerOnUser,
            onLoadTrees: _loadTreesInArea,
            isLoading: mapProvider.isLoading,
            hasUserLocation: mapProvider.hasUserLocation,
          ),
        ),
        
        // Tree info card
        if (_selectedTree != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TreeInfoCard(
              tree: _selectedTree!,
              onViewDetails: () => _viewTreeDetails(_selectedTree!),
              onClose: _closeTreeCard,
            ),
          ),
        
        // Error message
        if (mapProvider.errorMessage != null)
          Positioned(
            top: 16,
            left: 16,
            right: 80,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mapProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => mapProvider.clearError(),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        
        // Loading indicator at top
        if (mapProvider.isLoading && mapProvider.errorMessage == null)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading trees...',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        
        // Trees count
        if (!mapProvider.isLoading && mapProvider.loadedTrees.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${mapProvider.loadedTrees.length} trees',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectWalletPrompt() {
    final themeColors = getThemeColors(context);
    final primaryColor = themeColors['primary'] ?? Theme.of(context).colorScheme.primary;
    final backgroundColor = themeColors['background'] ?? Theme.of(context).colorScheme.surface;
    final borderColor = themeColors['border'] ?? Theme.of(context).colorScheme.outline;
    final textPrimaryColor = themeColors['textPrimary'] ?? Theme.of(context).colorScheme.onSurface;
    final textSecondaryColor = themeColors['textSecondary'] ?? Theme.of(context).colorScheme.onSurfaceVariant;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect Your Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please connect your wallet to view trees on the map',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
