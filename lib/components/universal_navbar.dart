import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/providers/theme_provider.dart';
import 'package:tree_planting_protocol/components/wallet_connect_dialog.dart';

class UniversalNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;

  const UniversalNavbar({super.key, this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      title: Text(title ?? ''),
      actions: [
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode 
                ? Icons.light_mode 
                : Icons.dark_mode,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
          tooltip: themeProvider.isDarkMode 
              ? 'Switch to Light Mode' 
              : 'Switch to Dark Mode',
        ),
        
        ...?actions,
        
        if (walletProvider.isConnected && walletProvider.currentAddress != null)
          PopupMenuButton<String>(
            icon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.green[800]
                    : Colors.green[50],
                label: Text(
                  walletProvider.formatAddress(walletProvider.currentAddress!),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[200]
                        : Colors.green[800],
                  ),
                ),
                avatar: Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[200]
                      : Colors.green,
                ),
              ),
            ),
            onSelected: (value) async {
              if (value == 'disconnect') {
                await walletProvider.disconnectWallet();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wallet disconnected'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (value == 'copy') {
                await Clipboard.setData(
                  ClipboardData(text: walletProvider.currentAddress!),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address copied to clipboard'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'copy',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy Address'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'disconnect',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Disconnect',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          )
        else
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () async {
              final uri = await walletProvider.connectWallet();
              if (uri != null && context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => WalletConnectDialog(uri: uri),
                );
              }
            },
            tooltip: 'Connect Wallet',
          ),
      ],
    );
  }
}