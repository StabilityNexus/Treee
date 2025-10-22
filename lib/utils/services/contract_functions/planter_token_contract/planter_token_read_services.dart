// ignore: depend_on_referenced_packages
import 'package:web3dart/web3dart.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

class PlanterTokenReadResult {
  final bool success;
  final String? errorMessage;
  final dynamic data;

  PlanterTokenReadResult({
    required this.success,
    this.errorMessage,
    this.data,
  });

  PlanterTokenReadResult.success({
    dynamic data,
  }) : this(
          success: true,
          data: data,
        );

  PlanterTokenReadResult.error({
    required String errorMessage,
  }) : this(
          success: false,
          errorMessage: errorMessage,
        );
}

class PlanterTokenReadFunctions {
  // ERC20 token ABI for basic functions
  static const String _planterTokenAbi = '''
  [
    {
      "inputs": [],
      "name": "planterAddress",
      "outputs": [{"internalType": "address", "name": "", "type": "address"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "owner",
      "outputs": [{"internalType": "address", "name": "", "type": "address"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getPlanterAddress",
      "outputs": [{"internalType": "address", "name": "", "type": "address"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "name",
      "outputs": [{"internalType": "string", "name": "", "type": "string"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "symbol",
      "outputs": [{"internalType": "string", "name": "", "type": "string"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
      "name": "balanceOf",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  ''';

  static Future<PlanterTokenReadResult> getPlanterTokenDetails({
    required WalletProvider walletProvider,
    required String tokenContractAddress,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        logger.e("Wallet not connected for reading planter token");
        return PlanterTokenReadResult.error(
          errorMessage: 'Please connect your wallet.',
        );
      }

      // Create contract ABI
      final contractAbi =
          ContractAbi.fromJson(_planterTokenAbi, 'PlanterToken');

      // Call owner function
      final ownerResult = await walletProvider.readContract(
        contractAddress: tokenContractAddress,
        abi: contractAbi,
        functionName: 'owner',
        params: [],
      );

      // Call getPlanterAddress function
      final planterResult = await walletProvider.readContract(
        contractAddress: tokenContractAddress,
        abi: contractAbi,
        functionName: 'getPlanterAddress',
        params: [],
      );

      // Call name function
      final nameResult = await walletProvider.readContract(
        contractAddress: tokenContractAddress,
        abi: contractAbi,
        functionName: 'name',
        params: [],
      );

      // Call symbol function
      final symbolResult = await walletProvider.readContract(
        contractAddress: tokenContractAddress,
        abi: contractAbi,
        functionName: 'symbol',
        params: [],
      );

      if (!ownerResult.success ||
          !planterResult.success ||
          !nameResult.success ||
          !symbolResult.success) {
        return PlanterTokenReadResult.error(
          errorMessage: 'Failed to fetch token details from contract.',
        );
      }

      logger.d("Planter Token Details fetched successfully");
      logger.d("Owner: ${ownerResult.data[0]}");
      logger.d("Planter: ${planterResult.data[0]}");
      logger.d("Name: ${nameResult.data[0]}");
      logger.d("Symbol: ${symbolResult.data[0]}");

      return PlanterTokenReadResult.success(
        data: {
          'owner': (ownerResult.data[0] as EthereumAddress).hex,
          'planterAddress': (planterResult.data[0] as EthereumAddress).hex,
          'name': nameResult.data[0].toString(),
          'symbol': symbolResult.data[0].toString(),
          'contractAddress': tokenContractAddress,
        },
      );
    } catch (e) {
      logger.e("Error fetching planter token details: $e");
      return PlanterTokenReadResult.error(
        errorMessage: 'Failed to fetch token details: ${e.toString()}',
      );
    }
  }

  static Future<PlanterTokenReadResult> getTokenBalance({
    required WalletProvider walletProvider,
    required String tokenContractAddress,
    required String accountAddress,
  }) async {
    try {
      if (!walletProvider.isConnected) {
        return PlanterTokenReadResult.error(
          errorMessage: 'Please connect your wallet.',
        );
      }

      final account = EthereumAddress.fromHex(accountAddress);
      final contractAbi =
          ContractAbi.fromJson(_planterTokenAbi, 'PlanterToken');

      final balanceResult = await walletProvider.readContract(
        contractAddress: tokenContractAddress,
        abi: contractAbi,
        functionName: 'balanceOf',
        params: [account],
      );

      if (!balanceResult.success) {
        return PlanterTokenReadResult.error(
          errorMessage: 'Failed to fetch balance from contract.',
        );
      }

      logger.d("Token balance fetched: ${balanceResult.data[0]}");

      return PlanterTokenReadResult.success(
        data: {
          'balance': balanceResult.data[0].toString(),
          'accountAddress': accountAddress,
          'contractAddress': tokenContractAddress,
        },
      );
    } catch (e) {
      logger.e("Error fetching token balance: $e");
      return PlanterTokenReadResult.error(
        errorMessage: 'Failed to fetch balance: ${e.toString()}',
      );
    }
  }
}
