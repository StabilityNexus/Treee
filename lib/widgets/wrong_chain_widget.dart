import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/utils/services/switch_chain_utils.dart';

Widget buildWrongChainWidget(BuildContext context) {
  final walletProvider = Provider.of<WalletProvider>(context, listen: false);
  return Center(
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Please switch to the chain supported by Tree Planting Protocol i.e. ${walletProvider.correctChainId}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              showChainSelector(context, walletProvider);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                const Color.fromARGB(255, 28, 211, 129),
              ),
            ),
            child: const Text('Switch Chain'),
          ),
        ],
      ),
    ),
  );
}
