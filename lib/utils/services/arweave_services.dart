import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

/// ============================================================================
/// ARWEAVE PERMANENT STORAGE SERVICE
/// ============================================================================
/// This service handles uploading files to Arweave - a permanent, decentralized
/// storage solution. Unlike IPFS, Arweave guarantees data persistence for 200+ years
/// through economic incentives. Transaction IDs (Arweave TX IDs) serve as immutable
/// references that can be stored on-chain.
///
/// For hackathon: Demonstrates Web3 data persistence patterns where off-chain
/// media (images) is permanently stored and referenced by transaction IDs from
/// blockchain contracts.
/// ============================================================================

String _arweaveGateway = dotenv.get('ARWEAVE_GATEWAY', fallback: 'https://arweave.net');
String _arweaveApiKey = dotenv.get('ARWEAVE_API_KEY', fallback: '');

/// Result model for Arweave uploads containing transaction ID and metadata
class ArweaveUploadResult {
  /// Transaction ID - this is what gets stored on-chain as permanent reference
  final String transactionId;
  /// Gateway URL to access the uploaded file
  final String fileUrl;
  /// File size in bytes
  final int fileSize;
  /// Timestamp of successful upload
  final DateTime uploadedAt;

  ArweaveUploadResult({
    required this.transactionId,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
  });

  /// Convert to JSON for blockchain storage or database persistence
  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  factory ArweaveUploadResult.fromJson(Map<String, dynamic> json) =>
      ArweaveUploadResult(
        transactionId: json['transactionId'] as String,
        fileUrl: json['fileUrl'] as String,
        fileSize: json['fileSize'] as int,
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      );
}

/// Primary function to upload files to Arweave
/// 
/// Parameters:
///   - imageFile: The file to upload (typically image for NFT)
///   - setUploadingState: Callback to update UI during upload (e.g., progress indicator)
///   - metadata: Optional metadata about the file (e.g., name, description)
///
/// Returns: ArweaveUploadResult containing transaction ID on success, null on failure
///
/// Hackathon flow:
/// 1. User selects image from gallery/camera
/// 2. Image uploaded to Arweave
/// 3. Arweave TX ID returned and stored in contract metadata
/// 4. TX ID serves as permanent reference to the image
/// 5. Future contract calls retrieve images using TX ID + Arweave gateway
Future<ArweaveUploadResult?> uploadToArweave(
  File imageFile,
  Function(bool) setUploadingState, {
  Map<String, String>? metadata,
}) async {
  setUploadingState(true);
  logger.d('🔗 Starting Arweave upload for: ${imageFile.path}');

  try {
    // For production: use Bundlr (https://bundlr.network) for optimized uploads
    // For hackathon: direct upload to Arweave gateway
    
    final fileBytes = await imageFile.readAsBytes();
    final fileName = imageFile.path.split('/').last;
    
    logger.d('📦 File size: ${fileBytes.length} bytes');

    // Prepare multipart request
    var url = Uri.parse('$_arweaveGateway/tx');
    var request = http.MultipartRequest('POST', url);

    // Add file
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    // Add metadata tags (stored with transaction for indexing)
    if (metadata != null) {
      metadata.forEach((key, value) {
        request.fields['tag:$key'] = value;
      });
    }

    // Add API key if configured
    if (_arweaveApiKey.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_arweaveApiKey';
    }

    var response = await request.send().timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            logger.e('⏱️ Arweave upload timeout after 5 minutes');
            throw Exception('Upload timeout');
          },
        );

    setUploadingState(false);

    if (response.statusCode == 200 || response.statusCode == 202) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      
      // Extract transaction ID from response
      final txId = jsonResponse['id'] ?? jsonResponse['tx'];
      
      if (txId == null || txId.isEmpty) {
        logger.e('❌ Invalid response: no transaction ID');
        return null;
      }

      logger.d('✅ Arweave upload successful!');
      logger.d('🔑 Transaction ID: $txId');

      // Construct permanent Arweave URL
      final fileUrl = '$_arweaveGateway/$txId';

      return ArweaveUploadResult(
        transactionId: txId,
        fileUrl: fileUrl,
        fileSize: fileBytes.length,
        uploadedAt: DateTime.now(),
      );
    } else {
      logger.e('❌ Arweave upload failed: ${response.statusCode}');
      logger.e('Response: ${await response.stream.bytesToString()}');
      return null;
    }
  } catch (e) {
    setUploadingState(false);
    logger.e('🚨 Exception during Arweave upload: $e');
    return null;
  }
}

/// Batch upload multiple files to Arweave
/// Useful for NFT collections with multiple images per NFT
///
/// Returns: List of ArweaveUploadResult, null items indicate failed uploads
Future<List<ArweaveUploadResult?>> uploadMultipleToArweave(
  List<File> imageFiles,
  Function(int, int) onProgress, // current, total
) async {
  logger.d('📁 Starting batch upload of ${imageFiles.length} files to Arweave');
  List<ArweaveUploadResult?> results = [];

  for (int i = 0; i < imageFiles.length; i++) {
    onProgress(i + 1, imageFiles.length);
    
    final result = await uploadToArweave(
      imageFiles[i],
      (_) {}, // Progress updates handled by parent
      metadata: {
        'index': '${i + 1}',
        'total': '${imageFiles.length}',
        'app': 'TreePlantingProtocol',
      },
    );
    
    results.add(result);
    
    if (result != null) {
      logger.d('✅ File ${i + 1}/${imageFiles.length} uploaded: ${result.transactionId}');
    } else {
      logger.e('❌ File ${i + 1}/${imageFiles.length} failed to upload');
    }
  }

  return results;
}

/// Verify that an Arweave transaction ID is valid and accessible
/// Can be called before storing TX ID on-chain to ensure data is available
Future<bool> verifyArweaveTransaction(String transactionId) async {
  try {
    logger.d('🔍 Verifying Arweave transaction: $transactionId');
    
    final response = await http.get(
      Uri.parse('$_arweaveGateway/tx/$transactionId/status'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      logger.d('✅ Transaction verified: $jsonResponse');
      return true;
    }
    
    logger.e('❌ Verification failed: ${response.statusCode}');
    return false;
  } catch (e) {
    logger.e('🚨 Exception during verification: $e');
    return false;
  }
}

/// Retrieve file from Arweave using transaction ID
/// Returns file content as bytes, useful for decoding metadata or direct access
Future<List<int>?> getArweaveFile(String transactionId) async {
  try {
    logger.d('📥 Fetching Arweave file: $transactionId');
    
    final response = await http.get(
      Uri.parse('$_arweaveGateway/$transactionId'),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      logger.d('✅ File retrieved successfully');
      return response.bodyBytes;
    }

    logger.e('❌ Failed to fetch file: ${response.statusCode}');
    return null;
  } catch (e) {
    logger.e('🚨 Exception fetching file: $e');
    return null;
  }
}

/// Helper: Create permanent Arweave URL from transaction ID
/// Format: https://arweave.net/{transactionId}
String getArweaveUrl(String transactionId) => '$_arweaveGateway/$transactionId';

/// Helper: Extract transaction ID from full Arweave URL
String? extractTransactionId(String arweaveUrl) {
  try {
    final uri = Uri.parse(arweaveUrl);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
  } catch (e) {
    logger.e('Error parsing Arweave URL: $e');
  }
  return null;
}
