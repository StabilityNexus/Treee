import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    required String transactionHash,
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
  static final String _contractAddress = dotenv.env['CONTRACT_ADDRESS'] ??
      '';

  static Future<ContractReadResult> mintNft({
    required WalletProvider walletProvider,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for minting NFT");
        return ContractReadResult.error(
          errorMessage: 'Please connect your wallet before minting.',
        );
      }

      final List<dynamic> args = [
        walletProvider.currentAddress.toString()
      ];

      final txHash = await walletProvider.readContract(
        contractAddress: TreeNFtContractAddress,
        functionName: 'getNFTsByUsert',
        params: args,
        abi: TreeNftContractABI,
        chainId: walletProvider.currentChainId,
      );

      logger.i("NFT minting transaction sent: $txHash");

      return ContractReadResult.success(
        transactionHash: txHash,
        data: {
        },
      );

    } catch (e) {
      logger.e("Error minting NFT", error: e);
      return ContractReadResult.error(
        errorMessage: e.toString(),
      );
    }
  }
  
  static String get contractAddress => _contractAddress;
}