import 'package:flutter/material.dart';


class UserNftsWidget extends StatefulWidget {
  const UserNftsWidget({Key? key, required bool isOwnerCalling, required String userAddress})  : super(key: key);

  @override
  State<UserNftsWidget> createState() => _UserNftsWidgetState();
}

class _UserNftsWidgetState extends State<UserNftsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Your NFTs"
          )
        ],
      )
    );
  }
}