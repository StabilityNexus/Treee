import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/contract_abis/organisation_factory_contract_details.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

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

class OrganisationFactoryContractWriteFunctions {
  static Future<ContractWriteResult> createOrganisation({
    required WalletProvider walletProvider,
    required String name,
    required String description,
    required String organisationPhotoHash,
    String additionalData = "",
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for minting NFT");
        return ContractWriteResult.error(
          errorMessage: 'Please connect your wallet before minting.',
        );
      }

      final List<dynamic> args = [name, description, organisationPhotoHash];
      final txHash = await walletProvider.writeContract(
        contractAddress: organisationFactoryContractAddress,
        functionName: 'createOrganisation',
        params: args,
        abi: organisationFactoryContractAbi,
        chainId: walletProvider.currentChainId,
      );

      logger.i("NFT minting transaction sent: $txHash");

      return ContractWriteResult.success(
        transactionHash: txHash,
        data: {
          'name': name,
          'description': description,
          'organisationPhotoHash': organisationPhotoHash,
        },
      );
    } catch (e) {
      logger.e("Error minting NFT", error: e);
      return ContractWriteResult.error(
        errorMessage: e.toString(),
      );
    }
  }
}
