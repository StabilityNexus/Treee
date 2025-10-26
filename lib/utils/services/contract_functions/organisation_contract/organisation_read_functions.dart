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

      // Get organisation basic info
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
      final timeOfCreation = (orgDetailsResult[6] as BigInt).toInt();

      // Get owners with pagination
      final ownersResult = await walletProvider.readContract(
        contractAddress: organisationContractAddress,
        functionName: 'getOwners',
        params: [BigInt.from(0), BigInt.from(100)], // offset, limit
        abi: organisationContractAbi,
      );

      final owners = ownersResult.isNotEmpty
          ? (ownersResult[0] as List)
              .map((e) => (e as EthereumAddress).hex)
              .toList()
          : <String>[];

      // Get members with pagination
      final membersResult = await walletProvider.readContract(
        contractAddress: organisationContractAddress,
        functionName: 'getMembers',
        params: [BigInt.from(0), BigInt.from(100)], // offset, limit
        abi: organisationContractAbi,
      );

      final members = membersResult.isNotEmpty
          ? (membersResult[0] as List)
              .map((e) => (e as EthereumAddress).hex)
              .toList()
          : <String>[];

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
          'timeOfCreation': timeOfCreation,
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

  static Future<ContractReadResult> getVerificationRequestsByStatus({
    required WalletProvider walletProvider,
    required String organisationContractAddress,
    required int status, // 0: Pending, 1: Approved, 2: Rejected
    required int offset,
    required int limit,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected");
        return ContractReadResult.error(
          errorMessage: 'Please connect your wallet.',
        );
      }

      final String address = walletProvider.currentAddress.toString();
      if (!address.startsWith('0x')) {
        return ContractReadResult.error(
          errorMessage: 'Invalid wallet address format',
        );
      }

      final args = [
        BigInt.from(status),
        BigInt.from(offset),
        BigInt.from(limit)
      ];
      final contractResult = await walletProvider.readContract(
        contractAddress: organisationContractAddress,
        functionName: 'getVerificationRequestsByStatus',
        params: args,
        abi: organisationContractAbi,
      );

      if (contractResult == null || contractResult.isEmpty) {
        return ContractReadResult.error(
          errorMessage: 'No data returned from contract',
        );
      }

      // Parse the contract result according to the return structure:
      // returns (OrganisationVerificationRequest[] memory requests, uint256 totalMatching, bool hasMore)
      final requests =
          contractResult[0] as List; // OrganisationVerificationRequest[]
      final totalMatching = (contractResult[1] as BigInt).toInt();
      final hasMore = contractResult[2] as bool;

      // Parse each OrganisationVerificationRequest
      final List<Map<String, dynamic>> parsedRequests = requests.map((request) {
        final requestList = request as List;
        return {
          'id': (requestList[0] as BigInt).toInt(),
          'initialMember': (requestList[1] as EthereumAddress).hex,
          'organisationContract': (requestList[2] as EthereumAddress).hex,
          'status': (requestList[3] as BigInt).toInt(),
          'description': requestList[4] as String,
          'timestamp': (requestList[5] as BigInt).toInt(),
          'proofHashes':
              (requestList[6] as List).map((hash) => hash as String).toList(),
          'treeNftId': (requestList[7] as BigInt).toInt(),
        };
      }).toList();

      return ContractReadResult.success(
        data: {
          'requests': parsedRequests,
          'totalMatching': totalMatching,
          'hasMore': hasMore,
          'status': status,
          'offset': offset,
          'limit': limit,
        },
      );
    } catch (e) {
      logger.e("Error reading verification requests", error: e);
      return ContractReadResult.error(
        errorMessage: 'Failed to read verification requests: ${e.toString()}',
      );
    }
  }

  static Future<ContractReadResult> getTreePlantingProposalsByStatus({
    required WalletProvider walletProvider,
    required String organisationContractAddress,
    required int status, // 0: Pending, 1: Approved, 2: Rejected
    required int offset,
    required int limit,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for reading tree planting proposals");
        return ContractReadResult.error(
          errorMessage: 'Please connect your wallet before reading proposals.',
        );
      }

      final String address = walletProvider.currentAddress.toString();
      if (!address.startsWith('0x')) {
        return ContractReadResult.error(
          errorMessage: 'Invalid wallet address format',
        );
      }

      final args = [
        BigInt.from(status),
        BigInt.from(offset),
        BigInt.from(limit)
      ];
      final contractResult = await walletProvider.readContract(
        contractAddress: organisationContractAddress,
        functionName: 'getTreePlantingProposalsByStatus',
        params: args,
        abi: organisationContractAbi,
      );

      if (contractResult == null || contractResult.isEmpty) {
        return ContractReadResult.error(
          errorMessage: 'No data returned from contract',
        );
      }

      // Parse the contract result according to the return structure:
      // returns (TreePlantingProposal[] memory proposals, uint256 totalMatching, bool hasMore)
      final proposals = contractResult[0] as List; // TreePlantingProposal[]
      final totalMatching = (contractResult[1] as BigInt).toInt();
      final hasMore = contractResult[2] as bool;

      // Parse each TreePlantingProposal
      final List<Map<String, dynamic>> parsedProposals =
          proposals.map((proposal) {
        final proposalList = proposal as List;
        return {
          'id': (proposalList[0] as BigInt).toInt(),
          'latitude': (proposalList[1] as BigInt).toInt(),
          'longitude': (proposalList[2] as BigInt).toInt(),
          'species': proposalList[3] as String,
          'imageUri': proposalList[4] as String,
          'qrPhoto': proposalList[5] as String,
          'photos': (proposalList[6] as List)
              .map((photo) => photo as String)
              .toList(),
          'geoHash': proposalList[7] as String,
          'metadata': proposalList[8] as String,
          'status': (proposalList[9] as BigInt).toInt(),
          'numberOfTrees': (proposalList[10] as BigInt).toInt(),
          'initiator': (proposalList[11] as EthereumAddress).hex,
        };
      }).toList();

      return ContractReadResult.success(
        data: {
          'proposals': parsedProposals,
          'totalMatching': totalMatching,
          'hasMore': hasMore,
          'status': status,
          'offset': offset,
          'limit': limit,
        },
      );
    } catch (e) {
      logger.e("Error reading tree planting proposals", error: e);
      return ContractReadResult.error(
        errorMessage: 'Failed to read tree planting proposals: ${e.toString()}',
      );
    }
  }
}
