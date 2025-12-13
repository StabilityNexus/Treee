import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Geohash utilities for spatial indexing and proximity searches
/// 
/// Geohash is a hierarchical spatial data structure that subdivides space
/// into buckets of grid shape, providing a fast way to find nearby points.
class GeohashUtils {
  // Base32 character set for geohash encoding
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  
  /// Encode latitude and longitude into a geohash string
  /// 
  /// [lat]: Latitude (-90 to 90)
  /// [lng]: Longitude (-180 to 180)
  /// [precision]: Number of characters in geohash (default: 7)
  ///              - 1: ±2500 km
  ///              - 3: ±156 km
  ///              - 5: ±2.4 km
  ///              - 7: ±76 m (good for nearby trees)
  ///              - 9: ±2 m
  static String encode(double lat, double lng, {int precision = 7}) {
    final latRange = [-90.0, 90.0];
    final lngRange = [-180.0, 180.0];
    final geohash = StringBuffer();
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (geohash.length < precision) {
      if (isEven) {
        // Longitude
        final mid = (lngRange[0] + lngRange[1]) / 2;
        if (lng > mid) {
          ch |= (1 << (4 - bit));
          lngRange[0] = mid;
        } else {
          lngRange[1] = mid;
        }
      } else {
        // Latitude
        final mid = (latRange[0] + latRange[1]) / 2;
        if (lat > mid) {
          ch |= (1 << (4 - bit));
          latRange[0] = mid;
        } else {
          latRange[1] = mid;
        }
      }

      isEven = !isEven;

      if (bit < 4) {
        bit++;
      } else {
        geohash.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return geohash.toString();
  }

  /// Decode a geohash string into latitude and longitude
  /// 
  /// Returns the center point of the geohash cell
  static LatLng decode(String geohash) {
    final latRange = [-90.0, 90.0];
    final lngRange = [-180.0, 180.0];
    var isEven = true;

    for (var i = 0; i < geohash.length; i++) {
      final char = geohash[i];
      final cd = _base32.indexOf(char);

      for (var j = 0; j < 5; j++) {
        final mask = 1 << (4 - j);

        if (isEven) {
          // Longitude
          if (cd & mask != 0) {
            lngRange[0] = (lngRange[0] + lngRange[1]) / 2;
          } else {
            lngRange[1] = (lngRange[0] + lngRange[1]) / 2;
          }
        } else {
          // Latitude
          if (cd & mask != 0) {
            latRange[0] = (latRange[0] + latRange[1]) / 2;
          } else {
            latRange[1] = (latRange[0] + latRange[1]) / 2;
          }
        }

        isEven = !isEven;
      }
    }

    final lat = (latRange[0] + latRange[1]) / 2;
    final lng = (lngRange[0] + lngRange[1]) / 2;

    return LatLng(lat, lng);
  }

  /// Get the 8 neighboring geohashes (N, NE, E, SE, S, SW, W, NW)
  /// 
  /// Useful for finding trees in adjacent grid cells
  static List<String> getNeighbors(String geohash) {
    if (geohash.isEmpty) return [];

    return [
      _getNeighbor(geohash, 'top'),
      _getNeighbor(geohash, 'right'),
      _getNeighbor(geohash, 'bottom'),
      _getNeighbor(geohash, 'left'),
      _getNeighbor(_getNeighbor(geohash, 'top'), 'right'),
      _getNeighbor(_getNeighbor(geohash, 'bottom'), 'right'),
      _getNeighbor(_getNeighbor(geohash, 'bottom'), 'left'),
      _getNeighbor(_getNeighbor(geohash, 'top'), 'left'),
    ];
  }

  /// Get all geohashes that cover a circular area
  /// 
  /// [centerLat]: Center latitude
  /// [centerLng]: Center longitude
  /// [radiusKm]: Radius in kilometers
  /// 
  /// Returns list of geohashes (including center and neighbors)
  static List<String> getCoverageGeohashes(
    double centerLat,
    double centerLng,
    double radiusKm,
  ) {
    final precision = getPrecisionForRadius(radiusKm);
    final centerGeohash = encode(centerLat, centerLng, precision: precision);
    final neighbors = getNeighbors(centerGeohash);
    
    return [centerGeohash, ...neighbors];
  }

  /// Calculate optimal geohash precision for a given radius
  /// 
  /// Returns number of characters needed to cover the area efficiently
  static int getPrecisionForRadius(double radiusKm) {
    // Geohash precision vs approximate dimensions
    // 1: ±2500 km
    // 2: ±630 km
    // 3: ±78 km
    // 4: ±20 km
    // 5: ±2.4 km
    // 6: ±0.61 km
    // 7: ±0.076 km (76m)
    // 8: ±0.019 km (19m)
    // 9: ±0.0024 km (2.4m)

    if (radiusKm > 630) return 1;
    if (radiusKm > 78) return 2;
    if (radiusKm > 20) return 3;
    if (radiusKm > 5) return 4;
    if (radiusKm > 1) return 5;
    if (radiusKm > 0.2) return 6;
    if (radiusKm > 0.05) return 7;
    if (radiusKm > 0.01) return 8;
    return 9;
  }

  /// Calculate distance between two points using Haversine formula
  /// 
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371.0; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Internal helper to get neighbor geohash
  static String _getNeighbor(String geohash, String direction) {
    if (geohash.isEmpty) return '';

    final lastChar = geohash[geohash.length - 1];
    final parent = geohash.substring(0, geohash.length - 1);
    final type = geohash.length % 2 == 0 ? 'even' : 'odd';

    // Neighbor lookup tables
    final neighbors = {
      'right': {'even': 'bc01fg45238967deuvhjyznpkmstqrwx', 'odd': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy'},
      'left': {'even': '238967debc01fg45kmstqrwxuvhjyznp', 'odd': '14365h7k9dcfesgujnmqp0r2twvyx8zb'},
      'top': {'even': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy', 'odd': 'bc01fg45238967deuvhjyznpkmstqrwx'},
      'bottom': {'even': '14365h7k9dcfesgujnmqp0r2twvyx8zb', 'odd': '238967debc01fg45kmstqrwxuvhjyznp'},
    };

    final borders = {
      'right': {'even': 'bcfguvyz', 'odd': 'prxz'},
      'left': {'even': '0145hjnp', 'odd': '028b'},
      'top': {'even': 'prxz', 'odd': 'bcfguvyz'},
      'bottom': {'even': '028b', 'odd': '0145hjnp'},
    };

    if (borders[direction]![type]!.contains(lastChar) && parent.isNotEmpty) {
      return _getNeighbor(parent, direction) + _base32[neighbors[direction]![type]!.indexOf(lastChar)];
    }

    return parent + _base32[neighbors[direction]![type]!.indexOf(lastChar)];
  }
}
