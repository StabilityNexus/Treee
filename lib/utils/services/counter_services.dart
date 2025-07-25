// import 'package:web3dart/web3dart.dart';
// import 'package:tree_planting_protocol/providers/wallet_provider.dart';

// class CounterService {
//   // Sepolia testnet chain ID
//   static const int SEPOLIA_CHAIN_ID = 11155111;
  
//   // ABI for a simple counter contract
//   static const String counterABI = '''
//   [
//     {
//       "inputs": [],
//       "name": "count",
//       "outputs": [
//         {
//           "internalType": "uint256",
//           "name": "",
//           "type": "uint256"
//         }
//       ],
//       "stateMutability": "view",
//       "type": "function"
//     },
//     {
//       "inputs": [],
//       "name": "increment",
//       "outputs": [],
//       "stateMutability": "nonpayable",
//       "type": "function"
//     },
//     {
//       "inputs": [],
//       "name": "getCount",
//       "outputs": [
//         {
//           "internalType": "uint256",
//           "name": "",
//           "type": "uint256"
//         }
//       ],
//       "stateMutability": "view",
//       "type": "function"
//     }
//   ]
//   ''';

//   /// Get the current count from the smart contract
//   static Future<BigInt> getCount(
//     WalletProvider walletProvider,
//     String contractAddress,
//   ) async {
//     try {
//       // Ensure we have a web3 client
//       if (walletProvider.ethClient == null) {
//         throw Exception('Web3Client not initialized');
//       }

//       // Verify we're on the correct chain (Sepolia)
//       await _verifyChainId(walletProvider);

//       // Create contract instance
//       final contract = DeployedContract(
//         ContractAbi.fromJson(counterABI, 'Counter'),
//         EthereumAddress.fromHex(contractAddress),
//       );

//       // Get the count function
//       final countFunction = contract.function('getCount') ?? 
//                            contract.function('count');
      
//       if (countFunction == null) {
//         throw Exception('Count function not found in contract');
//       }

//       // Call the contract function
//       final result = await walletProvider.ethClient!.call(
//         contract: contract,
//         function: countFunction,
//         params: [],
//       );

//       // Return the count value
//       if (result.isNotEmpty && result[0] is BigInt) {
//         return result[0] as BigInt;
//       } else {
//         throw Exception('Invalid response from contract');
//       }
//     } catch (e) {
//       throw Exception('Failed to get count: ${e.toString()}');
//     }
//   }

//   /// Increment the counter by calling the smart contract
//   static Future<String> increment(
//     WalletProvider walletProvider,
//     String contractAddress,
//   ) async {
//     try {
//       // Ensure wallet is connected
//       if (!walletProvider.isConnected || walletProvider.currentAddress!.isEmpty) {
//         throw Exception('Wallet not connected');
//       }

//       // Ensure we're on Sepolia
//       await _verifyChainId(walletProvider);

//       // Ensure we have a web3 client
//       if (walletProvider.ethClient == null) {
//         throw Exception('Web3Client not initialized');
//       }

//       // Create contract instance
//       final contract = DeployedContract(
//         ContractAbi.fromJson(counterABI, 'Counter'),
//         EthereumAddress.fromHex(contractAddress),
//       );

//       // Get the increment function
//       final incrementFunction = contract.function('increment');
//       if (incrementFunction == null) {
//         throw Exception('Increment function not found in contract');
//       }

//       // Get current gas price
//       final gasPrice = await walletProvider.ethClient!.getGasPrice();
      
//       // Estimate gas for the transaction
//       BigInt gasLimit;
//       try {
//         gasLimit = await walletProvider.ethClient!.estimateGas(
//           sender: EthereumAddress.fromHex(walletProvider.currentAddress!),
//           to: EthereumAddress.fromHex(contractAddress),
//           data: incrementFunction.encodeCall([]),
//         );
//         // Add 20% buffer to gas limit
//         gasLimit = BigInt.from((gasLimit.toDouble() * 1.2).round());
//       } catch (e) {
//         // Fallback gas limit if estimation fails
//         gasLimit = BigInt.from(100000);
//       }

//       // Create the transaction
//       final transaction = Transaction.callContract(
//         contract: contract,
//         function: incrementFunction,
//         parameters: [],
//         from: EthereumAddress.fromHex(walletProvider.currentAddress!),
//         gasPrice: gasPrice,
//         maxGas: gasLimit.toInt(),
//       );

//       // Send the transaction
//       final txHash = await walletProvider.sendTransaction(transaction 
//         , contractAddress: contractAddress,
//         functionName: 'increment',
//         parameters: [],
//       );
      
//       return txHash;
//     } catch (e) {
//       throw Exception('Failed to increment: ${e.toString()}');
//     }
//   }

//   /// Get transaction receipt and status
//   static Future<TransactionReceipt?> getTransactionReceipt(
//     WalletProvider walletProvider,
//     String txHash,
//   ) async {
//     try {
//       if (walletProvider.ethClient == null) {
//         throw Exception('Web3Client not initialized');
//       }

//       return await walletProvider.ethClient!.getTransactionReceipt(txHash);
//     } catch (e) {
//       throw Exception('Failed to get transaction receipt: ${e.toString()}');
//     }
//   }

//   /// Wait for transaction confirmation
//   static Future<TransactionReceipt> waitForTransaction(
//     WalletProvider walletProvider,
//     String txHash, {
//     Duration timeout = const Duration(minutes: 5),
//     Duration pollInterval = const Duration(seconds: 2),
//   }) async {
//     final startTime = DateTime.now();
    
//     while (DateTime.now().difference(startTime) < timeout) {
//       try {
//         final receipt = await getTransactionReceipt(walletProvider, txHash);
//         if (receipt != null) {
//           return receipt;
//         }
//       } catch (e) {
//         // Continue polling on error
//       }
      
//       await Future.delayed(pollInterval);
//     }
    
//     throw Exception('Transaction confirmation timeout');
//   }

//   /// Get the Sepolia Etherscan URL for a transaction
//   static String getEtherscanUrl(String txHash) {
//     return 'https://sepolia.etherscan.io/tx/$txHash';
//   }

//   /// Validate contract address format
//   static bool isValidContractAddress(String address) {
//     try {
//       EthereumAddress.fromHex(address);
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Format BigInt count for display
//   static String formatCount(BigInt count) {
//     return count.toString();
//   }

//   /// Convert Wei to Ether for gas calculations
//   static String weiToEther(BigInt wei) {
//     return EtherAmount.inWei(wei).getValueInUnit(EtherUnit.ether).toString();
//   }

//   /// Verify that we're connected to the Sepolia testnet
//   static Future<void> _verifyChainId(WalletProvider walletProvider) async {
//     try {
//       final chainId = await walletProvider.ethClient!.getChainId();
//       if (chainId != SEPOLIA_CHAIN_ID) {
//         throw Exception(
//           'Wrong network! Please switch to Sepolia testnet (Chain ID: $SEPOLIA_CHAIN_ID). '
//           'Current Chain ID: $chainId'
//         );
//       }
//     } catch (e) {
//       if (e.toString().contains('Wrong network')) {
//         rethrow;
//       }
//       throw Exception('Failed to verify chain ID: ${e.toString()}');
//     }
//   }

//   /// Get current chain ID
//   static Future<BigInt> getCurrentChainId(WalletProvider walletProvider) async {
//     try {
//       if (walletProvider.ethClient == null) {
//         throw Exception('Web3Client not initialized');
//       }
//       return await walletProvider.ethClient!.getChainId();
//     } catch (e) {
//       throw Exception('Failed to get chain ID: ${e.toString()}');
//     }
//   }

//   /// Check if currently connected to Sepolia
//   static Future<bool> isConnectedToSepolia(WalletProvider walletProvider) async {
//     try {
//       final chainId = await getCurrentChainId(walletProvider);
//       return chainId == SEPOLIA_CHAIN_ID;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Get chain name from chain ID
//   static String getChainName(int chainId) {
//     switch (chainId) {
//       case 1:
//         return 'Ethereum Mainnet';
//       case 5:
//         return 'Goerli Testnet';
//       case 11155111:
//         return 'Sepolia Testnet';
//       case 137:
//         return 'Polygon Mainnet';
//       case 80001:
//         return 'Polygon Mumbai';
//       default:
//         return 'Unknown Network (ID: $chainId)';
//     }
//   }
// }