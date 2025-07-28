import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/mint_nft_provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/widgets/tree_nft_view_details_with_map.dart';



class SubmitNFTPage extends StatefulWidget {
  const SubmitNFTPage({super.key});

  @override
  State<SubmitNFTPage> createState() => _SubmitNFTPageState();
}

class _SubmitNFTPageState extends State<SubmitNFTPage> {
  @override
  Widget build(BuildContext context) {
    return const BaseScaffold(
      title: "Submit NFT",
      body: NewNFTMapWidget()
    );
  }
}