import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/utils/services/switch_chain_utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
        title: "Settings",
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<WalletProvider>(
              builder: (ctx, walletProvider, __) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'User Address: ${walletProvider.userAddress}',
                  ),
                  Text(
                    'Current Chain: ${walletProvider.currentChainName} (${walletProvider.currentChainId})',
                    style: const TextStyle(fontSize: 20),
                  ),
                  ElevatedButton(
                    onPressed: () => showChainSelector(context, walletProvider),
                    child: const Text('Switch Chain'),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
