import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/utils/constants/navbar_constants.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';
import 'package:tree_planting_protocol/widgets/user_nfts_widget.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: appName,
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.push(RouteConstants.allTreesPath);
                      },
                      child: const Text('Go to all trees page'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              
              // NFTs section - takes remaining space
              Expanded(
                child: walletProvider.isConnected
                    ? UserNftsWidget(
                        isOwnerCalling: true,
                        userAddress: walletProvider.currentAddress.toString(),
                      )
                    : _buildWalletNotConnectedWidget(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWalletNotConnectedWidget(BuildContext context) {
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
}