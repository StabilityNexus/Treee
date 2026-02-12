import 'package:flutter/material.dart';

/// ============================================================================
/// MINT NFT PROVIDER - NFT CREATION STATE MANAGEMENT
/// ============================================================================
/// Manages state for minting tree NFTs with support for both IPFS and Arweave
/// storage backends. Enhanced with Arweave transaction ID tracking.
///
/// For hackathon: Demonstrates how to maintain backward compatibility while
/// adding new storage backends. The provider accepts both IPFS hashes and
/// Arweave transaction IDs, allowing gradual migration.
/// ============================================================================

class MintNftProvider extends ChangeNotifier {
  // ===== Tree NFT Metadata =====
  double _latitude = 0;
  double _longitude = 0;
  int _numberOfTrees = 0;
  String _species = "";
  String _details = "";
  String _imageUri = "";
  String _qrIpfsHash = "";
  String _geoHash = "";
  String organisationAddress = "";

  // ===== Image Storage: IPFS or Arweave =====
  // List of photo identifiers (can be IPFS hashes or Arweave TX IDs)
  List<String> _initialPhotos = [];
  
  // Arweave-specific: map photo ID to full Arweave data
  // Key: photo identifier, Value: full Arweave upload result JSON
  Map<String, Map<String, dynamic>> _arweavePhotoMetadata = {};
  
  // Track which storage provider was used for each photo
  Map<String, String> _photoStorageProvider = {}; // 'ipfs' or 'arweave'

  // Getters for existing functionality (backward compatible)
  double getLatitude() => _latitude;
  double getLongitude() => _longitude;
  int getNumberOfTrees() => _numberOfTrees;
  String getSpecies() => _species;
  String getImageUri() => _imageUri;
  String getQrIpfsHash() => _qrIpfsHash;
  String getGeoHash() => _geoHash;
  String getDetails() => _details;
  List<String> getInitialPhotos() => _initialPhotos;

  // ===== New Arweave Getters =====
  
  /// Get Arweave transaction IDs only (filters out IPFS hashes)
  List<String> getArweaveTransactionIds() => _initialPhotos
      .where((photo) => _photoStorageProvider[photo] == 'arweave')
      .toList();

  /// Get IPFS hashes only (for legacy support)
  List<String> getIpfsHashes() => _initialPhotos
      .where((photo) => _photoStorageProvider[photo] == 'ipfs')
      .toList();

  /// Get storage provider for a specific photo
  String? getPhotoStorageProvider(String photoId) =>
      _photoStorageProvider[photoId];

  /// Get full Arweave metadata for a photo
  Map<String, dynamic>? getArweavePhotoMetadata(String photoId) =>
      _arweavePhotoMetadata[photoId];

  /// Check if we have any Arweave-stored photos
  bool hasArweavePhotos() => getArweaveTransactionIds().isNotEmpty;

  // ===== Basic Setters (backward compatible) =====

  void setLatitude(double latitude) {
    _latitude = latitude;
    notifyListeners();
  }

  void setLongitude(double longitude) {
    _longitude = longitude;
    notifyListeners();
  }

  void setSpecies(String species) {
    _species = species;
    notifyListeners();
  }

  void setOrganisationAddress(String address) {
    organisationAddress = address;
    notifyListeners();
  }

  void setDescription(String details) {
    _details = details;
    notifyListeners();
  }

  void setImageUri(String imageUri) {
    _imageUri = imageUri;
    notifyListeners();
  }

  void setQrIpfsHash(String qrIpfsHash) {
    _qrIpfsHash = qrIpfsHash;
    notifyListeners();
  }

  void setGeoHash(String geoHash) {
    _geoHash = geoHash;
    notifyListeners();
  }

  void setInitialPhotos(List<String> initialPhotos) {
    _initialPhotos = initialPhotos;
    notifyListeners();
  }

  void setNumberOfTrees(int numberOfTrees) {
    _numberOfTrees = numberOfTrees;
    notifyListeners();
  }

  // ===== New Arweave Setters =====

  /// Add a photo with Arweave storage information
  /// 
  /// [photoId]: Identifier for this photo
  /// [arweaveTransactionId]: Arweave TX ID (permanent reference)
  /// [metadata]: Full Arweave upload metadata (optional)
  void addArweavePhoto(
    String photoId,
    String arweaveTransactionId, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_initialPhotos.contains(photoId)) {
      _initialPhotos.add(photoId);
    }
    _photoStorageProvider[photoId] = 'arweave';
    
    if (metadata != null) {
      _arweavePhotoMetadata[photoId] = metadata;
    }
    
    notifyListeners();
  }

  /// Add a photo with IPFS storage (legacy support)
  void addIpfsPhoto(String ipfsHash) {
    if (!_initialPhotos.contains(ipfsHash)) {
      _initialPhotos.add(ipfsHash);
    }
    _photoStorageProvider[ipfsHash] = 'ipfs';
    notifyListeners();
  }

  /// Replace a photo (e.g., upgrading from IPFS to Arweave)
  void replacePhoto(
    String oldPhotoId,
    String newPhotoId,
    String storageProvider,
  ) {
    final index = _initialPhotos.indexOf(oldPhotoId);
    if (index >= 0) {
      _initialPhotos[index] = newPhotoId;
      _photoStorageProvider[newPhotoId] = storageProvider;
      
      // Clean up old metadata
      _photoStorageProvider.remove(oldPhotoId);
      _arweavePhotoMetadata.remove(oldPhotoId);
    }
    notifyListeners();
  }

  /// Remove a specific photo
  void removePhoto(String photoId) {
    _initialPhotos.remove(photoId);
    _photoStorageProvider.remove(photoId);
    _arweavePhotoMetadata.remove(photoId);
    notifyListeners();
  }

  /// Export NFT data as JSON for blockchain submission
  /// Includes both IPFS and Arweave transaction IDs
  Map<String, dynamic> toNftMetadataJson() {
    return {
      // Tree metadata
      'latitude': _latitude,
      'longitude': _longitude,
      'numberOfTrees': _numberOfTrees,
      'species': _species,
      'details': _details,
      'geoHash': _geoHash,
      
      // Image URIs
      'imageUri': _imageUri,
      'qrIpfsHash': _qrIpfsHash,
      
      // Photos with storage provider info
      'photos': {
        'ipfs': getIpfsHashes(),
        'arweave': getArweaveTransactionIds(),
      },
      
      // Full Arweave metadata for each transaction
      'arweaveMetadata': _arweavePhotoMetadata,
      
      'organisationAddress': organisationAddress,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Clear all data
  void clearData() {
    _latitude = 0;
    _longitude = 0;
    _species = "";
    _imageUri = "";
    _qrIpfsHash = "";
    _geoHash = "";
    _initialPhotos.clear();
    _photoStorageProvider.clear();
    _arweavePhotoMetadata.clear();
    organisationAddress = "";
    _numberOfTrees = 0;
    _details = "";
    notifyListeners();
  }

  /// Clear only photo data (useful for re-uploading photos)
  void clearPhotos() {
    _initialPhotos.clear();
    _photoStorageProvider.clear();
    _arweavePhotoMetadata.clear();
    notifyListeners();
  }
}
