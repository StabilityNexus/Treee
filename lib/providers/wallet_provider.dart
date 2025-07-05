import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:tree_planting_protocol/models/wallet_option.dart';

class WalletProvider extends ChangeNotifier {
  Web3App? _web3App;
  String? _currentAddress;
  bool _isConnected = false;
  bool _isInitialized = false;
  bool _isConnecting = false;
  String _statusMessage = 'Initializing...';
  ConnectResponse? _pendingConnection; // Add this to track pending connection
  String? get currentAddress => _currentAddress;
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  bool get isConnecting => _isConnecting;
  String get statusMessage => _statusMessage;

  final List<WalletOption> _walletOptions = [
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

  List<WalletOption> get walletOptions => _walletOptions;

  WalletProvider() {
    _initializeWalletConnect();
  }

  Future<void> _initializeWalletConnect() async {
    try {
      _updateStatus('Initializing WalletConnect...');

      _web3App = Web3App(
        core: Core(
          projectId: 'bae2d46d706b0bfd76087f472ffec96d',
        ),
        metadata: const PairingMetadata(
          name: 'Sample Flutter App',
          description: 'Sample Flutter App with WalletConnect',
          url: 'https://walletconnect.com/',
          icons: ['https://walletconnect.com/walletconnect-logo.png'],
        ),
      );

      await _web3App!.init();

      // Set up session event listeners
      _web3App!.onSessionConnect.subscribe(_onSessionConnect);
      _web3App!.onSessionDelete.subscribe(_onSessionDelete);

      final sessions = _web3App!.sessions.getAll();
      if (sessions.isNotEmpty) {
        final session = sessions.first;
        final accounts = session.namespaces['eip155']?.accounts;
        if (accounts != null && accounts.isNotEmpty) {
          _updateConnection(
            isConnected: true,
            address: accounts.first.split(':').last,
            message: 'Connected to existing session',
          );
        }
      }

      _updateStatus('Ready to connect');
      _isInitialized = true;
      notifyListeners();

      print('WalletConnect initialized successfully');
    } catch (e) {
      print('Error initializing WalletConnect: $e');
      _updateStatus('Initialization failed: ${e.toString()}');
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _onSessionConnect(SessionConnect? event) {
    if (event != null) {
      final accounts = event.session.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        _updateConnection(
          isConnected: true,
          address: accounts.first.split(':').last,
          message: 'Connected successfully',
        );
        print('Session connected: ${event.session.topic}');
      }
    }
  }

  void _onSessionDelete(SessionDelete? event) {
    if (event != null) {
      _updateConnection(
        isConnected: false,
        address: null,
        message: 'Session disconnected',
      );
      print('Session deleted: ${event.topic}');
    }
  }

  Future<String?> connectWallet() async {
    if (!_isInitialized || _isConnecting) return null;

    _updateStatus('Creating connection...');
    _isConnecting = true;
    notifyListeners();

    try {
      final ConnectResponse connectResponse = await _web3App!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:1', 'eip155:137'],
            methods: [
              'eth_sendTransaction',
              'eth_signTransaction',
              'eth_sign',
              'personal_sign',
              'eth_signTypedData',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
        optionalNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:56', 'eip155:43114'],
            methods: [
              'eth_sendTransaction',
              'eth_signTransaction',
              'eth_sign',
              'personal_sign',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      _pendingConnection = connectResponse; 

      final Uri? uri = connectResponse.uri;
      if (uri != null) {
        print('WalletConnect URI: $uri');
        _updateStatus('Waiting for wallet approval...');
        _listenForSession();
        
        return uri.toString();
      } else {
        _updateStatus('Failed to generate connection URI');
      }
    } catch (e) {
      print('Error connecting wallet: $e');
      _updateStatus('Connection failed: ${e.toString()}');
      _isConnecting = false;
      notifyListeners();
      throw Exception('Failed to connect wallet: $e');
    }
    return null;
  }
  void _listenForSession() async {
    if (_pendingConnection == null) return;

    try {
      _updateStatus('Waiting for wallet approval...');
      
      // Wait for the session with a timeout
      final SessionData session = await _pendingConnection!.session.future
          .timeout(const Duration(minutes: 2));

      final accounts = session.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        _updateConnection(
          isConnected: true,
          address: accounts.first.split(':').last,
          message: 'Connected successfully',
        );
        print('Session established successfully');
      }
    } catch (e) {
      print('Session timeout or error: $e');
      if (e.toString().contains('TimeoutException')) {
        _updateStatus('Connection timeout - please try again');
      } else {
        _updateStatus('Connection cancelled or failed');
      }
      _isConnecting = false;
      notifyListeners();
    } finally {
      _pendingConnection = null;
    }
  }

  Future<void> openWallet(WalletOption wallet, String uri) async {
    try {
      final String encodedUri = Uri.encodeComponent(uri);
      final String deepLinkUrl = '${wallet.deepLink}$encodedUri';
      final Uri deepLink = Uri.parse(deepLinkUrl);

      print('Attempting to open: $deepLinkUrl');

      bool launched = false;

      if (await canLaunchUrl(deepLink)) {
        launched = await launchUrl(
          deepLink,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched && wallet.fallbackUrl != null) {
        final String fallbackUrl = '${wallet.fallbackUrl}$encodedUri';
        final Uri fallbackUri = Uri.parse(fallbackUrl);

        print('Deep link failed, trying fallback: $fallbackUrl');

        if (await canLaunchUrl(fallbackUri)) {
          launched = await launchUrl(
            fallbackUri,
            mode: LaunchMode.externalApplication,
          );
        }
      }

      if (!launched) {
        await Clipboard.setData(ClipboardData(text: uri));
        throw Exception(
          '${wallet.name} app not found. URI copied to clipboard.',
        );
      } else {
        _updateStatus('Opened ${wallet.name}, please approve in the app...');
      }
    } catch (e) {
      print('Error opening wallet: $e');
      try {
        await Clipboard.setData(ClipboardData(text: uri));
        throw Exception(
          'Failed to open ${wallet.name}. URI copied to clipboard.',
        );
      } catch (clipboardError) {
        throw Exception('Failed to open ${wallet.name}: $e');
      }
    }
  }

  Future<void> disconnectWallet() async {
    if (!_isConnected) return;

    try {
      final sessions = _web3App!.sessions.getAll();
      if (sessions.isNotEmpty) {
        final session = sessions.first;
        await _web3App!.disconnectSession(
          topic: session.topic,
          reason: const WalletConnectError(
            code: 6000,
            message: 'User disconnected',
          ),
        );
      }

      _updateConnection(
        isConnected: false,
        address: null,
        message: 'Disconnected',
      );
    } catch (e) {
      print('Error disconnecting wallet: $e');
      throw Exception('Failed to disconnect wallet: $e');
    }
  }

  String formatAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _updateConnection({
    required bool isConnected,
    String? address,
    required String message,
  }) {
    _isConnected = isConnected;
    _currentAddress = address;
    _statusMessage = message;
    _isConnecting = false;
    notifyListeners();
  }

  void _updateStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up event listeners
    _web3App?.onSessionConnect.unsubscribe(_onSessionConnect);
    _web3App?.onSessionDelete.unsubscribe(_onSessionDelete);
    super.dispose();
  }
}