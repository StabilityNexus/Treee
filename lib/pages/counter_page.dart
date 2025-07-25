import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  static const String contractAddress = '0xa122109493B90e322824c3444ed8D6236CAbAB7C';
  static const String chainId = '11155111'; // Sepolia testnet
  
  static const List<Map<String, dynamic>> contractAbi = [
    {
      "inputs": [],
      "name": "getCount",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "increment",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ];

  String? currentCount;
  bool isLoading = false;
  bool isIncrementing = false;
  String? errorMessage;
  String? lastTransactionHash;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      final result = await walletProvider.readContract(
        contractAddress: contractAddress,
        functionName: 'getCount',
        abi: contractAbi,
      );

      setState(() {
        // The result is a List, and getCount returns a single uint256
        currentCount = result.isNotEmpty ? result[0].toString() : '0';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _incrementCount() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    if (!walletProvider.isConnected) {
      _showErrorDialog('Wallet Not Connected', 
          'Please connect your wallet to increment the counter.');
      return;
    }

    if (walletProvider.currentChainId != chainId) {
      _showErrorDialog('Wrong Network', 
          'Please switch to Sepolia testnet (Chain ID: $chainId) to interact with this contract.');
      return;
    }

    setState(() {
      isIncrementing = true;
    });

    try {
      final txHash = await walletProvider.writeContract(
        contractAddress: contractAddress,
        functionName: 'increment',
        abi: contractAbi,
        chainId: chainId,
      );

      setState(() {
        lastTransactionHash = txHash;
        isIncrementing = false;
      });

      _showSuccessDialog('Transaction Sent!', 
          'Transaction hash: ${txHash.substring(0, 10)}...\n\nThe counter will update once the transaction is confirmed.');

      // Auto-refresh count after a delay to allow transaction confirmation
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _loadCount();
        }
      });

    } catch (e) {
      setState(() {
        isIncrementing = false;
      });
      _showErrorDialog('Transaction Failed', e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Counter',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contract Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contract Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Address:', contractAddress),
                    _buildInfoRow('Chain ID:', chainId),
                    _buildInfoRow('Network:', 'Sepolia Testnet'),
                    _buildInfoRow('Function:', 'getCount()'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Count Display Card
            Card(
              elevation: 4,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Current Count',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading count...'),
                        ],
                      )
                    else if (errorMessage != null)
                      Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: $errorMessage',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentCount ?? '0',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last updated: ${DateTime.now().toString().substring(11, 19)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _loadCount,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Count'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<WalletProvider>(
                    builder: (context, walletProvider, child) {
                      final bool canIncrement = walletProvider.isConnected && 
                          walletProvider.currentChainId == chainId &&
                          !isIncrementing && !isLoading;
                      
                      return ElevatedButton.icon(
                        onPressed: canIncrement ? _incrementCount : null,
                        icon: isIncrementing 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(isIncrementing ? 'Incrementing...' : 'Increment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // Transaction Hash Display
            if (lastTransactionHash != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Last Transaction',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hash: ${lastTransactionHash!.substring(0, 20)}...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View on Etherscan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const Spacer(),
            
            // Status Information
            Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                return Card(
                  color: Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connection Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              walletProvider.isConnected
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              size: 16,
                              color: walletProvider.isConnected
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                walletProvider.isConnected
                                    ? 'Wallet Connected'
                                    : 'Wallet Not Connected (Read-only mode)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        if (walletProvider.isConnected) ...[
                          if (walletProvider.currentChainId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    walletProvider.currentChainId == chainId
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    size: 14,
                                    color: walletProvider.currentChainId == chainId
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Chain: ${walletProvider.currentChainId} ${walletProvider.currentChainId == chainId ? '(Correct)' : '(Switch to $chainId)'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: walletProvider.currentChainId == chainId
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (walletProvider.currentAddress != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Address: ${walletProvider.currentAddress!.substring(0, 6)}...${walletProvider.currentAddress!.substring(walletProvider.currentAddress!.length - 4)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Connect wallet to increment counter',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}