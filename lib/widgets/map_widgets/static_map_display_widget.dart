import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class StaticCoordinatesMap extends StatefulWidget {
  final double lat;
  final double lng;
  const StaticCoordinatesMap({super.key, required this.lat, required this.lng});

  @override
  State<StaticCoordinatesMap> createState() => _StaticCoordinatesMapState();
}

class _StaticCoordinatesMapState extends State<StaticCoordinatesMap> {
  late MapController _mapController;
  bool _mapLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double latitude = widget.lat;
    final double longitude = widget.lng;

    return Container(
      height: 200, // Fixed height for consistency
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _hasError
            ? _buildErrorWidget()
            : _buildMapWidget(latitude, longitude),
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
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              "Map Unavailable",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Coordinates: ${widget.lat.toStringAsFixed(6)}, ${widget.lng.toStringAsFixed(6)}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
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
            initialZoom: 12.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.flingAnimation,
            ),
            onMapReady: () {
              setState(() {
                _mapLoaded = true;
              });
              _mapController.move(LatLng(latitude, longitude), 15.0);
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
                  });
                }
              },
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(latitude, longitude),
                  width: 60,
                  height: 60,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.park,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        width: 0,
                        height: 0,
                        decoration: const BoxDecoration(
                          border: Border(
                            left:
                                BorderSide(width: 6, color: Colors.transparent),
                            right:
                                BorderSide(width: 6, color: Colors.transparent),
                            top: BorderSide(width: 8, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (!_mapLoaded)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading tree location...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 60,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
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
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.add,
                        color: Colors.black87,
                        size: 18,
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
                    borderRadius: BorderRadius.zero,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.remove,
                        color: Colors.black87,
                        size: 18,
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
                      _mapController.move(
                        LatLng(latitude, longitude),
                        _mapController.camera.zoom,
                      );
                    },
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
