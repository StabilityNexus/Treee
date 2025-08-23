import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String alchemyApiKey = dotenv.env['ALCHEMY_API_KEY'] ?? '';

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

final List<WalletOption> walletOptionsList = [
  WalletOption(
    name: 'MetaMask',
    deepLink: 'metamask://wc?uri=',
    fallbackUrl: 'https://metamask.app.link/wc?uri=',
    icon: Icons.account_balance_wallet,
    color: Colors.orange,
  ),
];

final Map<String, String> rpcUrls = {
  '11155111': 'https://eth-sepolia.g.alchemy.com/v2/$alchemyApiKey',
  '1': 'https://eth-mainnet.g.alchemy.com/v2/$alchemyApiKey',
};

final Map<String, Map<String, dynamic>> chainInfoList = {
  '1': {
    'name': 'Ethereum Mainnet',
    'rpcUrl': 'https://eth-mainnet.g.alchemy.com/v2/$alchemyApiKey',
    'nativeCurrency': {
      'name': 'Ether',
      'symbol': 'ETH',
      'decimals': 18,
    },
    'blockExplorerUrl': 'https://etherscan.io',
  },
  '11155111': {
    'name': 'Sepolia Testnet',
    'rpcUrl': 'https://eth-sepolia.g.alchemy.com/v2/$alchemyApiKey',
    'nativeCurrency': {
      'name': 'Sepolia Ether',
      'symbol': 'SEP',
      'decimals': 18,
    },
    'blockExplorerUrl': 'https://sepolia.etherscan.io',
  },
};
