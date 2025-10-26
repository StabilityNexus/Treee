import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';

void copyAddress(String address, BuildContext context) {
  Clipboard.setData(ClipboardData(text: address));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Address copied to clipboard'),
      backgroundColor: getThemeColors(context)['primary'],
      duration: Duration(seconds: 2),
    ),
  );
}
