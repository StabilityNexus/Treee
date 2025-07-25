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
    }
  ];

  String? currentCount;
  bool isLoading = false;
  String? errorMessage;

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

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
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
            
            // Refresh Button
            ElevatedButton.icon(
              onPressed: isLoading ? null : _loadCount,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Count'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
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
                                    : 'Wallet Not Connected (Reading via RPC)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        if (walletProvider.isConnected && walletProvider.currentChainId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Current Chain: ${walletProvider.currentChainId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
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