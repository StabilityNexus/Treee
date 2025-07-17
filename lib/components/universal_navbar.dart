import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/providers/theme_provider.dart';
import 'package:tree_planting_protocol/components/wallet_connect_dialog.dart';
import 'package:tree_planting_protocol/utils/services/wallet_provider_utils.dart';

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
        // Theme toggle button
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
        
        // Chain selector (only show when connected)
        if (walletProvider.isConnected)
          _buildChainSelector(context, walletProvider),
        
        ...?actions,
        
        // Wallet connection/menu
        if (walletProvider.isConnected && walletProvider.currentAddress != null)
          _buildWalletMenu(context, walletProvider)
        else
          _buildConnectButton(context, walletProvider),
      ],
    );
  }

  Widget _buildChainSelector(BuildContext context, WalletProvider walletProvider) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.blue[800]
              : Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.blue[600]!
                : Colors.blue[200]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[200]
                  : Colors.blue[700],
            ),
            const SizedBox(width: 4),
            Text(
              _getChainDisplayName(walletProvider.currentChainName),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue[200]
                    : Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[200]
                  : Colors.blue[700],
            ),
          ],
        ),
      ),
      tooltip: 'Switch Network',
      onSelected: (chainId) async {
        if (chainId != walletProvider.currentChainId) {
          await _switchChain(context, walletProvider, chainId);
        }
      },
      itemBuilder: (BuildContext context) {
        final supportedChains = walletProvider.getSupportedChains();
        return supportedChains.map((chain) {
          final isCurrentChain = chain['isCurrentChain'] as bool;
          return PopupMenuItem<String>(
            value: chain['chainId'] as String,
            child: Row(
              children: [
                Icon(
                  _getChainIcon(chain['chainId'] as String),
                  size: 20,
                  color: isCurrentChain 
                      ? Colors.green 
                      : Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chain['name'] as String,
                        style: TextStyle(
                          fontWeight: isCurrentChain 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: isCurrentChain 
                              ? Colors.green 
                              : null,
                        ),
                      ),
                      Text(
                        '${chain['nativeCurrency']['symbol']} Network',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentChain)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildWalletMenu(BuildContext context, WalletProvider walletProvider) {
    return PopupMenuButton<String>(
      icon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Chip(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.green[800]
              : Colors.green[50],
          label: Text(
            formatAddress(walletProvider.currentAddress!),
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
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wallet disconnected'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (value == 'copy') {
          await Clipboard.setData(
            ClipboardData(text: walletProvider.currentAddress!),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address copied to clipboard'),
                backgroundColor: Colors.blue,
              ),
            );
          }
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
    );
  }

  Widget _buildConnectButton(BuildContext context, WalletProvider walletProvider) {
    return IconButton(
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
    );
  }

  Future<void> _switchChain(BuildContext context, WalletProvider walletProvider, String chainId) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Switching to ${walletProvider.chainInfo[chainId]?['name'] ?? 'Unknown Chain'}...'),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Perform chain switch
      final success = await walletProvider.switchChain(chainId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (success) {
          // Refresh chain info to make sure we have the latest
          await walletProvider.refreshChainInfo();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to ${walletProvider.currentChainName}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chain switch was cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Chain switch error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        String errorMessage = 'Failed to switch chain';
        if (e.toString().contains('not supported')) {
          errorMessage = 'Chain switching not supported by this wallet';
        } else if (e.toString().contains('User rejected')) {
          errorMessage = 'Chain switch cancelled by user';
        } else if (e.toString().contains('4902')) {
          errorMessage = 'Chain not found in wallet. Try adding it manually.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _switchChain(context, walletProvider, chainId),
            ),
          ),
        );
      }
    }
  }

  String _getChainDisplayName(String chainName) {
    // Shorten chain names for display
    switch (chainName) {
      case 'Ethereum Mainnet':
        return 'ETH';
      case 'Sepolia Testnet':
        return 'SEP';
      case 'BNB Smart Chain':
        return 'BSC';
      case 'Polygon':
        return 'MATIC';
      case 'Avalanche C-Chain':
        return 'AVAX';
      default:
        return chainName.length > 6 ? chainName.substring(0, 6) : chainName;
    }
  }

  IconData _getChainIcon(String chainId) {
    switch (chainId) {
      case '1':
        return Icons.diamond; // Ethereum
      case '11155111':
        return Icons.science; // Sepolia (testnet)
      case '56':
        return Icons.speed; // BSC
      case '137':
        return Icons.polyline; // Polygon
      case '43114':
        return Icons.ac_unit; // Avalanche
      default:
        return Icons.link;
    }
  }
}