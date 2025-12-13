import 'package:latlong2/latlong.dart';
import 'package:tree_planting_protocol/utils/geohash_utils.dart';

/// Represents a cluster of nearby trees
class TreeCluster {
  final LatLng center;
  final int count;
  final List<Map<String, dynamic>> trees;
  final LatLngBounds bounds;

  TreeCluster({
    required this.center,
    required this.count,
    required this.trees,
    required this.bounds,
  });

  /// Get a representative tree from the cluster (for displaying info)
  Map<String, dynamic>? get representativeTree => trees.isNotEmpty ? trees.first : null;
}

/// Service for clustering trees based on proximity and zoom level
class TreeClusteringService {
  /// Cluster trees based on zoom level
  /// 
  /// [trees]: List of trees to cluster
  /// [zoomLevel]: Current map zoom level (3-18)
  /// [minClusterSize]: Minimum trees to form a cluster (default: 2)
  /// 
  /// Returns list of clusters. Each cluster contains all trees in that area.
  static List<TreeCluster> clusterTrees(
    List<Map<String, dynamic>> trees,
    double zoomLevel, {
    int minClusterSize = 2,
  }) {
    if (trees.isEmpty) return [];

    // At high zoom levels (14+), don't cluster - show individual trees
    if (zoomLevel >= 14) {
      return trees.map((tree) {
        final lat = _convertCoordinate(tree['latitude'] as int);
        final lng = _convertCoordinate(tree['longitude'] as int);
        return TreeCluster(
          center: LatLng(lat, lng),
          count: 1,
          trees: [tree],
          bounds: LatLngBounds(LatLng(lat, lng), LatLng(lat, lng)),
        );
      }).toList();
    }

    // Calculate cluster distance based on zoom level
    final clusterDistanceKm = _getClusterDistance(zoomLevel);
    
    // Group trees by geohash at appropriate precision
    final precision = GeohashUtils.getPrecisionForRadius(clusterDistanceKm);
    final Map<String, List<Map<String, dynamic>>> geohashGroups = {};

    for (final tree in trees) {
      final lat = _convertCoordinate(tree['latitude'] as int);
      final lng = _convertCoordinate(tree['longitude'] as int);
      final geohash = GeohashUtils.encode(lat, lng, precision: precision);

      geohashGroups.putIfAbsent(geohash, () => []);
      geohashGroups[geohash]!.add(tree);
    }

    // Create clusters from groups
    final clusters = <TreeCluster>[];

    for (final entry in geohashGroups.entries) {
      final treesInGroup = entry.value;

      // Only create cluster if we have enough trees
      if (treesInGroup.length >= minClusterSize) {
        final bounds = _calculateBounds(treesInGroup);
        final center = LatLng(
          (bounds.north + bounds.south) / 2,
          (bounds.east + bounds.west) / 2,
        );

        clusters.add(TreeCluster(
          center: center,
          count: treesInGroup.length,
          trees: treesInGroup,
          bounds: bounds,
        ));
      } else {
        // Too few trees, add individually
        for (final tree in treesInGroup) {
          final lat = _convertCoordinate(tree['latitude'] as int);
          final lng = _convertCoordinate(tree['longitude'] as int);
          clusters.add(TreeCluster(
            center: LatLng(lat, lng),
            count: 1,
            trees: [tree],
            bounds: LatLngBounds(LatLng(lat, lng), LatLng(lat, lng)),
          ));
        }
      }
    }

    return clusters;
  }

  /// Get cluster distance based on zoom level
  /// 
  /// Lower zoom = larger clusters (more km between centers)
  /// Higher zoom = smaller clusters (less km between centers)
  static double _getClusterDistance(double zoom) {
    if (zoom <= 5) return 100.0; // 100km clusters
    if (zoom <= 7) return 50.0;  // 50km clusters
    if (zoom <= 9) return 20.0;  // 20km clusters
    if (zoom <= 11) return 5.0;  // 5km clusters
    if (zoom <= 13) return 1.0;  // 1km clusters
    return 0.2; // 200m clusters
  }

  /// Calculate bounding box for a list of trees
  static LatLngBounds _calculateBounds(List<Map<String, dynamic>> trees) {
    double? north, south, east, west;

    for (final tree in trees) {
      final lat = _convertCoordinate(tree['latitude'] as int);
      final lng = _convertCoordinate(tree['longitude'] as int);

      north = north == null ? lat : (lat > north ? lat : north);
      south = south == null ? lat : (lat < south ? lat : south);
      east = east == null ? lng : (lng > east ? lng : east);
      west = west == null ? lng : (lng < west ? lng : west);
    }

    return LatLngBounds(
      LatLng(south!, west!),
      LatLng(north!, east!),
    );
  }

  /// Convert contract fixed-point coordinate to decimal degrees
  static double _convertCoordinate(int coordinate) {
    return (coordinate / 1000000.0) - 90.0;
  }
}
