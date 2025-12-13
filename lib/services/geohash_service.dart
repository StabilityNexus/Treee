import 'package:dart_geohash/dart_geohash.dart';
import 'package:latlong2/latlong.dart';

/// Service for efficient geospatial queries using geohash
class GeohashService {
  static final GeohashService _instance = GeohashService._internal();
  factory GeohashService() => _instance;
  GeohashService._internal();

  final GeoHasher _geoHasher = GeoHasher();

  /// Default precision for geohash (6 = ~1.2km x 0.6km area)
  static const int defaultPrecision = 6;

  /// Encode coordinates to geohash
  String encode(double latitude, double longitude, {int precision = defaultPrecision}) {
    return _geoHasher.encode(longitude, latitude, precision: precision);
  }

  /// Decode geohash to coordinates
  LatLng decode(String geohash) {
    final decoded = _geoHasher.decode(geohash);
    return LatLng(decoded[1], decoded[0]);
  }

  /// Get bounding box for a geohash
  GeohashBounds getBounds(String geohash) {
    // Calculate approximate bounds based on geohash precision
    final center = decode(geohash);
    final precision = geohash.length;
    
    // Approximate dimensions based on precision
    final latDelta = _getLatDelta(precision);
    final lngDelta = _getLngDelta(precision);
    
    return GeohashBounds(
      southwest: LatLng(center.latitude - latDelta / 2, center.longitude - lngDelta / 2),
      northeast: LatLng(center.latitude + latDelta / 2, center.longitude + lngDelta / 2),
    );
  }

  double _getLatDelta(int precision) {
    // Approximate latitude span for each precision level
    const latDeltas = [180.0, 45.0, 5.6, 1.4, 0.18, 0.022, 0.0027, 0.00068, 0.000085];
    return precision < latDeltas.length ? latDeltas[precision] : 0.00001;
  }

  double _getLngDelta(int precision) {
    // Approximate longitude span for each precision level
    const lngDeltas = [360.0, 45.0, 11.25, 1.4, 0.35, 0.044, 0.0055, 0.00069, 0.000172];
    return precision < lngDeltas.length ? lngDeltas[precision] : 0.00001;
  }

  /// Get neighboring geohashes (8 surrounding + center)
  List<String> getNeighbors(String geohash) {
    final neighbors = <String>[geohash];
    
    // Get all 8 neighbors
    final directions = ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'];
    for (final direction in directions) {
      try {
        final neighbor = _getNeighbor(geohash, direction);
        if (neighbor.isNotEmpty) {
          neighbors.add(neighbor);
        }
      } catch (_) {
        // Skip invalid neighbors at edges
      }
    }
    
    return neighbors;
  }

  String _getNeighbor(String geohash, String direction) {
    if (geohash.isEmpty) return '';
    
    final center = decode(geohash);
    final precision = geohash.length;
    final latDelta = _getLatDelta(precision);
    final lngDelta = _getLngDelta(precision);
    
    double newLat = center.latitude;
    double newLng = center.longitude;
    
    if (direction.contains('n')) newLat += latDelta;
    if (direction.contains('s')) newLat -= latDelta;
    if (direction.contains('e')) newLng += lngDelta;
    if (direction.contains('w')) newLng -= lngDelta;
    
    // Clamp to valid ranges
    newLat = newLat.clamp(-90.0, 90.0);
    newLng = newLng.clamp(-180.0, 180.0);
    
    return encode(newLat, newLng, precision: precision);
  }

  /// Get geohashes covering a bounding box
  List<String> getGeohashesInBounds(LatLng southwest, LatLng northeast, {int precision = defaultPrecision}) {
    final geohashes = <String>{};
    
    final latStep = _getLatDelta(precision) * 0.8;
    final lngStep = _getLngDelta(precision) * 0.8;
    
    for (double lat = southwest.latitude; lat <= northeast.latitude; lat += latStep) {
      for (double lng = southwest.longitude; lng <= northeast.longitude; lng += lngStep) {
        geohashes.add(encode(lat, lng, precision: precision));
      }
    }
    
    return geohashes.toList();
  }

  /// Calculate optimal precision based on zoom level
  int getPrecisionForZoom(double zoom) {
    if (zoom >= 18) return 8;
    if (zoom >= 16) return 7;
    if (zoom >= 14) return 6;
    if (zoom >= 12) return 5;
    if (zoom >= 10) return 4;
    if (zoom >= 8) return 3;
    if (zoom >= 6) return 2;
    return 1;
  }

  /// Check if a geohash starts with any of the given prefixes
  bool matchesAnyPrefix(String geohash, List<String> prefixes) {
    for (final prefix in prefixes) {
      if (geohash.startsWith(prefix)) return true;
    }
    return false;
  }

  /// Calculate distance between two points in meters
  double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }
}

/// Represents bounds of a geohash area
class GeohashBounds {
  final LatLng southwest;
  final LatLng northeast;

  GeohashBounds({required this.southwest, required this.northeast});

  LatLng get center => LatLng(
    (southwest.latitude + northeast.latitude) / 2,
    (southwest.longitude + northeast.longitude) / 2,
  );

  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
           point.latitude <= northeast.latitude &&
           point.longitude >= southwest.longitude &&
           point.longitude <= northeast.longitude;
  }
}
