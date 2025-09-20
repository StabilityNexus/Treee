import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/services/switch_chain_utils.dart';

Widget buildWrongChainWidget(BuildContext context) {
  final walletProvider = Provider.of<WalletProvider>(context, listen: false);
  return Center(
    child: Container(
      decoration: BoxDecoration(
        color: getThemeColors(context)['primary'],
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: getThemeColors(context)['icon'],
          ),
          const SizedBox(height: 16),
          Text(
            'Please switch to the chain supported by Tree Planting Protocol',
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
                getThemeColors(context)['primary']!,
              ),
            ),
            child: const Text('Switch Chain'),
          ),
        ],
      ),
    ),
  );
}
