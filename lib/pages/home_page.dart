import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';

import 'package:tree_planting_protocol/utils/constants/navbar_constants.dart';
import 'package:tree_planting_protocol/utils/constants/route_constants.dart';

import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/profile_section_widget.dart';
import 'package:tree_planting_protocol/widgets/user_nfts_widget.dart';
import 'package:tree_planting_protocol/widgets/wallet_not_connected_widget.dart';

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
              SizedBox(
                width: 400,
                height: 400, 
                child: ProfileSectionWidget()
              ),
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
              // r
            ],
          );
        },
      ),
    );
  }
}
