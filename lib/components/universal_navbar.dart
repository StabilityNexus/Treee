import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/providers/theme_provider.dart';
import 'package:tree_planting_protocol/components/wallet_connect_dialog.dart';
import 'package:tree_planting_protocol/utils/services/wallet_provider_utils.dart';
import 'package:tree_planting_protocol/utils/constants/tree_images.dart';
import 'package:tree_planting_protocol/utils/services/switch_chain_utils.dart';

class UniversalNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;

  const UniversalNavbar({super.key, this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(120.0);
  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? const Color.fromARGB(255, 1, 135, 12)
            : const Color.fromARGB(255, 28, 211, 129),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: _buildPlantIllustrations(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          child: Image.asset(
                            'assets/tree-navbar-images/logo.png', // Fixed path to match your folder structure
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.eco,
                                color: Colors.green[600],
                                size: 28,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (title != null)
                          Flexible(
                            child: Text(
                              title!,
                              style: const TextStyle(
                                color: Color.fromARGB(251, 179, 249, 2),
                                fontSize: 30,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Container(
                        //   width: 36,
                        //   height: 36,
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withOpacity(0.2),
                        //     borderRadius: BorderRadius.circular(8),
                        //     border: Border.all(
                        //       color: Colors.white.withOpacity(0.3),
                        //       width: 1,
                        //     ),
                        //   ),
                        //   child: IconButton(
                        //     padding: EdgeInsets.zero,
                        //     icon: Icon(
                        //       themeProvider.isDarkMode
                        //           ? Icons.light_mode
                        //           : Icons.dark_mode,
                        //       color: Colors.white,
                        //       size: 18,
                        //     ),
                        //     onPressed: () {
                        //       themeProvider.toggleTheme();
                        //     },
                        //     tooltip: themeProvider.isDarkMode
                        //         ? 'Switch to Light Mode'
                        //         : 'Switch to Dark Mode',
                        //   ),
                        // ),
                        const SizedBox(width: 6),
                        if (actions != null) ...actions!,
                        if (walletProvider.isConnected &&
                            walletProvider.currentAddress != null)
                          _buildWalletMenu(context, walletProvider)
                        else
                          _buildConnectButton(context, walletProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantIllustrations() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 251, 251, 99),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final plantWidth = 35.0;
            final plantSpacing = 0.0;
            final totalPlantWidth = plantWidth + plantSpacing;
            final visiblePlantCount =
                (availableWidth / totalPlantWidth).floor();

            if (visiblePlantCount >= treeImages.length) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: treeImages.map((imagePath) {
                    return SizedBox(
                      width: plantWidth,
                      height: plantWidth,
                      child: Image.asset(
                        'assets/tree-navbar-images/$imagePath', // Fixed: consistent path
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.eco,
                            color: Colors.green[600],
                            size: 28,
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: treeImages.map((imagePath) {
                  return Container(
                    width: plantWidth,
                    height: plantWidth,
                    margin: EdgeInsets.zero,
                    child: Image.asset(
                      'assets/tree-navbar-images/$imagePath', // Fixed: consistent path
                      width: 35,
                      height: 35,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.eco,
                          color: Colors.green[600],
                          size: 28,
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWalletMenu(BuildContext context, WalletProvider walletProvider) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100, minHeight: 20),
      // Limit max width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 14,
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 10,
                child: Flexible(
                  child: Text(
                    formatAddress(walletProvider.currentAddress!),
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 14,
                color: Colors.green[700],
              ),
            ],
          ),
        ),
        onSelected: (value) async {
          if (value == 'disconnect') {
            await walletProvider.disconnectWallet();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Wallet disconnected'),
                  backgroundColor: Colors.green[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          } else if (value == 'copy') {
            await Clipboard.setData(
              ClipboardData(text: walletProvider.currentAddress!),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Address copied to clipboard'),
                  backgroundColor: Colors.blue[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          } else if (value == 'Switch Chain') {
            showChainSelector(context, walletProvider);
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem<String>(
            value: 'copy',
            child: ListTile(
              leading: Icon(Icons.copy, size: 20),
              title: Text('Copy Address'),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'Switch Chain',
            child: ListTile(
              leading: Icon(Icons.switch_access_shortcut,
                  color: Colors.green, size: 20),
              title: Text(
                'Switch Chain',
                style: TextStyle(color: Colors.green),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'disconnect',
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red, size: 20),
              title: Text(
                'Disconnect',
                style: TextStyle(color: Colors.red),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton(
      BuildContext context, WalletProvider walletProvider) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 80), // Limit max width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final uri = await walletProvider.connectWallet();
            if (uri != null && context.mounted) {
              showDialog(
                context: context,
                builder: (context) => WalletConnectDialog(uri: uri),
              );
            }
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Connect',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
