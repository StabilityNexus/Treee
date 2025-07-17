import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:tree_planting_protocol/models/wallet_option.dart';
import 'package:http/http.dart' as http;
import 'package:tree_planting_protocol/utils/services/wallet_provider_utils.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum InitializationState {
  notStarted,
  initializing,
  initialized,
  failed,
}

class WalletProvider extends ChangeNotifier {
  Web3App? _web3App;
  String? _currentAddress;
  bool _isConnected = false;
  bool _isConnecting = false;
  InitializationState _initializationState = InitializationState.notStarted;
  String _statusMessage = 'Initializing...';
  String? _currentChainId;
  final Map<String, String> _rpcUrls = rpcUrls;

  static const String _defaultChainId = '11155111';

  String? get currentAddress => _currentAddress;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get statusMessage => _statusMessage;
  String? get currentChainId => _currentChainId;
  List<WalletOption> get walletOptions => walletOptionsList;
  InitializationState get initializationState => _initializationState;

  WalletProvider() {
    _initializeWeb3App();
  }

  Future<void> _initializeWeb3App() async {
    try {
      _updateStatus('Initializing Web3App...');

      _web3App = await Web3App.createInstance(
        projectId: dotenv.env['WALLETCONNECT_PROJECT_ID'] ?? '',
        metadata: const PairingMetadata(
          name: 'Tree Planting Protocol',
          description: 'Tokenise Tree plantations on blockchain',
          url: 'https://walletconnect.com/',
          icons: ['https://walletconnect.com/walletconnect-logo.png'],
        ),
      );

      _web3App!.onSessionConnect.subscribe(_onSessionConnect);
      _web3App!.onSessionDelete.subscribe(_onSessionDelete);
      _web3App!.onSessionUpdate.subscribe(_onSessionUpdate);
      _web3App!.onSessionEvent.subscribe(_onSessionEvent);

      final sessions = _web3App!.sessions.getAll();
      if (sessions.isNotEmpty) {
        final session = sessions.first;
        final accounts = session.namespaces['eip155']?.accounts;
        if (accounts != null && accounts.isNotEmpty) {
          final accountData = accounts.first.split(':');
          _updateConnection(
            isConnected: true,
            address: accountData.last,
            chainId: accountData[1],
            message: 'Connected to existing session',
          );
        }
      }

      _updateStatus('Ready to connect');
      _initializationState = InitializationState.initialized;
      notifyListeners();
    } catch (e) {
      _updateStatus('Initialization failed: ${e.toString()}');
      _initializationState = InitializationState.failed;
      notifyListeners();
    }
  }

  void _onSessionConnect(SessionConnect? event) {
    if (event != null) {
      final accounts = event.session.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        final accountData = accounts.first.split(':');
        _updateConnection(
          isConnected: true,
          address: accountData.last,
          chainId: accountData[1],
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
        chainId: null,
        message: 'Session disconnected',
      );
    }
  }

  void _onSessionEvent(SessionEvent? event) {
    if (event != null) {
      print('Session event: ${event.name}, data: ${event.data}');

      if (event.name == 'chainChanged') {
        final newChainId = event.data.toString();
        String chainId = newChainId.startsWith('0x')
            ? int.parse(newChainId.substring(2), radix: 16).toString()
            : newChainId;

        if (_currentChainId != chainId) {
          _currentChainId = chainId;
          _updateStatus('Chain changed to ${currentChainName}');
          notifyListeners();
        }
      }

      if (event.name == 'accountsChanged') {
        final accounts = event.data as List<dynamic>?;
        if (accounts != null && accounts.isNotEmpty) {
          final newAddress = accounts.first.toString();
          if (_currentAddress != newAddress) {
            _currentAddress = newAddress;
            _updateStatus('Account changed');
            notifyListeners();
          }
        }
      }
    }
  }

  String get currentChainName {
    if (_currentChainId != null && _chainInfo.containsKey(_currentChainId)) {
      return _chainInfo[_currentChainId]!['name'];
    }
    return 'Unknown Chain';
  }

  void _onSessionUpdate(SessionUpdate? event) {
    if (event != null) {
      final sessions = _web3App!.sessions.getAll();
      final session = sessions.firstWhere(
        (s) => s.topic == event.topic,
        orElse: () => throw Exception('Session not found'),
      );

      final accounts = session.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        final accountData = accounts.first.split(':');
        _updateConnection(
          isConnected: true,
          address: accountData.last,
          chainId: accountData[1],
          message: 'Session updated',
        );
      }
    }
  }

  Future<String?> connectWallet() async {
    if (_initializationState != InitializationState.initialized ||
        _isConnecting) return null;

    _updateStatus('Creating connection...');
    _isConnecting = true;
    notifyListeners();

    try {
      final ConnectResponse connectResponse = await _web3App!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:11155111'], // Sepolia and mainnet
            methods: [
              'eth_sendTransaction',
              'eth_signTransaction',
              'eth_sign',
              'personal_sign',
              'eth_signTypedData',
              'eth_call',
              'eth_getBalance',
              'eth_getTransactionCount',
              'eth_getTransactionReceipt',
              'eth_estimateGas',
              'wallet_switchEthereumChain',
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
              'eth_call',
              'eth_getBalance',
              'wallet_switchEthereumChain',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      final Uri? uri = connectResponse.uri;
      if (uri != null) {
        _updateStatus('Waiting for wallet approval...');
        _listenForSession(connectResponse);
        return uri.toString();
      } else {
        _updateStatus('Failed to generate connection URI');
      }
    } catch (e) {
      _updateStatus('Connection failed: ${e.toString()}');
      _isConnecting = false;
      notifyListeners();
      throw Exception('Failed to connect wallet: $e');
    }
    return null;
  }

  Future<bool> switchToSepolia() async {
    return await switchChain(_defaultChainId);
  }

  bool get isConnectedToSepolia => _currentChainId == _defaultChainId;

  final Map<String, Map<String, dynamic>> _chainInfo = chainInfoList;
  Map<String, Map<String, dynamic>> get chainInfo => chainInfoList;
  Future<bool> switchChain(String chainId) async {
    if (!_isConnected) {
      throw Exception('Wallet not connected');
    }

    if (_currentChainId == chainId) {
      return true;
    }

    if (!_chainInfo.containsKey(chainId)) {
      throw Exception('Unsupported chain ID: $chainId');
    }

    try {
      _updateStatus('Switching to ${_chainInfo[chainId]!['name']}...');

      final sessions = _web3App!.sessions.getAll();
      if (sessions.isEmpty) {
        throw Exception('No active session found');
      }

      final session = sessions.first;
      final supportedMethods = session.namespaces['eip155']?.methods ?? [];

      if (!supportedMethods.contains('wallet_switchEthereumChain')) {
        throw Exception('Chain switching not supported by this wallet');
      }

      final hexChainId = '0x${int.parse(chainId).toRadixString(16)}';
      final currentSessionChainId = _getCurrentSessionChainId(session);

      await _web3App!.request(
        topic: session.topic,
        chainId: 'eip155:$currentSessionChainId',
        request: SessionRequestParams(
          method: 'wallet_switchEthereumChain',
          params: [
            {
              'chainId': hexChainId,
            }
          ],
        ),
      );
      await _waitForChainChange(chainId);
      _updateStatus('Switched to ${_chainInfo[chainId]!['name']}');
      return true;
    } catch (e) {
      String errorString = e.toString().toLowerCase();
      if (errorString.contains('4001') ||
          errorString.contains('user rejected') ||
          errorString.contains('user denied') ||
          errorString.contains('cancelled')) {
        _updateStatus('Chain switch cancelled by user');
        return false;
      }
      if (errorString.contains('4902') ||
          errorString.contains('unrecognized chain') ||
          errorString.contains('chain not found') ||
          errorString.contains('unknown chain')) {
        _updateStatus('Chain not found in wallet - please add it manually');
        throw Exception(
            'Chain not found in wallet. Please add ${_chainInfo[chainId]!['name']} manually in your wallet.');
      }

      _updateStatus('Failed to switch chain: ${e.toString()}');
      throw Exception('Failed to switch chain: $e');
    }
  }

  String _getCurrentSessionChainId(SessionData session) {
    final accounts = session.namespaces['eip155']?.accounts;
    if (accounts != null && accounts.isNotEmpty) {
      final accountData = accounts.first.split(':');
      return accountData[1];
    }
    return _currentChainId ?? '1';
  }

  Future<void> _waitForChainChange(String expectedChainId,
      {Duration timeout = const Duration(seconds: 10)}) async {
    final completer = Completer<void>();
    bool isListening = true;

    void handleChainChange(SessionEvent? event) {
      if (!isListening) return;

      if (event?.name == 'chainChanged') {
        final newChainId = event!.data.toString();
        final chainId = newChainId.startsWith('0x')
            ? int.parse(newChainId.substring(2), radix: 16).toString()
            : newChainId;

        if (chainId == expectedChainId) {
          isListening = false;
          _web3App!.onSessionEvent.unsubscribe(handleChainChange);
          completer.complete();
        }
      }
    }

    _web3App!.onSessionEvent.subscribe(handleChainChange);

    Timer(timeout, () {
      if (!completer.isCompleted) {
        isListening = false;
        _web3App!.onSessionEvent.unsubscribe(handleChainChange);
        completer.complete();
      }
    });

    await completer.future;
  }

  Future<void> refreshChainInfo() async {
    if (!_isConnected) return;

    try {
      final sessions = _web3App!.sessions.getAll();
      if (sessions.isNotEmpty) {
        final session = sessions.first;
        final accounts = session.namespaces['eip155']?.accounts;

        if (accounts != null && accounts.isNotEmpty) {
          final accountData = accounts.first.split(':');
          final chainId = accountData[1];

          if (_currentChainId != chainId) {
            _currentChainId = chainId;
            _updateStatus('Chain updated to ${currentChainName}');
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error refreshing chain info: $e');
    }
  }

  Future<String?> getCurrentChainFromWallet() async {
    if (!_isConnected) return null;

    try {
      final sessions = _web3App!.sessions.getAll();
      if (sessions.isEmpty) return null;

      final session = sessions.first;
      final currentSessionChainId = _getCurrentSessionChainId(session);

      final result = await _web3App!.request(
        topic: session.topic,
        chainId: 'eip155:$currentSessionChainId',
        request: SessionRequestParams(
          method: 'eth_chainId',
          params: [],
        ),
      );

      if (result != null) {
        final chainIdHex = result.toString();
        final chainId = chainIdHex.startsWith('0x')
            ? int.parse(chainIdHex.substring(2), radix: 16).toString()
            : chainIdHex;

        if (_currentChainId != chainId) {
          _currentChainId = chainId;
          notifyListeners();
        }

        return chainId;
      }
    } catch (e) {
      print('Error getting current chain from wallet: $e');
    }

    return _currentChainId;
  }

  List<Map<String, dynamic>> getSupportedChains() {
    return _chainInfo.entries.map((entry) {
      return {
        'chainId': entry.key,
        'name': entry.value['name'],
        'nativeCurrency': entry.value['nativeCurrency'],
        'isCurrentChain': entry.key == _currentChainId,
      };
    }).toList();
  }

  bool isChainSupported(String chainId) {
    return _chainInfo.containsKey(chainId);
  }

  void _listenForSession(ConnectResponse connectResponse) async {
    try {
      _updateStatus('Waiting for wallet approval...');

      final SessionData session = await connectResponse.session.future
          .timeout(const Duration(minutes: 2));

      final accounts = session.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        final accountData = accounts.first.split(':');
        _updateConnection(
          isConnected: true,
          address: accountData.last,
          chainId: accountData[1],
          message: 'Connected successfully',
        );
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _updateStatus('Connection timeout - please try again');
      } else {
        _updateStatus('Connection cancelled or failed');
      }
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> openWallet(WalletOption wallet, String uri) async {
    try {
      final String encodedUri = Uri.encodeComponent(uri);
      final String deepLinkUrl =
          '${wallet.deepLink}$encodedUri&redirect=treeplantingprotocol://';
      final Uri deepLink = Uri.parse(deepLinkUrl);
      bool launched = false;
      if (await canLaunchUrl(deepLink)) {
        launched = await launchUrl(
          deepLink,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched && wallet.fallbackUrl != null) {
        final String fallbackUrl =
            '${wallet.fallbackUrl}$encodedUri&redirect=treeplantingprotocol://';
        final Uri fallbackUri = Uri.parse(fallbackUrl);
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
        chainId: null,
        message: 'Disconnected',
      );
    } catch (e) {
      throw Exception('Failed to disconnect wallet: $e');
    }
  }

  void _updateConnection({
    required bool isConnected,
    String? address,
    String? chainId,
    required String message,
  }) {
    _isConnected = isConnected;
    _currentAddress = address;
    _currentChainId = chainId;
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
    _web3App?.onSessionConnect.unsubscribe(_onSessionConnect);
    _web3App?.onSessionDelete.unsubscribe(_onSessionDelete);
    _web3App?.onSessionUpdate.unsubscribe(_onSessionUpdate);
    _web3App?.onSessionEvent.unsubscribe(_onSessionEvent);
    super.dispose();
  }
}
