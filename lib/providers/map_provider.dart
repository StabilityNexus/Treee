import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:tree_planting_protocol/models/tree_details.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

class MapProvider extends ChangeNotifier {
  // Map state
  LatLng _currentCenter = LatLng(28.7041, 77.1025); // Default to Delhi, India
  double _currentZoom = 13.0;
  LatLng? _userLocation;
  
  // Tree data
  List<Tree> _loadedTrees = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Map bounds for tracking viewport changes
  LatLng? _lastFetchCenter;
  double? _lastFetchZoom;
  
  // Configuration
  static const double _significantMoveThreshold = 0.01; // ~1km
  static const double _significantZoomThreshold = 1.0;
  
  // Getters
  LatLng get currentCenter => _currentCenter;
  double get currentZoom => _currentZoom;
  LatLng? get userLocation => _userLocation;
  List<Tree> get loadedTrees => _loadedTrees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUserLocation => _userLocation != null;
  
  // Setters
  void setCurrentCenter(LatLng center) {
    _currentCenter = center;
    notifyListeners();
  }
  
  void setCurrentZoom(double zoom) {
    _currentZoom = zoom;
    notifyListeners();
  }
  
  void setUserLocation(LatLng location) {
    _userLocation = location;
    _currentCenter = location; // Center map on user location
    notifyListeners();
  }
  
  void setLoadedTrees(List<Tree> trees) {
    _loadedTrees = trees;
    _lastFetchCenter = _currentCenter;
    _lastFetchZoom = _currentZoom;
    notifyListeners();
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Check if map has moved significantly since last fetch
  bool shouldRefetchTrees() {
    if (_lastFetchCenter == null || _lastFetchZoom == null) {
      return true;
    }
    
    final distance = _calculateDistance(
      _lastFetchCenter!.latitude,
      _lastFetchCenter!.longitude,
      _currentCenter.latitude,
      _currentCenter.longitude,
    );
    
    final zoomDiff = (_currentZoom - _lastFetchZoom!).abs();
    
    return distance > _significantMoveThreshold || 
           zoomDiff > _significantZoomThreshold;
  }
  
  // Calculate distance between two points (simple Euclidean for threshold check)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final latDiff = lat1 - lat2;
    final lonDiff = lon1 - lon2;
    return (latDiff * latDiff + lonDiff * lonDiff);
  }
  
  // Get bounding box for current map viewport
  Map<String, double> getBoundingBox() {
    // Approximate: 1 degree latitude ≈ 111km
    // Longitude varies by latitude, but for simplicity we use a rough estimate
    final latDelta = 0.05 / _currentZoom; // Adjust based on zoom
    final lngDelta = 0.05 / _currentZoom;
    
    return {
      'minLat': _currentCenter.latitude - latDelta,
      'maxLat': _currentCenter.latitude + latDelta,
      'minLng': _currentCenter.longitude - lngDelta,
      'maxLng': _currentCenter.longitude + lngDelta,
    };
  }
  
  // Add a single tree to the loaded trees
  void addTree(Tree tree) {
    _loadedTrees.add(tree);
    notifyListeners();
  }
  
  // Remove a tree from loaded trees
  void removeTree(int treeId) {
    _loadedTrees.removeWhere((tree) => tree.id == treeId);
    notifyListeners();
  }
  
  // Update a tree in the loaded trees
  void updateTree(Tree updatedTree) {
    final index = _loadedTrees.indexWhere((tree) => tree.id == updatedTree.id);
    if (index != -1) {
      _loadedTrees[index] = updatedTree;
      notifyListeners();
    }
  }
  
  // Clear all loaded trees
  void clearTrees() {
    _loadedTrees.clear();
    _lastFetchCenter = null;
    _lastFetchZoom = null;
    notifyListeners();
  }
  
  // Reset map to user location
  void centerOnUser() {
    if (_userLocation != null) {
      _currentCenter = _userLocation!;
      notifyListeners();
      logger.d("Map centered on user location: $_userLocation");
    }
  }
  
  // Reset provider state
  void reset() {
    _currentCenter = LatLng(28.7041, 77.1025);
    _currentZoom = 13.0;
    _userLocation = null;
    _loadedTrees.clear();
    _isLoading = false;
    _errorMessage = null;
    _lastFetchCenter = null;
    _lastFetchZoom = null;
    notifyListeners();
  }
}
