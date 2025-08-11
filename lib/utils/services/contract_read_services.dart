import 'package:web3dart/web3dart.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/constants/contract_abis/tree_nft_contract_abi.dart';

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
        contractAddress: TreeNFtContractAddress,
        functionName: 'getNFTsByUserPaginated',
        params: args,
        abi: TreeNftContractABI,
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

  static Future<ContractReadResult> ping({
    required WalletProvider walletProvider,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for ping");
        return ContractReadResult.error(
          errorMessage: 'Please connect your wallet before pinging.',
        );
      }

      final String address = walletProvider.currentAddress.toString();
      if (!address.startsWith('0x')) {
        return ContractReadResult.error(
          errorMessage: 'Invalid wallet address format',
        );
      }
      final result = await walletProvider.readContract(
        contractAddress: TreeNFtContractAddress,
        functionName: 'ping',
        abi: TreeNftContractABI,
        params: [],
      );
      String pingResponse;
      if (result != null) {
        if (result is List && result.isNotEmpty) {
          pingResponse =
              result[0]?.toString() ?? 'Ping successful - no return value';
        } else {
          pingResponse = result.toString();
        }
      } else {
        pingResponse = 'Ping successful - no return value';
      }
      return ContractReadResult.success(
        data: {
          'result': pingResponse,
        },
      );
    } catch (e) {
      logger.e("Error pinging contract", error: e);

      String detailedError = 'Ping failed: ${e.toString()}';
      return ContractReadResult.error(
        errorMessage: detailedError,
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
      final EthereumAddress userAddress = EthereumAddress.fromHex(currentAddress);
      final List<dynamic> args = [userAddress];
      final result = await walletProvider.readContract(
        contractAddress: TreeNFtContractAddress,
        functionName: 'getUserProfile',
        abi: TreeNftContractABI,
        params: args,
      );
      final profile = result.length() > 0 ? result[0] ?? [] : [];
      return ContractReadResult.success(data: {'profile': profile});
    } catch (e) {
      logger.e("Error reading User profile", error: e);
      return ContractReadResult.error(
        errorMessage: 'Failed to read User Profile: ${e.toString()}',
      );
    }
  }
}
