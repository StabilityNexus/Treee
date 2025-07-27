import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CoordinatesMap extends StatefulWidget {
  const CoordinatesMap({super.key});

  @override
  State<CoordinatesMap> createState() => _CoordinatesMapState();
}

class _CoordinatesMapState extends State<CoordinatesMap> {
  late MapController _mapController;
  bool _mapLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(28.7041, 77.1025), // Delhi coordinates
              initialZoom: 10.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onMapReady: () {
                setState(() {
                  _mapLoaded = true;
                });
              },
              onTap: (tapPosition, point) {
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'tree_planting_protocol', 
                retinaMode: true,
                errorTileCallback: (tile, error, stackTrace) {
                  setState(() {
                    _errorMessage = 'Tile loading error: $error';
                  });
                },
                tileBuilder: (context, tileWidget, tile) {
                  return tileWidget;
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(28.7041, 77.1025),
                    width: 80,
                    height: 80,
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Map Status: ${_mapLoaded ? "Loaded" : "Loading..."}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  if (_errorMessage != null)
                    Text(
                      'Error: $_errorMessage',
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "zoom_in",
            mini: true,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
            child: Icon(Icons.zoom_in),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoom_out",
            mini: true,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
            child: Icon(Icons.zoom_out),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}