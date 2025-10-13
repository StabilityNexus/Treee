// ignore: depend_on_referenced_packages
import 'package:web3dart/web3dart.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/constants/contract_abis/tree_nft_contract_details.dart';

class ContractReadResult {
  final bool success;
  final String? transactionHash;
  final String? errorMessage;
  final dynamic data;

  ContractReadResult({
    required this.success,
    this.transactionHash,
    this.errorMessage,
    this.data,
  });

  ContractReadResult.success({
    String? transactionHash,
    dynamic data,
  }) : this(
          success: true,
          transactionHash: transactionHash,
          data: data,
        );

  ContractReadResult.error({
    required String errorMessage,
  }) : this(
          success: false,
          errorMessage: errorMessage,
        );
}

class ContractReadFunctions {
  static Future<ContractReadResult> getNFTsByUserPaginated({
    required WalletProvider walletProvider,
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for reading NFTs");
        return ContractReadResult.error(
          errorMessage: 'Please connect your wallet before reading NFTs.',
        );
      }
      final String address = walletProvider.currentAddress.toString();
      if (!address.startsWith('0x')) {
        return ContractReadResult.error(
          errorMessage: 'Invalid wallet address format',
        );
      }
      final EthereumAddress userAddress = EthereumAddress.fromHex(address);
      if (offset < 0 || limit <= 0 || limit > 100) {
        return ContractReadResult.error(
          errorMessage:
              'Invalid pagination parameters. Offset must be >= 0 and limit must be between 1-100',
        );
      }
      final List<dynamic> args = [
        userAddress,
        BigInt.from(offset),
        BigInt.from(limit),
      ];

      final result = await walletProvider.readContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'getNFTsByUserPaginated',
        params: args,
        abi: treeNftContractABI,
      );
      logger.i("NFTs read successfully: $result");
      if (result == null || result.isEmpty) {
        return ContractReadResult.error(
          errorMessage: 'No data returned from contract',
        );
      }
      final trees = result.length > 0 ? result[0] ?? [] : [];
      final totalCount =
          result.length > 1 ? int.parse(result[1].toString()) : 0;
      logger.d(trees);
      return ContractReadResult.success(
        data: {
          'trees': trees,
          'totalCount': totalCount,
        },
      );
    } catch (e) {
      logger.e("Error reading NFTs", error: e);
      return ContractReadResult.error(
        errorMessage: 'Failed to read NFTs: ${e.toString()}',
      );
    }
  }

  static Future<ContractReadResult> getProfileDetails({
    required WalletProvider walletProvider,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for reading user data");
        return ContractReadResult.error(
          errorMessage:
              'Please connect your wallet before fetching user details from blockchain',
        );
      }
      final String address = walletProvider.currentAddress.toString();
      if (!address.startsWith('0x')) {
        return ContractReadResult.error(
          errorMessage: 'Invalid wallet address format',
        );
      }
      final String currentAddress = walletProvider.currentAddress!.toString();
      final EthereumAddress userAddress =
          EthereumAddress.fromHex(currentAddress);
      final List<dynamic> args = [userAddress];
      final userVerifierTokensResult = await walletProvider.readContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'getUserVerifierTokenDetails',
        abi: treeNftContractABI,
        params: args,
      );
      final userProfileResult = await walletProvider.readContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'getUserProfile',
        abi: treeNftContractABI,
        params: args,
      );
      final profile =
          userProfileResult.length > 0 ? userProfileResult[0] ?? [] : [];
      final verifierTokens = userVerifierTokensResult.length > 0
          ? userVerifierTokensResult[0] ?? []
          : [];
      logger.d("User Profile");
      logger.d(profile);
      return ContractReadResult.success(
          data: {'profile': profile, 'verifierTokens': verifierTokens});
    } catch (e) {
      logger.e("Error reading User profile", error: e);
      return ContractReadResult.error(
        errorMessage: 'Failed to read User Profile: ${e.toString()}',
      );
    }
  }

  static Future<ContractReadResult> getTreeNFTInfo({
    required WalletProvider walletProvider,
    required int id,
    required int offset,
    required int limit,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected");
        return ContractReadResult.error(
          errorMessage: 'Please connect your wallet first',
        );
      }
      final String address = walletProvider.currentAddress.toString();
      if (!address.startsWith('0x')) {
        return ContractReadResult.error(
          errorMessage: 'Invalid wallet address format',
        );
      }
      final List<dynamic> args = [BigInt.from(id)];
      final treeDetailsResult = await walletProvider.readContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'getTreeDetailsbyID',
        params: args,
        abi: treeNftContractABI,
      );
      final tree =
          treeDetailsResult.length > 0 ? treeDetailsResult[0] ?? [] : [];
      final treeVerifiersResult = await walletProvider.readContract(
          contractAddress: treeNFtContractAddress,
          functionName: 'getTreeNftVerifiersPaginated',
          params: [BigInt.from(id), BigInt.from(offset), BigInt.from(limit)],
          abi: treeNftContractABI);
      final verifiers =
          treeVerifiersResult.length > 0 ? treeVerifiersResult[0] ?? [] : [];
      logger.d("Tree Verifiers Info");
      logger.d(verifiers);
      final ownerResult = await walletProvider.readContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'ownerOf',
        params: [BigInt.from(id)],
        abi: treeNftContractABI,
      );
      final owner = ownerResult.isNotEmpty ? ownerResult[0] : null;
      return ContractReadResult.success(
        data: {'details': tree, 'verifiers': verifiers, 'owner': owner},
      );
    } catch (e) {
      logger.e("Error fetching the details of the Tree NFT", error: e);
      return ContractReadResult.error(
        errorMessage: 'Failed to read the details of the Tree: ${e.toString()}',
      );
    }
  }

  static Future<ContractReadResult> getRecentTreesPaginated({
    required WalletProvider walletProvider,
    required int offset,
    required int limit,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected");
        return ContractReadResult.error(
          errorMessage: 'Please connect your wallet first',
        );
      }
      final String address = walletProvider.currentAddress.toString();
      if (!address.startsWith('0x')) {
        return ContractReadResult.error(
          errorMessage: 'Invalid wallet address format',
        );
      }

      if (offset < 0 || limit <= 0 || limit > 50) {
        return ContractReadResult.error(
          errorMessage:
              'Invalid pagination parameters. Offset must be >= 0 and limit must be between 1-50',
        );
      }

      final List<dynamic> args = [BigInt.from(offset), BigInt.from(limit)];
      final contractResult = await walletProvider.readContract(
        contractAddress: treeNFtContractAddress,
        functionName: 'getRecentTreesPaginated',
        params: args,
        abi: treeNftContractABI,
      );

      if (contractResult == null || contractResult.isEmpty) {
        return ContractReadResult.error(
          errorMessage: 'No data returned from contract',
        );
      }
      final trees = contractResult[0] as List; 
      final totalCount =
          (contractResult[1] as BigInt).toInt(); 
      final hasMore = contractResult[2] as bool;

      final List<Map<String, dynamic>> parsedTrees = trees.map((tree) {
        final treeList = tree as List;
        return {
          'id': (treeList[0] as BigInt).toInt(),
          'latitude': (treeList[1] as BigInt).toInt(),
          'longitude': (treeList[2] as BigInt).toInt(),
          'planting': (treeList[3] as BigInt).toInt(),
          'death': (treeList[4] as BigInt).toInt(),
          'species': treeList[5] as String,
          'imageUri': treeList[6] as String,
          'qrPhoto': treeList[7] as String,
          'metadata': treeList[8] as String,
          'photos':
              (treeList[9] as List).map((photo) => photo as String).toList(),
          'geoHash': treeList[10] as String,
          'ancestors': (treeList[11] as List)
              .map((ancestor) => (ancestor as EthereumAddress).hex)
              .toList(),
          'lastCareTimestamp': (treeList[12] as BigInt).toInt(),
          'careCount': (treeList[13] as BigInt).toInt(),
          'numberOfTrees': (treeList[14] as BigInt).toInt(),
        };
      }).toList();

      logger
          .d("Recent trees fetched successfully: ${parsedTrees.length} trees");

      return ContractReadResult.success(
        data: {
          'trees': parsedTrees,
          'totalCount': totalCount,
          'hasMore': hasMore,
          'offset': offset,
          'limit': limit,
        },
      );
    } catch (e) {
      logger.e("Error fetching recent trees", error: e);
      return ContractReadResult.error(
        errorMessage: 'Failed to read recent trees: ${e.toString()}',
      );
    }
  }
}
