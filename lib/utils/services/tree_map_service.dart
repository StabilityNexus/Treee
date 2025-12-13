import 'dart:math' as math;
import 'package:dart_geohash/dart_geohash.dart';
import 'package:tree_planting_protocol/models/tree_details.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_read_services.dart';

class TreeMapService {
  static final GeoHasher _geoHasher = GeoHasher();
  
  /// Fetch trees within a bounding box by filtering from recent trees
  /// This is the client-side approach - filters fetched trees by location
  static Future<List<Tree>> getTreesInBoundingBox({
    required WalletProvider walletProvider,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int maxTrees = 100,
  }) async {
    try {
      logger.d("Fetching trees in bounding box: "
          "lat[$minLat, $maxLat], lng[$minLng, $maxLng]");
      
      // Fetch a large batch of recent trees
      // In future, this could be optimized with backend or contract-level filtering
      final result = await ContractReadFunctions.getRecentTreesPaginated(
        walletProvider: walletProvider,
        offset: 0,
        limit: 50, // Fetch more trees to filter from
      );
      
      if (!result.success || result.data == null) {
        logger.e("Failed to fetch trees: ${result.errorMessage}");
        return [];
      }
      
      final List<dynamic> treesData = result.data['trees'] ?? [];
      final List<Tree> allTrees = [];
      
      // Parse trees from contract data
      for (var treeData in treesData) {
        try {
          final tree = _parseTreeFromMap(treeData);
          allTrees.add(tree);
        } catch (e) {
          logger.e("Error parsing tree: $e");
          continue;
        }
      }
      
      // Filter trees within bounding box
      final List<Tree> treesInBounds = allTrees.where((tree) {
        final lat = _convertLatitude(tree.latitude);
        final lng = _convertLongitude(tree.longitude);
        
        return lat >= minLat && 
               lat <= maxLat && 
               lng >= minLng && 
               lng <= maxLng;
      }).take(maxTrees).toList();
      
      logger.d("Found ${treesInBounds.length} trees in bounding box");
      return treesInBounds;
      
    } catch (e) {
      logger.e("Error fetching trees in bounding box: $e");
      return [];
    }
  }
  
  /// Fetch trees near a specific location using geohash
  /// Returns trees within the same geohash and neighboring geohashes
  static Future<List<Tree>> getTreesNearLocation({
    required WalletProvider walletProvider,
    required double latitude,
    required double longitude,
    int precision = 6, // ~1.2km x 0.6km
    int maxTrees = 100,
  }) async {
    try {
      final centerGeohash = _geoHasher.encode(longitude, latitude, precision: precision);
      logger.d("Searching for trees near geohash: $centerGeohash");
      
      // Get neighboring geohashes to cover boundary cases
      final neighborsMap = _geoHasher.neighbors(centerGeohash);
      final neighbors = neighborsMap.values.toList();
      final geohashesToCheck = [centerGeohash, ...neighbors];
      
      logger.d("Checking ${geohashesToCheck.length} geohash regions");
      
      // Fetch trees and filter by geohash prefix
      final result = await ContractReadFunctions.getRecentTreesPaginated(
        walletProvider: walletProvider,
        offset: 0,
        limit: 50,
      );
      
      if (!result.success || result.data == null) {
        logger.e("Failed to fetch trees: ${result.errorMessage}");
        return [];
      }
      
      final List<dynamic> treesData = result.data['trees'] ?? [];
      final List<Tree> matchingTrees = [];
      
      for (var treeData in treesData) {
        try {
          final tree = _parseTreeFromMap(treeData);
          
          // Check if tree's geohash matches any of our target geohashes
          if (_isGeohashInList(tree.geoHash, geohashesToCheck, precision)) {
            matchingTrees.add(tree);
          }
          
          if (matchingTrees.length >= maxTrees) break;
        } catch (e) {
          logger.e("Error parsing tree: $e");
          continue;
        }
      }
      
      logger.d("Found ${matchingTrees.length} trees near location");
      return matchingTrees;
      
    } catch (e) {
      logger.e("Error fetching trees near location: $e");
      return [];
    }
  }
  
  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Get geohash for a coordinate
  static String getGeohash(double latitude, double longitude, {int precision = 6}) {
    return _geoHasher.encode(longitude, latitude, precision: precision);
  }
  
  /// Get neighboring geohashes
  static List<String> getNeighboringGeohashes(String geohash) {
    return _geoHasher.neighbors(geohash).values.toList();
  }
  
  /// Decode geohash to coordinates
  static Map<String, double> decodeGeohash(String geohash) {
    final decoded = _geoHasher.decode(geohash);
    return {
      'latitude': decoded[0],
      'longitude': decoded[1],
    };
  }
  
  // Private helper methods
  
  static Tree _parseTreeFromMap(Map<String, dynamic> treeData) {
    return Tree(
      id: treeData['id'] as int,
      latitude: treeData['latitude'] as int,
      longitude: treeData['longitude'] as int,
      planting: treeData['planting'] as int,
      death: treeData['death'] as int,
      species: treeData['species'] as String,
      imageUri: treeData['imageUri'] as String,
      qrIpfsHash: treeData['qrPhoto'] as String,
      metadata: treeData['metadata'] as String,
      photos: List<String>.from(treeData['photos'] ?? []),
      geoHash: treeData['geoHash'] as String,
      ancestors: (treeData['ancestors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      lastCareTimestamp: treeData['lastCareTimestamp'] as int,
      careCount: treeData['careCount'] as int,
      verifiers: [], // Not included in map data
      owner: '', // Not included in map data
    );
  }
  
  static double _convertLatitude(int coordinate) {
    // Convert from fixed-point representation to decimal degrees
    // Encoding: (latitude + 90.0) * 1e6
    return (coordinate / 1000000.0) - 90.0;
  }
  
  static double _convertLongitude(int coordinate) {
    // Convert from fixed-point representation to decimal degrees
    // Encoding: (longitude + 180.0) * 1e6
    return (coordinate / 1000000.0) - 180.0;
  }
  
  static bool _isGeohashInList(String treeGeohash, List<String> targetGeohashes, int precision) {
    if (treeGeohash.isEmpty) return false;
    
    // Compare geohash prefix up to the specified precision
    final treePrefix = treeGeohash.length >= precision 
        ? treeGeohash.substring(0, precision) 
        : treeGeohash;
    
    for (var targetHash in targetGeohashes) {
      final targetPrefix = targetHash.length >= precision 
          ? targetHash.substring(0, precision) 
          : targetHash;
      
      if (treePrefix == targetPrefix) {
        return true;
      }
    }
    
    return false;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
