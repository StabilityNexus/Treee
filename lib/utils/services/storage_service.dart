import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

/// Storage service that supports multiple providers for decentralized file storage.
/// Currently supports: Web3.Storage (free IPFS pinning via Filecoin)
/// 
/// Web3.Storage provides:
/// - 5GB free storage
/// - IPFS-compatible content addressing (same hash format)
/// - No cost restrictions for reasonable usage
/// - Backed by Filecoin for persistence

class StorageService {
  // Web3.Storage API token (get free at https://web3.storage)
  static String get _web3StorageToken =>
      dotenv.get('WEB3_STORAGE_TOKEN', fallback: "");

  // Legacy Pinata keys (kept for backward compatibility)
  static String get _pinataApiKey =>
      dotenv.get('PINATA_API_KEY', fallback: "");
  static String get _pinataApiSecret =>
      dotenv.get('PINATA_API_SECRET', fallback: "");

  /// Upload a file to decentralized storage and return the gateway URL.
  /// 
  /// Tries Web3.Storage first (free), falls back to Pinata if configured.
  /// Returns the full gateway URL with the IPFS hash.
  static Future<String?> uploadFile(
    File file,
    Function(bool) setUploadingState,
  ) async {
    setUploadingState(true);

    try {
      // Try Web3.Storage first (free option)
      if (_web3StorageToken.isNotEmpty) {
        final result = await _uploadToWeb3Storage(file);
        if (result != null) {
          setUploadingState(false);
          return result;
        }
      }

      // Fall back to Pinata if Web3.Storage fails or isn't configured
      if (_pinataApiKey.isNotEmpty && _pinataApiSecret.isNotEmpty) {
        final result = await _uploadToPinata(file);
        if (result != null) {
          setUploadingState(false);
          return result;
        }
      }

      logger.e('No storage provider configured. Please set WEB3_STORAGE_TOKEN or PINATA_API_KEY in .env');
      setUploadingState(false);
      return null;
    } catch (e) {
      logger.e('Error uploading file: $e');
      setUploadingState(false);
      return null;
    }
  }

  /// Upload to Web3.Storage (free IPFS pinning)
  /// Get your free token at: https://web3.storage
  static Future<String?> _uploadToWeb3Storage(File file) async {
    try {
      final url = Uri.parse('https://api.web3.storage/upload');
      
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $_web3StorageToken',
      });

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final cid = jsonResponse['cid'];
        logger.d('Web3.Storage upload successful. CID: $cid');
        // Use w3s.link gateway (Web3.Storage's fast gateway)
        return 'https://w3s.link/ipfs/$cid';
      } else {
        logger.e('Web3.Storage upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Web3.Storage upload error: $e');
      return null;
    }
  }

  /// Upload to Pinata (legacy, paid after free tier)
  static Future<String?> _uploadToPinata(File file) async {
    try {
      final url = Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS');
      
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'pinata_api_key': _pinataApiKey,
        'pinata_secret_api_key': _pinataApiSecret,
      });

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final ipfsHash = jsonResponse['IpfsHash'];
        logger.d('Pinata upload successful. Hash: $ipfsHash');
        return 'https://gateway.pinata.cloud/ipfs/$ipfsHash';
      } else {
        logger.e('Pinata upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Pinata upload error: $e');
      return null;
    }
  }

  /// Extract the IPFS CID/hash from a gateway URL
  /// Works with any IPFS gateway URL format
  static String? extractCidFromUrl(String url) {
    // Match patterns like:
    // https://w3s.link/ipfs/bafybeig...
    // https://gateway.pinata.cloud/ipfs/Qm...
    // https://ipfs.io/ipfs/Qm...
    final regex = RegExp(r'/ipfs/([a-zA-Z0-9]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Get alternative gateway URLs for a given IPFS URL
  /// Useful for fallback if one gateway is slow/down
  static List<String> getAlternativeGateways(String originalUrl) {
    final cid = extractCidFromUrl(originalUrl);
    if (cid == null) return [originalUrl];

    return [
      'https://w3s.link/ipfs/$cid',           // Web3.Storage gateway (fast)
      'https://ipfs.io/ipfs/$cid',            // Protocol Labs gateway
      'https://cloudflare-ipfs.com/ipfs/$cid', // Cloudflare gateway
      'https://dweb.link/ipfs/$cid',          // dweb.link gateway
    ];
  }
}

// Legacy function for backward compatibility
// This wraps the new StorageService
Future<String?> uploadToIPFS(
  File imageFile,
  Function(bool) setUploadingState,
) async {
  return StorageService.uploadFile(imageFile, setUploadingState);
}
