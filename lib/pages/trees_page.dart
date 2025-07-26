import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/utils/constants/navbar_constants.dart';

class AllTreesPage extends StatelessWidget {
  const AllTreesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: appName,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => context.push('/mint-nft'),
            child: const Text(
              'Mint NFT',
              textAlign: TextAlign.center,
            ),

          ),
          Text(
            'This is the All Trees Page',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ],
      )
    );
  }
}