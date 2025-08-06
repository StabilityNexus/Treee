import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/constants/contract_abis/tree_nft_contract_abi.dart';

class ContractWriteResult {
  final bool success;
  final String? transactionHash;
  final String? errorMessage;
  final dynamic data;

  ContractWriteResult({
    required this.success,
    this.transactionHash,
    this.errorMessage,
    this.data,
  });

  ContractWriteResult.success({
    required String transactionHash,
    dynamic data,
  }) : this(
          success: true,
          transactionHash: transactionHash,
          data: data,
        );

  ContractWriteResult.error({
    required String errorMessage,
  }) : this(
          success: false,
          errorMessage: errorMessage,
        );
}

class ContractWriteFunctions {
  static final String _contractAddress = dotenv.env['CONTRACT_ADDRESS'] ??
      '';

  /// Mint a new Tree NFT
  /// 
  /// Parameters:
  /// - [walletProvider]: The wallet provider instance
  /// - [latitude]: Latitude coordinate (-90.0 to 90.0)
  /// - [longitude]: Longitude coordinate (-180.0 to 180.0)  
  /// - [species]: Tree species name
  /// - [photos]: List of photo URLs/paths
  /// - [geoHash]: Geographic hash for the location
  /// - [additionalData]: Optional additional metadata
  /// 
  /// Returns [ContractWriteResult] with transaction details
  static Future<ContractWriteResult> mintNft({
    required WalletProvider walletProvider,
    required double latitude,
    required double longitude,
    required String species,
    required List<String> photos,
    required String geoHash,
    String additionalData = "",
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for minting NFT");
        return ContractWriteResult.error(
          errorMessage: 'Please connect your wallet before minting.',
        );
      }
      if (latitude < -90.0 || latitude > 90.0 || longitude < -180.0 || longitude > 180.0) {
        logger.e("Invalid coordinates: Lat: $latitude, Lng: $longitude");
        return ContractWriteResult.error(
          errorMessage: 'Invalid coordinates. Lat: [-90, 90], Lng: [-180, 180].',
        );
      }
      final lat = BigInt.from((latitude + 90.0) * 1e6);
      final lng = BigInt.from((longitude + 180.0) * 1e6);
      
      logger.i("Minting NFT with coordinates: Lat: $lat, Lng: $lng");
      logger.i("Species: $species, Photos: ${photos.length}, GeoHash: $geoHash");
      final List<dynamic> args = [
        lat,
        lng,
        species,
        photos.isNotEmpty ? photos[0] : "",
        additionalData,
        geoHash,
        photos,
      ];
      final txHash = await walletProvider.writeContract(
        contractAddress: TreeNFtContractAddress,
        functionName: 'mintNft',
        params: args,
        abi: TreeNftContractABI,
        chainId: walletProvider.currentChainId,
      );

      logger.i("NFT minting transaction sent: $txHash");

      return ContractWriteResult.success(
        transactionHash: txHash,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'species': species,
          'photos': photos,
          'geoHash': geoHash,
        },
      );

    } catch (e) {
      logger.e("Error minting NFT", error: e);
      return ContractWriteResult.error(
        errorMessage: e.toString(),
      );
    }
  }
  /// Get the contract address being used
  static String get contractAddress => _contractAddress;
}