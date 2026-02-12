import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';

import 'package:tree_planting_protocol/utils/constants/navbar_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';

import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/profile_widgets/profile_section_widget.dart';
import 'package:tree_planting_protocol/widgets/nft_display_utils/user_nfts_widget.dart';
import 'package:tree_planting_protocol/widgets/map_widgets/nearby_trees_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: appName,
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                    width: 400,
                    child: ProfileSectionWidget(
                      userAddress: walletProvider.currentAddress ?? '',
                    )),
                
                // Quick Actions Section
                if (walletProvider.isConnected) ...[
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 16),
                  // Nearby Trees Section
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 500),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: getThemeColors(context)['background'],
                      borderRadius: BorderRadius.circular(buttonCircularRadius),
                      border: Border.all(
                        color: getThemeColors(context)['border']!,
                        width: 1,
                      ),
                    ),
                    child: const NearbyTreesWidget(
                      radiusMeters: 10000,
                      maxTrees: 8,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  height: 600,
                  child: UserNftsWidget(
                      isOwnerCalling: true,
                      userAddress: walletProvider.currentAddress ?? ''),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.map,
              label: 'Explore Map',
              onTap: () => context.push('/explore-map'),
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.forest,
              label: 'All Trees',
              onTap: () => context.push('/trees'),
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary
          ? getThemeColors(context)['primary']
          : getThemeColors(context)['secondary'],
      borderRadius: BorderRadius.circular(buttonCircularRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(buttonCircularRadius),
            border: Border.all(
              color: getThemeColors(context)['border']!,
              width: buttonborderWidth,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary
                    ? Colors.white
                    : getThemeColors(context)['textPrimary'],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPrimary
                      ? Colors.white
                      : getThemeColors(context)['textPrimary'],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
