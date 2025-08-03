import 'package:location/location.dart';
import 'package:tree_planting_protocol/utils/logger.dart';


class LocationException implements Exception {
  final String message;
  final LocationErrorType type;
  
  const LocationException(this.message, this.type);
  
  @override
  String toString() => 'LocationException: $message';
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  locationUnavailable,
  unknown,
}
class LocationInfo {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? speedAccuracy;
  final double? heading;
  final int? time;

  const LocationInfo({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.speedAccuracy,
    this.heading,
    this.time,
  });

  factory LocationInfo.fromLocationData(LocationData data) {
    return LocationInfo(
      latitude: data.latitude,
      longitude: data.longitude,
      accuracy: data.accuracy,
      altitude: data.altitude,
      speed: data.speed,
      speedAccuracy: data.speedAccuracy,
      heading: data.heading,
      time: data.time?.toInt(),
    );
  }
  String get formattedLocation {
    return "Latitude: ${latitude?.toStringAsFixed(6) ?? 'N/A'}\n"
           "Longitude: ${longitude?.toStringAsFixed(6) ?? 'N/A'}\n"
           "Accuracy: ${accuracy?.toStringAsFixed(2) ?? 'N/A'}m";
  }
  bool get isValid => latitude != null && longitude != null;

  @override
  String toString() {
    return 'LocationInfo(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Location _location = Location();
  Future<LocationInfo> getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          const error = "Location services are disabled. Please enable them in settings.";
          logger.e(error);
          throw const LocationException(error, LocationErrorType.serviceDisabled);
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          const error = "Location permissions are denied. Please grant location access.";
          logger.e(error);
          throw const LocationException(error, LocationErrorType.permissionDenied);
        }
      }
      LocationData locationData = await _location.getLocation();
      
      if (locationData.latitude == null || locationData.longitude == null) {
        const error = "Unable to retrieve valid location coordinates.";
        logger.e(error);
        throw const LocationException(error, LocationErrorType.locationUnavailable);
      }

      logger.i("Location retrieved successfully: ${locationData.latitude}, ${locationData.longitude}");
      return LocationInfo.fromLocationData(locationData);

    } catch (e) {
      if (e is LocationException) {
        rethrow;
      }
      
      final error = "Error getting location: $e";
      logger.e(error);
      throw LocationException(error, LocationErrorType.unknown);
    }
  }

  Future<LocationInfo> getCurrentLocationWithTimeout({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return Future.any([
      getCurrentLocation(),
      Future.delayed(timeout, () {
        throw const LocationException(
          "Location request timed out",
          LocationErrorType.locationUnavailable,
        );
      }),
    ]);
  }
  Stream<LocationInfo> getLocationStream() {
    return _location.onLocationChanged.map((locationData) {
      return LocationInfo.fromLocationData(locationData);
    });
  }
  Future<bool> isLocationServiceAvailable() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) return false;

      PermissionStatus permissionGranted = await _location.hasPermission();
      return permissionGranted == PermissionStatus.granted;
    } catch (e) {
      logger.e("Error checking location service availability: $e");
      return false;
    }
  }
}