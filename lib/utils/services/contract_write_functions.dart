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
  static Future<ContractWriteResult> mintNft({
    required WalletProvider walletProvider,
    required double latitude,
    required double longitude,
    required String species,
    required List<String> photos,
    required String geoHash,
    required String metadata,
    String additionalData = "",
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for minting NFT");
        return ContractWriteResult.error(
          errorMessage: 'Please connect your wallet before minting.',
        );
      }
      if (latitude < -90.0 ||
          latitude > 90.0 ||
          longitude < -180.0 ||
          longitude > 180.0) {
        logger.e("Invalid coordinates: Lat: $latitude, Lng: $longitude");
        return ContractWriteResult.error(
          errorMessage:
              'Invalid coordinates. Lat: [-90, 90], Lng: [-180, 180].',
        );
      }
      final lat = BigInt.from((latitude + 90.0) * 1e6);
      final lng = BigInt.from((longitude + 180.0) * 1e6);

      logger.i("Minting NFT with coordinates: Lat: $lat, Lng: $lng");
      logger
          .i("Species: $species, Photos: ${photos.length}, GeoHash: $geoHash");
      final List<dynamic> args = [
        lat,
        lng,
        species,
        photos.isNotEmpty ? photos[0] : "",
        "",
        metadata,
        geoHash,
        photos,
      ];
      final txHash = await walletProvider.writeContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'mintNft',
        params: args,
        abi: treeNftContractABI,
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

  static Future<ContractWriteResult> registerUser({
    required WalletProvider walletProvider,
    required String name,
    required String profilePhotoHash,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected ");
        return ContractWriteResult.error(
          errorMessage: 'Please connect your wallet.',
        );
      }
      final List<dynamic> args = [name, profilePhotoHash];
      final txHash = await walletProvider.writeContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'registerUserProfile',
        params: args,
        abi: treeNftContractABI,
        chainId: walletProvider.currentChainId,
      );

      logger.i("User registeration transaction sent: $txHash");

      return ContractWriteResult.success(
        transactionHash: txHash,
        data: {'name': name, 'profilePhotoHash': profilePhotoHash},
      );
    } catch (e) {
      logger.e("Error registering User", error: e);
      return ContractWriteResult.error(
        errorMessage: e.toString(),
      );
    }
  }

  static Future<ContractWriteResult> verifyTree(
      {required WalletProvider walletProvider,
      required int treeId,
      required String description,
      required List<String> photos}) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for verifying tree");
        return ContractWriteResult.error(
          errorMessage: 'Please connect your wallet before verifying.',
        );
      }

      final List<dynamic> args = [BigInt.from(treeId), photos, description];
      final txHash = await walletProvider.writeContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'verify',
        params: args,
        abi: treeNftContractABI,
        chainId: walletProvider.currentChainId,
      );

      logger.i("Tree verification transaction sent: $txHash");

      return ContractWriteResult.success(
        transactionHash: txHash,
        data: {'treeId': treeId},
      );
    } catch (e) {
      logger.e("Error verifying Tree", error: e);
      return ContractWriteResult.error(
        errorMessage: e.toString(),
      );
    }
  }

  static Future<ContractWriteResult> removeVerification(
      {required WalletProvider walletProvider,
      required int treeId,
      required String address}) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for removing verification");
        return ContractWriteResult.error(
          errorMessage:
              'Please connect your wallet before removing verification.',
        );
      }

      final List<dynamic> args = [BigInt.from(treeId), address];
      final txHash = await walletProvider.writeContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'removeVerification',
        params: args,
        abi: treeNftContractABI,
        chainId: walletProvider.currentChainId,
      );

      logger.i("Remove verification transaction sent: $txHash");

      return ContractWriteResult.success(
        transactionHash: txHash,
        data: {'treeId': treeId, 'address': address},
      );
    } catch (e) {
      logger.e("Error removing verification", error: e);
      return ContractWriteResult.error(
        errorMessage: e.toString(),
      );
    }
  }
}
