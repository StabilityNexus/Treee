import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

/// ============================================================================
/// ARWEAVE WALLET SERVICE - HACKATHON EDITION (SIMPLE & FAST)
/// ============================================================================
/// 
/// 📋 PROJECT INFORMATION:
/// - Project: Tree Planting Protocol - NFT Hackathon
/// - Date: December 13, 2025
/// - Purpose: Decentralized Arweave wallet for Tree NFT minting
/// 
/// 🎯 FEATURES:
/// ✅ Create new Arweave wallets programmatically
/// ✅ Save/load wallets from local device storage
/// ✅ Generate Arweave-compatible addresses (43 characters)
/// ✅ JSON serialization for blockchain contracts
/// ✅ Support multiple wallets
/// 
/// 🏗️ ARCHITECTURE:
/// - Service Layer: Handles wallet operations
/// - Pure Dart: No external crypto dependencies (for hackathon speed)
/// - Local Storage: SharedPreferences (secure enough for demo)
/// - Blockchain Ready: JSON export for smart contracts
/// 
/// 📱 INTEGRATION POINTS:
/// - register_user_page.dart: User wallet creation on signup
/// - mint_nft_provider.dart: NFT minting with wallet
/// - arweave_provider.dart: Upload coordination with wallet
/// - tree_details_page.dart: Tree ownership tracking
/// 
/// 🔐 SECURITY NOTES:
/// - Hackathon Version: Local storage with basic security
/// - Production Version: Would include:
///   * AES-256 encryption
///   * Biometric authentication
///   * Hardware security module (HSM)
///   * Never transmit private keys
/// 
/// 💡 TECHNICAL DECISIONS:
/// - Why Simple? Hackathon time constraint - 24-48 hours
/// - Why Not External Libs? Faster implementation, fewer dependencies
/// - Why Local Storage? Works offline, no server needed
/// - Why Random Keys? Demo purposes, real Arweave would use cryptography
/// 
/// 🚀 SCALABILITY:
/// Current: Single device, single wallet
/// Future: Multi-device sync, wallet recovery, cold storage
///
/// ============================================================================
/// Wallet create, load, save - sab kuch 1 minute mein!
/// Website ka koi zarurat nahi!
/// ============================================================================

class SimpleArweaveWallet {
  final String address;
  final String publicKey;
  final String privateKey;
  final DateTime createdAt;
  final String displayName;

  SimpleArweaveWallet({
    required this.address,
    required this.publicKey,
    required this.privateKey,
    required this.createdAt,
    required this.displayName,
  });

  // JSON format (blockchain ke liye)
  Map<String, dynamic> toJson() => {
        'address': address,
        'publicKey': publicKey,
        'privateKey': privateKey,
        'createdAt': createdAt.toIso8601String(),
        'displayName': displayName,
      };

  factory SimpleArweaveWallet.fromJson(Map<String, dynamic> json) =>
      SimpleArweaveWallet(
        address: json['address'] as String,
        publicKey: json['publicKey'] as String,
        privateKey: json['privateKey'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        displayName: json['displayName'] as String? ?? 'My Wallet',
      );

  @override
  String toString() => 'Wallet($displayName) - $address';
}

class ArweaveWalletServiceSimple {
  static const String _storageKey = 'arweave_wallet_hackathon';
  static const String _allWalletsKey = 'arweave_all_wallets';

  /// 🔐 NAYA WALLET GENERATE KARNA (1 SECOND!)
  static Future<SimpleArweaveWallet> createNewWallet(
      {String displayName = 'My Arweave Wallet'}) async {
    logger.d('🔐 Creating new wallet...');

    // Random address generate (Arweave jaisa 43 character)
    final address = _generateRandomAddress();

    // Random keys generate
    final publicKey = _generateRandomKey(130);
    final privateKey = _generateRandomKey(256);

    final wallet = SimpleArweaveWallet(
      address: address,
      publicKey: publicKey,
      privateKey: privateKey,
      createdAt: DateTime.now(),
      displayName: displayName,
    );

    logger.d('✅ Wallet created!');
    logger.d('🔑 Address: ${wallet.address}');
    logger.d('💾 Save kar le - button click par save ho jayega!');

    return wallet;
  }

  /// 💾 WALLET SAVE KARNA (LOCAL STORAGE)
  static Future<bool> saveWallet(SimpleArweaveWallet wallet) async {
    try {
      logger.d('💾 Saving wallet: ${wallet.displayName}');

      final prefs = await SharedPreferences.getInstance();
      final walletJson = jsonEncode(wallet.toJson());

      // Current wallet
      await prefs.setString(_storageKey, walletJson);

      // All wallets history (testing ke liye)
      final allWalletsJson = prefs.getString(_allWalletsKey) ?? '[]';
      final allWallets = jsonDecode(allWalletsJson) as List;
      allWallets.add(wallet.toJson());
      await prefs.setString(_allWalletsKey, jsonEncode(allWallets));

      logger.d('✅ Wallet saved successfully!');
      return true;
    } catch (e) {
      logger.e('❌ Error saving wallet: $e');
      return false;
    }
  }

  /// 📂 WALLET LOAD KARNA (SAVE HONE SE PEHLE WALA)
  static Future<SimpleArweaveWallet?> loadWallet() async {
    try {
      logger.d('📂 Loading saved wallet...');

      final prefs = await SharedPreferences.getInstance();
      final walletJson = prefs.getString(_storageKey);

      if (walletJson == null) {
        logger.w('⚠️ No wallet found! Create new wallet first.');
        return null;
      }

      final wallet =
          SimpleArweaveWallet.fromJson(jsonDecode(walletJson));

      logger.d('✅ Wallet loaded: ${wallet.displayName}');
      logger.d('📍 Address: ${wallet.address}');

      return wallet;
    } catch (e) {
      logger.e('❌ Error loading wallet: $e');
      return null;
    }
  }

  /// 📋 SARE WALLETS KA HISTORY DEKHO (TESTING KE LIYE)
  static Future<List<SimpleArweaveWallet>> getAllWallets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allWalletsJson = prefs.getString(_allWalletsKey) ?? '[]';
      final allWalletsData =
          jsonDecode(allWalletsJson) as List;

      return allWalletsData
          .map((w) => SimpleArweaveWallet.fromJson(w as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('❌ Error loading wallets: $e');
      return [];
    }
  }

  /// 🗑️ WALLET DELETE KARNA
  static Future<bool> deleteWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      logger.d('✅ Wallet deleted');
      return true;
    } catch (e) {
      logger.e('❌ Error deleting wallet: $e');
      return false;
    }
  }

  /// 📍 WALLET ADDRESS GET KARNA
  static Future<String?> getWalletAddress() async {
    final wallet = await loadWallet();
    return wallet?.address;
  }

  /// 💰 MOCK BALANCE (TESTING KE LIYE)
  /// Real balance ke liye API call karna padega
  static Future<String> getMockBalance() async {
    // Hackathon mein demo balance dena
    final random = Random();
    final mockBalance = random.nextDouble() * 10;
    return '${mockBalance.toStringAsFixed(2)} AR';
  }

  // ============= HELPER FUNCTIONS =============

  /// Random Arweave-style address generate karna (43 chars)
  static String _generateRandomAddress() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final random = Random();
    return List.generate(43, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Random key generate karna (base64 format)
  static String _generateRandomKey(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}

/// ============================================================================
/// USAGE EXAMPLE (APP MEIN USE KARNA)
/// ============================================================================
///
/// // 1. NAYA WALLET CREATE KARNA
/// final wallet = await ArweaveWalletServiceSimple.createNewWallet(
///   displayName: 'My Tree NFT Wallet',
/// );
///
/// // 2. SAVE KARNA
/// await ArweaveWalletServiceSimple.saveWallet(wallet);
///
/// // 3. LOAD KARNA (NEXT TIME)
/// final savedWallet = await ArweaveWalletServiceSimple.loadWallet();
///
/// // 4. ADDRESS KA USE KARNA
/// final address = savedWallet?.address;
/// print('My Arweave Address: $address');
///
/// // 5. DISPLAY KARNA
/// print(savedWallet); // "Wallet(My Tree NFT Wallet) - abc123..."
