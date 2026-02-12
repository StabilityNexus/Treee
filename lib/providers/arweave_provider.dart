import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/arweave_services.dart';

/// ============================================================================
/// ARWEAVE PROVIDER - STATE MANAGEMENT
/// ============================================================================
/// Manages Arweave upload state and caches transaction IDs throughout the app.
/// This provider integrates with the existing Provider pattern for clean
/// separation of concerns.
///
/// For hackathon: This demonstrates clean architecture by:
/// 1. Separating storage logic (service) from state management (provider)
/// 2. Caching Arweave TX IDs for efficient blockchain interactions
/// 3. Providing loading/error states to UI without exposing implementation
/// ============================================================================

class ArweaveProvider extends ChangeNotifier {
  // ===== Upload State =====
  bool _isUploading = false;
  int _uploadProgress = 0; // 0-100
  String? _uploadError;

  // ===== Cached Transaction Data =====
  /// Maps local file paths or identifiers to Arweave transaction IDs
  /// Used to avoid re-uploading same files
  final Map<String, ArweaveUploadResult> _uploadedFiles = {};

  // ===== Batch Upload State =====
  int _currentBatchIndex = 0;
  int _totalBatchCount = 0;
  List<ArweaveUploadResult?> _batchResults = [];

  // Getters for UI consumption
  bool get isUploading => _isUploading;
  int get uploadProgress => _uploadProgress;
  String? get uploadError => _uploadError;
  int get currentBatchIndex => _currentBatchIndex;
  int get totalBatchCount => _totalBatchCount;
  List<ArweaveUploadResult?> get batchResults => _batchResults;

  /// Get all cached transaction IDs
  /// Useful for sending to blockchain or displaying in UI
  List<String> get cachedTransactionIds =>
      _uploadedFiles.values.map((r) => r.transactionId).toList();

  /// Get a cached Arweave URL by transaction ID
  String? getCachedFileUrl(String transactionId) {
    try {
      return _uploadedFiles.values
          .firstWhere((r) => r.transactionId == transactionId)
          .fileUrl;
    } catch (e) {
      return null;
    }
  }

  /// Check if a file has already been uploaded to Arweave
  bool hasBeenUploaded(String identifier) => _uploadedFiles.containsKey(identifier);

  /// Get cached upload result by identifier
  ArweaveUploadResult? getUploadResult(String identifier) =>
      _uploadedFiles[identifier];

  // ===== Upload Methods =====

  /// Upload a single file to Arweave
  /// 
  /// [identifier]: Unique key to cache this upload (e.g., file path)
  /// [file]: The file object to upload
  /// [metadata]: Optional metadata to attach to the Arweave transaction
  /// 
  /// Returns the ArweaveUploadResult containing the transaction ID
  Future<ArweaveUploadResult?> uploadFileToArweave(
    String identifier,
    dynamic file, {
    Map<String, String>? metadata,
  }) async {
    // Check cache first to avoid redundant uploads
    if (_uploadedFiles.containsKey(identifier)) {
      logger.d('📦 File already uploaded (cached): $identifier');
      return _uploadedFiles[identifier];
    }

    _isUploading = true;
    _uploadError = null;
    _uploadProgress = 0;
    notifyListeners();

    try {
      logger.d('🚀 Starting Arweave upload for: $identifier');

      // Call the Arweave service
      final result = await uploadToArweave(
        file,
        (isUploading) {
          if (isUploading) {
            _uploadProgress = 50; // Upload in progress
          } else {
            _uploadProgress = 100; // Upload complete
          }
          notifyListeners();
        },
        metadata: metadata,
      );

      if (result != null) {
        // Cache the successful upload
        _uploadedFiles[identifier] = result;
        logger.d('✅ Upload successful. TX ID: ${result.transactionId}');
        _uploadProgress = 100;
      } else {
        _uploadError = 'Failed to upload file to Arweave';
        logger.e('❌ Upload failed: $_uploadError');
      }

      notifyListeners();
      return result;
    } catch (e) {
      _uploadError = 'Exception: $e';
      logger.e('🚨 Upload exception: $e');
      notifyListeners();
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Upload multiple files to Arweave as a batch
  /// 
  /// Maintains progress state for batch operations (e.g., NFT collections)
  /// Returns list of results, with null for failed uploads
  Future<List<ArweaveUploadResult?>> uploadBatchToArweave(
    List<dynamic> files, {
    List<String>? identifiers,
  }) async {
    _isUploading = true;
    _uploadError = null;
    _totalBatchCount = files.length;
    _batchResults = [];
    _currentBatchIndex = 0;
    notifyListeners();

    try {
      logger.d('📁 Starting batch upload: ${files.length} files');

      // Call the batch upload service
      _batchResults = await uploadMultipleToArweave(
        files,
        (current, total) {
          _currentBatchIndex = current;
          _totalBatchCount = total;
          _uploadProgress = ((current / total) * 100).toInt();
          notifyListeners();
        },
      );

      // Cache successful results
      if (identifiers != null && identifiers.length == files.length) {
        for (int i = 0; i < _batchResults.length; i++) {
          if (_batchResults[i] != null) {
            _uploadedFiles[identifiers[i]] = _batchResults[i]!;
          }
        }
      }

      final successCount =
          _batchResults.where((r) => r != null).length;
      logger.d('✅ Batch upload complete: $successCount/${files.length} succeeded');

      notifyListeners();
      return _batchResults;
    } catch (e) {
      _uploadError = 'Batch upload exception: $e';
      logger.e('🚨 Batch upload failed: $e');
      notifyListeners();
      return [];
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Verify that a transaction ID is valid and accessible on Arweave
  /// Useful to call before storing TX ID on-chain
  Future<bool> verifyTransaction(String transactionId) async {
    try {
      logger.d('🔍 Verifying transaction: $transactionId');
      return await verifyArweaveTransaction(transactionId);
    } catch (e) {
      logger.e('❌ Verification failed: $e');
      return false;
    }
  }

  // ===== Cache Management =====

  /// Clear all cached uploads
  void clearCache() {
    _uploadedFiles.clear();
    _batchResults.clear();
    _uploadError = null;
    logger.d('🗑️ Upload cache cleared');
    notifyListeners();
  }

  /// Remove a specific cached upload
  void removeCachedUpload(String identifier) {
    _uploadedFiles.remove(identifier);
    notifyListeners();
  }

  /// Export all cached transaction IDs as JSON
  /// Useful for saving to SharedPreferences or database
  Map<String, dynamic> exportCacheAsJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'uploads': {
        for (var entry in _uploadedFiles.entries)
          entry.key: entry.value.toJson()
      },
    };
  }

  /// Import cached transaction IDs from JSON
  /// Useful for loading from SharedPreferences or database on app startup
  void importCacheFromJson(Map<String, dynamic> json) {
    try {
      if (json.containsKey('uploads')) {
        final uploads = json['uploads'] as Map<String, dynamic>;
        uploads.forEach((key, value) {
          _uploadedFiles[key] = ArweaveUploadResult.fromJson(
            value as Map<String, dynamic>,
          );
        });
        logger.d('✅ Imported ${_uploadedFiles.length} cached uploads');
      }
      notifyListeners();
    } catch (e) {
      logger.e('❌ Failed to import cache: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _uploadError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _uploadedFiles.clear();
    super.dispose();
  }
}

/// ============================================================================
/// USAGE EXAMPLES FOR HACKATHON
/// ============================================================================
/// 
/// Single file upload:
/// ```dart
/// final provider = Provider.of<ArweaveProvider>(context, listen: false);
/// final result = await provider.uploadFileToArweave(
///   'user_avatar_${userId}',
///   selectedFile,
///   metadata: {'owner': userId, 'type': 'avatar'},
/// );
/// if (result != null) {
///   // Send result.transactionId to blockchain contract
///   await contract.updateUserProfile(userId, result.transactionId);
/// }
/// ```
/// 
/// Batch upload (NFT collection):
/// ```dart
/// final results = await provider.uploadBatchToArweave(
///   imageFiles,
///   identifiers: ['nft_1', 'nft_2', 'nft_3'],
/// );
/// // Collect transaction IDs for blockchain
/// final txIds = results.whereType<ArweaveUploadResult>().map((r) => r.transactionId);
/// ```
/// 
/// Verify before storing on-chain:
/// ```dart
/// final isValid = await provider.verifyTransaction(txId);
/// if (isValid) {
///   // Safe to store on blockchain
///   await contract.mintNFT(txId, metadata);
/// }
/// ```
