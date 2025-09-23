import 'package:flutter/material.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';

Widget buildWalletNotConnectedWidget(BuildContext context) {
  return Center(
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
          'Please connect your wallet to view your NFTs',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: getThemeColors(context)['textPrimary'],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
