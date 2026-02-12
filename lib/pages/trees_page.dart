import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/widgets/nft_display_utils/recent_trees_widget.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/pages/nearby_trees_map_page.dart';

class AllTreesPage extends StatefulWidget {
  const AllTreesPage({super.key});

  @override
  State<AllTreesPage> createState() => _AllTreesPageState();
}

class _AllTreesPageState extends State<AllTreesPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return BaseScaffold(
          title: "All Trees",
          body: walletProvider.isConnected
              ? _buildTreesPageContent(context)
              : _buildConnectWalletPrompt(context),
        );
      },
    );
  }

  Widget _buildTreesPageContent(BuildContext context) {
    return Column(
      children: [
        // Header with Mint NFT Button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.eco,
                size: 28,
                color: getThemeColors(context)['primary'],
              ),
              const SizedBox(width: 8),
              Text(
                'Discover Trees',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: getThemeColors(context)['textPrimary'],
                ),
              ),
              const Spacer(),
              // Map button for nearby trees
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NearbyTreesMapPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.map, size: 20),
                label: const Text(
                  'Map',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                  ),
                  side: const BorderSide(color: Colors.black, width: 2),
                  elevation: buttonBlurRadius,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Mint NFT button
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/mint-nft');
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Mint NFT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: getThemeColors(context)['primary'],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                  ),
                  side: const BorderSide(color: Colors.black, width: 2),
                  elevation: buttonBlurRadius,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Recent Trees Widget
        const Expanded(
          child: RecentTreesWidget(),
        ),
      ],
    );
  }

  Widget _buildConnectWalletPrompt(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: getThemeColors(context)['background'],
          borderRadius: BorderRadius.circular(buttonCircularRadius),
          border: Border.all(
            color: getThemeColors(context)['border']!,
            width: buttonborderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: buttonBlurRadius,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: getThemeColors(context)['primary'],
            ),
            const SizedBox(height: 24),
            Text(
              'Connect Your Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: getThemeColors(context)['textPrimary'],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To view recent trees and interact with the blockchain, you need to connect your wallet first.',
              style: TextStyle(
                fontSize: 16,
                color: getThemeColors(context)['textPrimary'],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final walletProvider = Provider.of<WalletProvider>(
                  context,
                  listen: false,
                );
                try {
                  await walletProvider.connectWallet();
                  if (!mounted) return;
                  if (walletProvider.isConnected) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Wallet connected successfully!'),
                        // ignore: use_build_context_synchronously
                        backgroundColor: getThemeColors(context)['primary'],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to connect wallet: $e'),
                      // ignore: use_build_context_synchronously
                      backgroundColor: getThemeColors(context)['error'],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text(
                'Connect Wallet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: getThemeColors(context)['primary'],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonCircularRadius),
                ),
                side: const BorderSide(color: Colors.black, width: 2),
                elevation: buttonBlurRadius,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: getThemeColors(context)['secondary'],
                ),
                const SizedBox(width: 8),
                Text(
                  'Supported wallets: MetaMask, WalletConnect',
                  style: TextStyle(
                    fontSize: 12,
                    color: getThemeColors(context)['textPrimary'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
