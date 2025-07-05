// models/wallet_option.dart
import 'package:flutter/material.dart';

class WalletOption {
  final String name;
  final String deepLink;
  final String? fallbackUrl;
  final IconData icon;
  final Color color;

  WalletOption({
    required this.name,
    required this.deepLink,
    this.fallbackUrl,
    required this.icon,
    required this.color,
  });
}