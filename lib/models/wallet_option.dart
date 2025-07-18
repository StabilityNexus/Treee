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

 final List<WalletOption> walletOptionsList = [
    WalletOption(
      name: 'MetaMask',
      deepLink: 'metamask://wc?uri=',
      fallbackUrl: 'https://metamask.app.link/wc?uri=',
      icon: Icons.account_balance_wallet,
      color: Colors.orange,
    ),
    WalletOption(
      name: 'Trust Wallet',
      deepLink: 'trust://wc?uri=',
      fallbackUrl: 'https://link.trustwallet.com/wc?uri=',
      icon: Icons.security,
      color: Colors.blue,
    ),
    WalletOption(
      name: 'Rainbow',
      deepLink: 'rainbow://wc?uri=',
      fallbackUrl: 'https://rnbwapp.com/wc?uri=',
      icon: Icons.colorize,
      color: Colors.purple,
    ),
    WalletOption(
      name: 'Coinbase Wallet',
      deepLink: 'cbwallet://wc?uri=',
      fallbackUrl: 'https://go.cb-w.com/wc?uri=',
      icon: Icons.currency_bitcoin,
      color: Colors.blue.shade700,
    ),
  ];


  final Map<String, String> rpcUrls = {
    '11155111':
        'https://eth-sepolia.g.alchemy.com/v2/ghiIjYuaumHfkffONpzBEItpKXWt9952',
    '1': 'https://eth-mainnet.g.alchemy.com/v2/ghiIjYuaumHfkffONpzBEItpKXWt9952',
  };


  final Map<String, Map<String, dynamic>> chainInfoList = {
    '1': {
      'name': 'Ethereum Mainnet',
      'rpcUrl': 'https://mainnet.infura.io/v3/YOUR_INFURA_KEY',
      'nativeCurrency': {
        'name': 'Ether',
        'symbol': 'ETH',
        'decimals': 18,
      },
      'blockExplorerUrl': 'https://etherscan.io',
    },
    '11155111': {
      'name': 'Sepolia Testnet',
      'rpcUrl':
          'https://eth-sepolia.g.alchemy.com/v2/ghiIjYuaumHfkffONpzBEItpKXWt9952',
      'nativeCurrency': {
        'name': 'Sepolia Ether',
        'symbol': 'SEP',
        'decimals': 18,
      },
      'blockExplorerUrl': 'https://sepolia.etherscan.io',
    },
    '56': {
      'name': 'BNB Smart Chain',
      'rpcUrl': 'https://bsc-dataseed.binance.org',
      'nativeCurrency': {
        'name': 'BNB',
        'symbol': 'BNB',
        'decimals': 18,
      },
      'blockExplorerUrl': 'https://bscscan.com',
    },
    '137': {
      'name': 'Polygon',
      'rpcUrl': 'https://polygon-rpc.com',
      'nativeCurrency': {
        'name': 'MATIC',
        'symbol': 'MATIC',
        'decimals': 18,
      },
      'blockExplorerUrl': 'https://polygonscan.com',
    },
    '43114': {
      'name': 'Avalanche C-Chain',
      'rpcUrl': 'https://api.avax.network/ext/bc/C/rpc',
      'nativeCurrency': {
        'name': 'AVAX',
        'symbol': 'AVAX',
        'decimals': 18,
      },
      'blockExplorerUrl': 'https://snowtrace.io',
    },
  };
