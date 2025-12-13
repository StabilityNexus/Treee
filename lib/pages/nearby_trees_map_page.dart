import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/get_current_location.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_read_services.dart';

/// Interactive map page showing nearby planted trees
class NearbyTreesMapPage extends StatefulWidget {
  const NearbyTreesMapPage({super.key});

  @override
  State<NearbyTreesMapPage> createState() => _NearbyTreesMapPageState();
}

class _NearbyTreesMapPageState extends State<NearbyTreesMapPage> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  
  List<Map<String, dynamic>> _nearbyTrees = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double? _userLat;
  double? _userLng;
  int? _selectedTreeId;
  
  // Default location (fallback if GPS fails)
  static const double _defaultLat = 28.9845; // Example: Roorkee, India
  static const double _defaultLng = 77.8956;

  @override
  void initState() {
    super.initState();
    _loadNearbyTrees();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyTrees() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Try to get user's current location, but don't fail if it's unavailable
      try {
        final locationInfo = await _locationService.getCurrentLocation();
        _userLat = locationInfo.latitude;
        _userLng = locationInfo.longitude;
        logger.i("User location: $_userLat, $_userLng");
      } catch (locationError) {
        // Location failed, use default location
        logger.w("Could not get user location, using default: $locationError");
        _userLat = _defaultLat;
        _userLng = _defaultLng;
      }

      // Check if widget is still mounted
      if (!mounted) return;

      // Fetch nearby trees using either actual or default location
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      
      final result = await ContractReadFunctions.getNearbyTrees(
        walletProvider: walletProvider,
        centerLat: _userLat!,
        centerLng: _userLng!,
        radiusKm: 10.0, // 10km radius
      );

      if (result.success && result.data != null) {
        final trees = result.data['trees'] as List<Map<String, dynamic>>;
        
        setState(() {
          _nearbyTrees = trees;
          _isLoading = false;
        });

        logger.i("Loaded ${trees.length} nearby trees");
      } else {
        throw Exception(result.errorMessage ?? 'Failed to load trees');
      }
    } catch (e) {
      logger.e("Error loading nearby trees: $e");
      
      // Use fallback location if not already set
      setState(() {
        _userLat ??= _defaultLat;
        _userLng ??= _defaultLng;
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _recenterMap() {
    if (_userLat != null && _userLng != null) {
      _mapController.move(LatLng(_userLat!, _userLng!), 13.0);
    }
  }

  /// Convert contract coordinates (fixed-point) to decimal degrees
  double _convertCoordinate(int coordinate) {
    return (coordinate / 1000000.0) - 90.0;
  }

  List<Marker> _buildTreeMarkers() {
    return _nearbyTrees.map((tree) {
      final lat = _convertCoordinate(tree['latitude'] as int);
      final lng = _convertCoordinate(tree['longitude'] as int);
      final isSelected = _selectedTreeId == tree['id'];
      
      return Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 50,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedTreeId = tree['id'];
            });
            _showTreeDetails(tree);
          },
          child: Icon(
            Icons.park,
            size: isSelected ? 45 : 35,
            color: isSelected ? Colors.green[700] : Colors.green,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Marker? _buildUserMarker() {
    if (_userLat == null || _userLng == null) return null;
    
    return Marker(
      point: LatLng(_userLat!, _userLng!),
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
        ),
        child: const Icon(
          Icons.my_location,
          color: Colors.blue,
          size: 20,
        ),
      ),
    );
  }

  void _showTreeDetails(Map<String, dynamic> tree) {
    final lat = _convertCoordinate(tree['latitude'] as int);
    final lng = _convertCoordinate(tree['longitude'] as int);
    final plantingDate = DateTime.fromMillisecondsSinceEpoch(
      (tree['planting'] as int) * 1000,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: getThemeColors(context)['background'],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: getThemeColors(context)['border']!,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Tree details
            Text(
              tree['species'] ?? 'Unknown Species',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow(Icons.tag, 'ID #${tree['id']}'),
            _buildDetailRow(Icons.calendar_today, 
                'Planted: ${plantingDate.year}-${plantingDate.month}-${plantingDate.day}'),
            _buildDetailRow(Icons.location_on,
                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
            _buildDetailRow(Icons.favorite, '${tree['careCount']} care events'),
            _buildDetailRow(Icons.photo, 
                '${(tree['photos'] as List).length} photos'),
            
            const SizedBox(height: 16),
            
            // View full details button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/trees/${tree['id']}');
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('View Full Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: getThemeColors(context)['primary'],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: getThemeColors(context)['primary']),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Trees'),
        backgroundColor: getThemeColors(context)['primary'],
      ),
      body: Stack(
        children: [
          // Map
          if (!_isLoading && !_hasError)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_userLat ?? _defaultLat, _userLng ?? _defaultLng),
                initialZoom: 13.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.stability.nexus.tree_planting_protocol',
                ),
                MarkerLayer(
                  markers: [
                    if (_buildUserMarker() != null) _buildUserMarker()!,
                    ..._buildTreeMarkers(),
                  ],
                ),
              ],
            ),
          
          // Loading state
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading nearby trees...'),
                  ],
                ),
              ),
            ),
          
          // Error state
          if (_hasError)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load location',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadNearbyTrees,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          
          // Floating controls
          if (!_isLoading && !_hasError)
            Positioned(
              right: 16,
              bottom: 80,
              child: Column(
                children: [
                  // Recenter button
                  FloatingActionButton(
                    heroTag: 'recenter',
                    onPressed: _recenterMap,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  // Refresh button
                  FloatingActionButton(
                    heroTag: 'refresh',
                    onPressed: _loadNearbyTrees,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.refresh, color: Colors.green),
                  ),
                ],
              ),
            ),
          
          // Tree count badge
          if (!_isLoading && !_hasError && _nearbyTrees.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.park, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_nearbyTrees.length} trees nearby',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
