import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';

import 'package:tree_planting_protocol/utils/constants/navbar_constants.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';

import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/profile_widgets/profile_section_widget.dart';
import 'package:tree_planting_protocol/widgets/nft_display_utils/user_nfts_widget.dart';

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
                SizedBox(width: 400, child: ProfileSectionWidget()),
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
}
