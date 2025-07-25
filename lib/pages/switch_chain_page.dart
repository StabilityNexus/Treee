import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class SwitchChainPage extends StatelessWidget {
  const SwitchChainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Current Chain',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          walletProvider.isConnected 
                            ? '${walletProvider.currentChainName} (${walletProvider.currentChainId})'
                            : 'Not Connected',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      walletProvider.statusMessage,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: walletProvider.isConnected 
                        ? () => _showChainSelector(context, walletProvider)
                        : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Switch Chain',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (!walletProvider.isConnected) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Please connect your wallet first',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChainSelector(BuildContext context, WalletProvider walletProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Chain',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...walletProvider.getSupportedChains().map((chain) {
                final isCurrentChain = chain['isCurrentChain'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      chain['name'] as String,
                      style: TextStyle(
                        fontWeight: isCurrentChain ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text('Chain ID: ${chain['chainId']}'),
                    trailing: isCurrentChain 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios),
                    tileColor: isCurrentChain ? Colors.green[50] : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isCurrentChain ? Colors.green : Colors.grey[300]!,
                      ),
                    ),
                    onTap: isCurrentChain ? null : () async {
                      Navigator.pop(context);
                      await _switchToChain(context, walletProvider, chain['chainId'] as String);
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchToChain(BuildContext context, WalletProvider walletProvider, String chainId) async {
    try {
      final success = await walletProvider.switchChain(chainId);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chain switched successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch chain: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}