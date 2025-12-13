import 'package:latlong2/latlong.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/services/geohash_service.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_read_services.dart';

/// Model for tree data displayed on map
class MapTreeData {
  final int id;
  final double latitude;
  final double longitude;
  final String species;
  final String imageUri;
  final String geoHash;
  final bool isAlive;
  final int careCount;
  final int plantingDate;
  final int numberOfTrees;

  MapTreeData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.species,
    required this.imageUri,
    required this.geoHash,
    required this.isAlive,
    required this.careCount,
    required this.plantingDate,
    required this.numberOfTrees,
  });

  LatLng get position => LatLng(latitude, longitude);

  /// Safely convert dynamic value to int (handles BigInt, num, String)
  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is BigInt) return v.toInt();
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  /// Safely convert dynamic value to String
  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  factory MapTreeData.fromContractData(Map<String, dynamic> data) {
    final lat = _convertLatitude(_asInt(data['latitude']));
    final lng = _convertLongitude(_asInt(data['longitude']));
    final death = _asInt(data['death']);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Tree is alive if death is 0 (not set) or death timestamp is in the future
    final isAlive = death == 0 || death >= now;

    return MapTreeData(
      id: _asInt(data['id']),
      latitude: lat,
      longitude: lng,
      species: _asString(data['species'], fallback: 'Unknown'),
      imageUri: _asString(data['imageUri']),
      geoHash: _asString(data['geoHash']),
      isAlive: isAlive,
      careCount: _asInt(data['careCount']),
      plantingDate: _asInt(data['plantingDate'] ?? data['planting']),
      numberOfTrees: _asInt(data['numberOfTrees'], fallback: 1),
    );
  }

  /// Convert stored latitude from fixed-point to decimal degrees
  /// Contract stores as (latitude + 90) * 1000000
  static double _convertLatitude(int coordinate) {
    return (coordinate / 1000000.0) - 90.0;
  }

  /// Convert stored longitude from fixed-point to decimal degrees
  /// Contract stores as (longitude + 180) * 1000000
  static double _convertLongitude(int coordinate) {
    return (coordinate / 1000000.0) - 180.0;
  }
}

/// Cluster of trees for efficient rendering
class TreeCluster {
  final LatLng center;
  final List<MapTreeData> trees;
  final String geohash;

  TreeCluster({
    required this.center,
    required this.trees,
    required this.geohash,
  });

  int get count => trees.length;
  int get totalTreeCount => trees.fold(0, (sum, tree) => sum + tree.numberOfTrees);
  
  bool get isSingleTree => trees.length == 1;
  MapTreeData? get singleTree => isSingleTree ? trees.first : null;
}

/// Service for fetching and managing tree data for map display
class TreeMapService {
  static final TreeMapService _instance = TreeMapService._internal();
  factory TreeMapService() => _instance;
  TreeMapService._internal();

  final GeohashService _geohashService = GeohashService();

  // Cache for loaded trees by geohash
  final Map<String, List<MapTreeData>> _treeCache = {};
  // O(1) lookup for duplicate prevention per geohash
  final Map<String, Set<int>> _treeCacheIds = {};
  final Set<String> _loadingGeohashes = {};

  // All loaded trees
  List<MapTreeData> _allTrees = [];
  int _totalTreeCount = 0;
  bool _hasMore = true;

  /// Returns an unmodifiable view of all trees to prevent external mutation
  List<MapTreeData> get allTrees => List.unmodifiable(_allTrees);
  int get totalTreeCount => _totalTreeCount;

  /// Clear all cached data
  void clearCache() {
    _treeCache.clear();
    _treeCacheIds.clear();
    _loadingGeohashes.clear();
    _allTrees.clear();
    _totalTreeCount = 0;
    _hasMore = true;
  }

  /// Add tree to cache with O(1) duplicate check
  void _addTreeToCache(String geohash, MapTreeData tree) {
    _treeCache.putIfAbsent(geohash, () => []);
    _treeCacheIds.putIfAbsent(geohash, () => {});

    // O(1) duplicate check using Set
    if (_treeCacheIds[geohash]!.add(tree.id)) {
      _treeCache[geohash]!.add(tree);
    }
  }

  /// Fetch trees for visible map area using geohash-based queries
  Future<List<MapTreeData>> fetchTreesInBounds({
    required WalletProvider walletProvider,
    required LatLng southwest,
    required LatLng northeast,
    required double zoom,
  }) async {
    try {
      // Calculate optimal precision based on zoom
      final precision = _geohashService.getPrecisionForZoom(zoom);
      
      // Get geohashes covering the visible area
      final geohashes = _geohashService.getGeohashesInBounds(
        southwest,
        northeast,
        precision: precision,
      );

      logger.d('Fetching trees for ${geohashes.length} geohashes at precision $precision');

      // Filter trees from cache that match visible geohashes
      final visibleTrees = <MapTreeData>[];
      final geohashesToFetch = <String>[];

      for (final geohash in geohashes) {
        if (_treeCache.containsKey(geohash)) {
          visibleTrees.addAll(_treeCache[geohash]!);
        } else if (!_loadingGeohashes.contains(geohash)) {
          geohashesToFetch.add(geohash);
        }
      }

      // Fetch new geohashes if needed
      if (geohashesToFetch.isNotEmpty) {
        await _fetchTreesFromBlockchain(
          walletProvider: walletProvider,
          geohashes: geohashesToFetch,
        );
        
        // Add newly fetched trees
        for (final geohash in geohashesToFetch) {
          if (_treeCache.containsKey(geohash)) {
            visibleTrees.addAll(_treeCache[geohash]!);
          }
        }
      }

      // Filter to only trees within bounds
      return visibleTrees.where((tree) {
        return tree.latitude >= southwest.latitude &&
               tree.latitude <= northeast.latitude &&
               tree.longitude >= southwest.longitude &&
               tree.longitude <= northeast.longitude;
      }).toList();
    } catch (e) {
      logger.e('Error fetching trees in bounds: $e');
      return [];
    }
  }

  /// Fetch all trees with pagination (for initial load)
  Future<List<MapTreeData>> fetchAllTrees({
    required WalletProvider walletProvider,
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      final result = await ContractReadFunctions.getRecentTreesPaginated(
        walletProvider: walletProvider,
        offset: offset,
        limit: limit,
      );

      if (result.success && result.data != null) {
        final treesData = result.data['trees'] as List<dynamic>? ?? [];
        _totalTreeCount = result.data['totalCount'] ?? 0;
        _hasMore = result.data['hasMore'] ?? false;

        final newTrees = treesData
            .map((data) => MapTreeData.fromContractData(data as Map<String, dynamic>))
            .toList();

        // Add to cache by geohash with O(1) duplicate check
        for (final tree in newTrees) {
          final geohash = tree.geoHash.isNotEmpty
              ? tree.geoHash.substring(
                  0,
                  GeohashService.defaultPrecision
                      .clamp(1, tree.geoHash.length)
                      .toInt())
              : _geohashService.encode(tree.latitude, tree.longitude);

          _addTreeToCache(geohash, tree);
        }

        if (offset == 0) {
          _allTrees = newTrees;
        } else {
          _allTrees.addAll(newTrees);
        }

        logger.d('Fetched ${newTrees.length} trees, total: ${_allTrees.length}');
        return newTrees;
      }

      return [];
    } catch (e) {
      logger.e('Error fetching all trees: $e');
      return [];
    }
  }

  Future<void> _fetchTreesFromBlockchain({
    required WalletProvider walletProvider,
    required List<String> geohashes,
  }) async {
    // Mark geohashes as loading
    _loadingGeohashes.addAll(geohashes);

    try {
      // For now, we fetch all trees and filter by geohash
      // In a production app, you'd have a backend that indexes by geohash
      if (_allTrees.isEmpty) {
        await fetchAllTrees(walletProvider: walletProvider, limit: 100);
      }

      // Convert geohashes to Set for membership check
      final geohashSet = geohashes.toSet();

      // Iterate over all trees and check prefix matches - O(n * m)
      for (final tree in _allTrees) {
        // Compute encoded geohash once per tree
        final encodedGeohash =
            _geohashService.encode(tree.latitude, tree.longitude);

        // Check each requested geohash for prefix match
        for (final geohash in geohashSet) {
          if (tree.geoHash.startsWith(geohash) ||
              encodedGeohash.startsWith(geohash)) {
            // O(1) duplicate check and add
            _addTreeToCache(geohash, tree);
          }
        }
      }
    } finally {
      _loadingGeohashes.removeAll(geohashes);
    }
  }

  /// Cluster trees for efficient rendering at lower zoom levels
  List<TreeCluster> clusterTrees(List<MapTreeData> trees, double zoom) {
    if (trees.isEmpty) return [];

    // At high zoom, show individual trees
    if (zoom >= 15) {
      return trees.map((tree) => TreeCluster(
        center: tree.position,
        trees: [tree],
        geohash: tree.geoHash,
      )).toList();
    }

    // Cluster by geohash at lower zoom levels
    final precision = _geohashService.getPrecisionForZoom(zoom);
    final clusters = <String, List<MapTreeData>>{};

    for (final tree in trees) {
      final clusterHash = tree.geoHash.isNotEmpty && tree.geoHash.length >= precision
          ? tree.geoHash.substring(0, precision)
          : _geohashService.encode(tree.latitude, tree.longitude, precision: precision);
      
      clusters.putIfAbsent(clusterHash, () => []);
      clusters[clusterHash]!.add(tree);
    }

    return clusters.entries.map((entry) {
      final clusterTrees = entry.value;
      final centerLat = clusterTrees.map((t) => t.latitude).reduce((a, b) => a + b) / clusterTrees.length;
      final centerLng = clusterTrees.map((t) => t.longitude).reduce((a, b) => a + b) / clusterTrees.length;

      return TreeCluster(
        center: LatLng(centerLat, centerLng),
        trees: clusterTrees,
        geohash: entry.key,
      );
    }).toList();
  }

  /// Get trees near a specific location
  Future<List<MapTreeData>> getTreesNearLocation({
    required WalletProvider walletProvider,
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    // Ensure we have trees loaded
    if (_allTrees.isEmpty) {
      await fetchAllTrees(walletProvider: walletProvider, limit: 100);
    }

    // Use geohash to pre-filter trees for better performance
    final centerGeohash = _geohashService.encode(latitude, longitude);
    final neighborGeohashes = _geohashService.getNeighbors(centerGeohash);
    // Include center geohash to avoid dropping trees in the current cell
    final geohashSet = {centerGeohash, ...neighborGeohashes};

    // Pre-filter by geohash (reduces distance calculations)
    final candidateTrees = _allTrees.where((tree) {
      // Check if tree's geohash matches any neighbor geohash prefix
      if (tree.geoHash.isNotEmpty) {
        final treePrefix = tree.geoHash.length >= centerGeohash.length
            ? tree.geoHash.substring(0, centerGeohash.length)
            : tree.geoHash;
        return geohashSet.any((gh) => gh.startsWith(treePrefix) || treePrefix.startsWith(gh));
      }
      // Compute geohash for trees without one
      final computedHash = _geohashService.encode(tree.latitude, tree.longitude);
      return geohashSet.any((gh) => computedHash.startsWith(gh) || gh.startsWith(computedHash));
    }).toList();

    // Filter by exact distance and cache distances to avoid recalculating during sort
    final center = LatLng(latitude, longitude);
    final treesWithDistance = <(MapTreeData, double)>[];
    for (final tree in candidateTrees) {
      final distance = _geohashService.calculateDistance(center, tree.position);
      if (distance <= radiusMeters) {
        treesWithDistance.add((tree, distance));
      }
    }
    treesWithDistance.sort((a, b) => a.$2.compareTo(b.$2));
    return treesWithDistance.map((e) => e.$1).toList();
  }
}
