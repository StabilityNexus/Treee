import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LocationWidget extends StatefulWidget {
  const LocationWidget({Key? key}) : super(key: key);

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  String _locationMessage = "Location not determined yet";
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            'Current Location',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const CircularProgressIndicator()
              : Text(
                  _locationMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _getCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Get Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationMessage = "Getting location...";
    });

    Location location = Location();

    try {
      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _locationMessage = "Location services are disabled. Please enable them.";
            _isLoading = false;
          });
          return;
        }
      }

      // Check and request location permissions
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _locationMessage = "Location permissions are denied.";
            _isLoading = false;
          });
          return;
        }
      }

      // Get current location
      LocationData locationData = await location.getLocation();

      setState(() {
        _locationMessage = "Latitude: ${locationData.latitude?.toStringAsFixed(6) ?? 'N/A'}\n"
            "Longitude: ${locationData.longitude?.toStringAsFixed(6) ?? 'N/A'}\n"
            "Accuracy: ${locationData.accuracy?.toStringAsFixed(2) ?? 'N/A'}m";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationMessage = "Error getting location: $e";
        _isLoading = false;
      });
    }
  }
}

// Example usage in your main app
class LocationApp extends StatelessWidget {
  const LocationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Widget Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Location Widget'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: LocationWidget(),
        ),
      ),
    );
  }
}