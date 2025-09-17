import 'package:flutter/material.dart';

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
       
      ],
    ),
  );
}
