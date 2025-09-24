// ignore: depend_on_referenced_packages
import 'package:web3dart/web3dart.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/constants/contract_abis/organisation_factory_contract_details.dart';

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
  static Future<ContractReadResult> getOrganisationsByUser({
    required WalletProvider walletProvider,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for reading organisations");
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
      final List<dynamic> args = [
        userAddress,
      ];
      final result = await walletProvider.readContract(
        contractAddress: organisationFactoryContractAddress,
        functionName: 'getUserOrganisations',
        params: args,
        abi: organisationFactoryContractAbi,
      );
      logger.i("Organisations read successfully: $result");
      if (result == null || result.isEmpty) {
        return ContractReadResult.error(
          errorMessage: 'No data returned from contract',
        );
      }
      final organisations = result.length > 0 ? result[0] ?? [] : [];
      final totalCount =
          result.length > 1 ? int.parse(result[1].toString()) : 0;
      logger.d(organisations);
      return ContractReadResult.success(
        data: {
          'organisations': organisations,
          'totalCount': totalCount,
        },
      );
    } catch (e) {
      logger.e("Error reading organisations", error: e);
      return ContractReadResult.error(
        errorMessage: 'Failed to read NFTs: ${e.toString()}',
      );
    }
  }
}
