import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:provider/provider.dart';

Widget buildWalletNotConnectedWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Please connect your wallet to view your NFTs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final walletProvider = Provider.of<WalletProvider>(context, listen: false);
            },
            child: const Text('Connect Wallet'),
          ),
        ],
      ),
    );
  }
