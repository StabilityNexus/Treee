import 'package:tree_planting_protocol/utils/constants/contract_abis/organisation_contract_details.dart';
// ignore: depend_on_referenced_packages
import 'package:web3dart/web3dart.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

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

class OrganisationContractReadFunctions {
  static Future<ContractReadResult> getOrganisationsByUser({
    required WalletProvider walletProvider,
    required String organisationContractAddress,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for reading organisations");
        return ContractReadResult.error(
          errorMessage:
              'Please connect your wallet before reading organisations.',
        );
      }

      final String address = walletProvider.currentAddress.toString();
      if (!address.startsWith('0x')) {
        return ContractReadResult.error(
          errorMessage: 'Invalid wallet address format',
        );
      }
      final orgDetailsResult = await walletProvider.readContract(
        contractAddress: organisationContractAddress,
        functionName: 'getOrganisationInfo',
        params: [],
        abi: organisationContractAbi,
      );

      if (orgDetailsResult == null || orgDetailsResult.isEmpty) {
        return ContractReadResult.error(
          errorMessage: 'No data returned from contract',
        );
      }
      final organisationAddress = (orgDetailsResult[0] as EthereumAddress).hex;
      final organisationName = orgDetailsResult[1] as String;
      final organisationDescription = orgDetailsResult[2] as String;
      final organisationLogoHash = orgDetailsResult[3] as String;

      final owners = (orgDetailsResult[4] as List)
          .map((e) => (e as EthereumAddress).hex)
          .toList();

      final members = (orgDetailsResult[5] as List)
          .map((e) => (e as EthereumAddress).hex)
          .toList();

      final timeOfCreation = orgDetailsResult[6] as BigInt;
      final isOwner =
          owners.any((o) => o.toLowerCase() == address.toLowerCase());
      final isMember =
          members.any((m) => m.toLowerCase() == address.toLowerCase());

      return ContractReadResult.success(
        data: {
          'organisationAddress': organisationAddress,
          'organisationName': organisationName,
          'organisationDescription': organisationDescription,
          'organisationLogoHash': organisationLogoHash,
          'owners': owners,
          'members': members,
          'timeOfCreation': timeOfCreation.toInt(),
          'isMember': isMember,
          'isOwner': isOwner,
        },
      );
    } catch (e) {
      logger.e("Error reading organisations", error: e);
      return ContractReadResult.error(
        errorMessage: 'Failed to read organisation info: ${e.toString()}',
      );
    }
  }
}
