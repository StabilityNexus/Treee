import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

class CoordinatesMap extends StatefulWidget {
  final Function(double lat, double lng)? onLocationSelected;
  
  const CoordinatesMap({Key? key, this.onLocationSelected, required double lat, required double lng}) : super(key: key);

  @override
  State<CoordinatesMap> createState() => _CoordinatesMapState();
}

class _CoordinatesMapState extends State<CoordinatesMap> {
  late MapController _mapController;
  bool _mapLoaded = false;
  bool _hasError = false;
  String? _errorMessage;
  static const double _defaultLat = 28.9845;
  static const double _defaultLng = 77.8956;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MintNftProvider>(
      builder: (context, provider, _) {
        final double latitude = provider.getLatitude() ?? _defaultLat;
        final double longitude = provider.getLongitude() ?? _defaultLng;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _hasError ? _buildErrorWidget() : _buildMapWidget(latitude, longitude),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Map Unavailable",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please use the coordinate fields below",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWidget(double latitude, double longitude) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: 1.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all, 
            ),
            onMapReady: () {
              setState(() {
                _mapLoaded = true;
              });
            },
            onTap: (tapPosition, point) {
              final provider = Provider.of<MintNftProvider>(context, listen: false);
              provider.setLatitude(point.latitude);
              provider.setLongitude(point.longitude);
              if (widget.onLocationSelected != null) {
                widget.onLocationSelected!(point.latitude, point.longitude);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'tree_planting_protocol',
              errorTileCallback: (tile, error, stackTrace) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = 'Network connection issue';
                  });
                }
              },
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(latitude, longitude),
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (!_mapLoaded)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading map..."),
                ],
              ),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 50,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          if (currentZoom < 18.0) {
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom + 1,
                            );
                          }
                        },
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.add,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          if (currentZoom > 3.0) {
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom - 1,
                            );
                          }
                        },
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.remove,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "Tap to set location • Use zoom buttons or pinch to zoom",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}


class StaticDisplayMap extends StatefulWidget {
  final Function(double lat, double lng)? onLocationSelected;
  final double lat;
  final double lng;

  const StaticDisplayMap({Key? key, this.onLocationSelected, required this.lat, required this.lng}) : super(key: key);

  @override
  State<StaticDisplayMap> createState() => _StaticDisplayMapState();
}

class _StaticDisplayMapState extends State<StaticDisplayMap> {
  late MapController _mapController;
  bool _mapLoaded = false;
  bool _hasError = false;
  String? _errorMessage;
  static const double _defaultLat = 28.9845; // Example: Roorkee, India
  static const double _defaultLng = 77.8956;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }
  double _sanitizeCoordinate(double value, double defaultValue) {
    if (value.isNaN || value.isInfinite || value == double.infinity || value == double.negativeInfinity) {
      logger.e('Invalid coordinate detected: $value, using default: $defaultValue');
      return defaultValue;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    double latitude = _sanitizeCoordinate(widget.lat, _defaultLat);
    double longitude = _sanitizeCoordinate(widget.lng, _defaultLng);
    latitude = latitude.clamp(-90.0, 90.0);
    longitude = longitude.clamp(-180.0, 180.0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _hasError ? _buildErrorWidget() : _buildMapWidget(latitude, longitude),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Map Unavailable",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please use the coordinate fields below",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWidget(double latitude, double longitude) {
    if (latitude.isNaN || latitude.isInfinite || longitude.isNaN || longitude.isInfinite) {
      logger.e('ERROR: Invalid coordinates in _buildMapWidget - lat: $latitude, lng: $longitude');
      latitude = _defaultLat;
      longitude = _defaultLng;
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: 15.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all, 
            ),
            onMapReady: () {
              setState(() {
                _mapLoaded = true;
              });
            },
            onTap: (tapPosition, point) {
              // For static display, you might want to disable tap or handle differently
              if (widget.onLocationSelected != null) {
                widget.onLocationSelected!(point.latitude, point.longitude);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'tree_planting_protocol',
              errorTileCallback: (tile, error, stackTrace) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = 'Network connection issue';
                  });
                }
              },
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(latitude, longitude),
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (!_mapLoaded)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading map..."),
                ],
              ),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 50,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          if (currentZoom < 18.0) {
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom + 1,
                            );
                          }
                        },
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.add,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          if (currentZoom > 3.0) {
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom - 1,
                            );
                          }
                        },
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.remove,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "Static display • Use zoom buttons or pinch to zoom",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}