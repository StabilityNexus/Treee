import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/contract_abis/organisation_contract_details.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

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

class OrganisationContractWriteFunctions {
  static Future<ContractWriteResult> addMember({
    required WalletProvider walletProvider,
    required String organisationContractAddress,
    required String userAddress,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for updating organisation details");
        return ContractWriteResult.error(
          errorMessage:
              'Please connect your wallet before updating organisation details.',
        );
      }

      final List<dynamic> args = [EthereumAddress.fromHex(userAddress)];
      final txHash = await walletProvider.writeContract(
        contractAddress: organisationContractAddress,
        functionName: 'addMember',
        params: args,
        abi: organisationContractAbi,
        chainId: walletProvider.currentChainId,
      );

      logger.i("Organisation update transaction sent: $txHash");

      return ContractWriteResult.success(transactionHash: txHash, data: {
        'userAddress': [EthereumAddress.fromHex(userAddress)],
      });
    } catch (e) {
      logger.e("Error updating organisation details: $e");
      return ContractWriteResult.error(
        errorMessage: 'Failed to update organisation details: $e',
      );
    }
  }

  static Future<ContractWriteResult> removeMember({
    required WalletProvider walletProvider,
    required String organisationContractAddress,
    required String userAddress,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for updating organisation details");
        return ContractWriteResult.error(
          errorMessage:
              'Please connect your wallet before updating organisation details.',
        );
      }

      final List<dynamic> args = [EthereumAddress.fromHex(userAddress)];
      final txHash = await walletProvider.writeContract(
        contractAddress: organisationContractAddress,
        functionName: 'removeMember',
        params: args,
        abi: organisationContractAbi,
        chainId: walletProvider.currentChainId,
      );

      logger.i("Organisation update transaction sent: $txHash");

      return ContractWriteResult.success(transactionHash: txHash, data: {
        'userAddress': EthereumAddress.fromHex(userAddress),
      });
    } catch (e) {
      logger.e("Error updating organisation details: $e");
      return ContractWriteResult.error(
        errorMessage: 'Failed to update organisation details: $e',
      );
    }
  }
}
