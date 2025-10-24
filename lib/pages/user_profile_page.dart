import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';

import 'package:tree_planting_protocol/utils/constants/navbar_constants.dart';

import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/profile_widgets/profile_section_widget.dart';
import 'package:tree_planting_protocol/widgets/nft_display_utils/user_nfts_widget.dart';

class UserProfilePage extends StatelessWidget {
  final String userAddress;

  const UserProfilePage({super.key, required this.userAddress});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: appName,
      showBackButton: true,
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                    width: 400,
                    child: ProfileSectionWidget(userAddress: userAddress)),
                SizedBox(
                  width: 400,
                  height: 600,
                  child: UserNftsWidget(
                      isOwnerCalling: true, userAddress: userAddress),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
