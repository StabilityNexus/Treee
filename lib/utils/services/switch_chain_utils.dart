import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
  
  void showChainSelector(BuildContext context, WalletProvider walletProvider) {
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
                      await switchToChain(context, walletProvider, chain['chainId'] as String);
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

  Future<void> switchToChain(BuildContext context, WalletProvider walletProvider, String chainId) async {
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
