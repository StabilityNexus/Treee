import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:tree_planting_protocol/models/wallet_chain_option.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tree_planting_protocol/utils/logger.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

enum InitializationState {
  notStarted,
  initializing,
  initialized,
  failed,
}

class WalletProvider extends ChangeNotifier {
  static final String _correctChainId = "11155111";
  // dotenv.env['APPLICATION_CHAIN_ID'].toString();
  // ignore: deprecated_member_use
  Web3App? _web3App;
  bool _isConnected = false;
  bool _isConnecting = false;

  InitializationState _initializationState = InitializationState.notStarted;
  String? _currentAddress;
  String _statusMessage = 'Initializing...';
  String? _currentChainId;

  String? get currentAddress => _currentAddress;
  String get statusMessage => _statusMessage;
  String? get currentChainId => _currentChainId;
  String? get correctChainId => _correctChainId;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get g => _isConnecting;
  bool get isValidCurrentChain =>
      _currentChainId?.toString() == _correctChainId;

  List<WalletOption> get walletOptions => walletOptionsList;
  InitializationState get initializationState => _initializationState;

  WalletProvider() {
    _initializeWeb3App();
  }

  Future<void> _initializeWeb3App() async {
    try {
      _updateStatus('Initializing Web3App...');

      // ignore: deprecated_member_use
      _web3App = await Web3App.createInstance(
        projectId: dotenv.env['WALLETCONNECT_PROJECT_ID'] ?? '',
        metadata: const PairingMetadata(
          name: 'Tree Planting Protocol',
          description: 'Tokenise Tree plantations on blockchain',
          url: 'https://walletconnect.com/',
          icons: ['https://walletconnect.com/walletconnect-logo.png'],
          redirect: Redirect(
            native: 'treeplantingprotocol://',
            universal: 'https://treeplantingprotocol.com/callback',
          ),
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
        ('Session connected: ${event.session.topic}');
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
      logger.d('Session event: ${event.name}, data: ${event.data}');

      if (event.name == 'chainChanged') {
        final newChainId = event.data.toString();
        String chainId = newChainId.startsWith('0x')
            ? int.parse(newChainId.substring(2), radix: 16).toString()
            : newChainId;

        if (_currentChainId != chainId) {
          _currentChainId = chainId;
          _updateStatus('Chain changed to $currentChainName');
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

  Future<String?> forceReconnect() async {
    _updateStatus("Forcing reconnection...");
    _isConnected = false;
    _isConnecting = false;
    _currentAddress = null;
    _currentChainId = null;
    notifyListeners();

    try {
      await disconnectWallet();
      final uri = await connectWallet(); // Return the URI
      return uri;
    } catch (e) {
      _updateStatus("Force reconnect failed: ${e.toString()}");
      _isConnecting = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> connectWallet() async {
    if (_isConnected) {
      _updateStatus('Already connected.');
      throw Exception('Wallet is already connected.');
    }

    if (_isConnecting) {
      _updateStatus('Connection already in progress.');
      throw Exception('A connection attempt is already in progress.');
    }

    if (_initializationState != InitializationState.initialized) {
      throw Exception('Web3App is not initialized.');
    }
    _updateStatus('Creating connection...');
    _isConnecting = true;
    notifyListeners();

    try {
      final ConnectResponse connectResponse = await _web3App!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:11155111', 'eip155:1'],
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

  final Map<String, Map<String, dynamic>> _chainInfo = chainInfoList;
  Map<String, Map<String, dynamic>> get chainInfo => chainInfoList;

  get userAddress => null;

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

  List<Map<String, dynamic>> getChainDetails(String chainId) {
    if (!_chainInfo.containsKey(chainId)) {
      throw Exception('Unsupported chain ID: $chainId');
    }
    final chain = _chainInfo[chainId]!;
    return [
      {
        'name': chain['name'],
        'rpcUrl': chain['rpcUrl'],
        'nativeCurrency': chain['nativeCurrency'],
        'isCurrentChain': chainId == _currentChainId,
      },
    ];
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

  void getSupportedChainsWithStatus() async {
    if (!_isConnected) {
      throw Exception('Wallet not connected');
    }
  }

  // ignore: unused_element
  String _getCurrentSessionChainId() {
    final sessions = _web3App!.sessions.getAll();
    if (sessions.isEmpty) {
      throw Exception('No active WalletConnect session');
    }
    final accounts = sessions.first.namespaces['eip155']?.accounts;
    if (accounts != null && accounts.isNotEmpty) {
      return accounts.first.split(':')[1];
    }
    return '11155111'; // Default to Sepolia if no accounts found
  }

  Future<bool> switchChain(String newChainId) async {
    logger.d('[switchChain] Requested chain id: $newChainId');
    if (!_isConnected) {
      logger.e('[switchChain] Wallet not connected.');
      throw Exception('Wallet not connected');
    }

    if (_currentChainId == newChainId) {
      logger.d('[switchChain] Already on chain $newChainId, skipping switch.');
      return true;
    }
    _updateStatus('Switching to ${chainInfo['name']}...');
    _currentChainId = newChainId;
    notifyListeners();
    return true;
  }

  Future<dynamic> readContract({
    required String contractAddress,
    required String functionName,
    required dynamic abi,
    List<dynamic> params = const [],
  }) async {
    try {
      if (!_isConnected || _web3App == null || _currentChainId == null) {
        throw Exception('Wallet not connected');
      }
      _updateStatus('Reading from contract...');
      List<dynamic> abiList;
      if (abi is String) {
        abiList = json.decode(abi);
      } else if (abi is List) {
        abiList = abi;
      } else {
        throw Exception('Invalid ABI format');
      }
      final contract = DeployedContract(
        ContractAbi.fromJson(json.encode(abiList), ''),
        EthereumAddress.fromHex(contractAddress),
      );
      final function = contract.function(functionName);
      final targetChainId = _currentChainId ?? _correctChainId;
      final rpcUrl = getChainDetails(targetChainId).first['rpcUrl'] as String?;
      final httpClient = http.Client();
      final ethClient = Web3Client(rpcUrl!, httpClient);
      final result = await ethClient.call(
        contract: contract,
        function: function,
        params: params,
      );

      httpClient.close();
      _updateStatus('Contract read successful');

      return result;
    } catch (e) {
      _updateStatus('Contract read failed: ${e.toString()}');
      logger.e('Error reading contract: $e');
      throw Exception('Failed to read contract: $e');
    }
  }

  Future<String> writeContract({
    required String contractAddress,
    required String functionName,
    required dynamic abi,
    String? chainId,
    List<dynamic> params = const [],
    BigInt? value,
    BigInt? gasLimit,
  }) async {
    try {
      if (!_isConnected || _web3App == null || _currentAddress == null) {
        throw Exception('Wallet not connected');
      }

      // Validate active WalletConnect session before transaction
      final sessions = _web3App!.sessions.getAll();
      if (sessions.isEmpty) {
        logger.w(
            'No active WalletConnect sessions found, wallet may be disconnected');
        _updateConnection(
          isConnected: false,
          address: null,
          chainId: null,
          message: 'Session expired - please reconnect',
        );
        throw Exception(
            'WalletConnect session expired. Please reconnect your wallet.');
      }

      final session = sessions.first;

      // Validate session is still valid
      if (session.expiry != null &&
          DateTime.now().millisecondsSinceEpoch / 1000 > session.expiry) {
        logger.w('WalletConnect session has expired');
        _updateConnection(
          isConnected: false,
          address: null,
          chainId: null,
          message: 'Session expired - please reconnect',
        );
        throw Exception(
            'WalletConnect session has expired. Please reconnect your wallet.');
      }

      // Validate session has the required accounts
      final accounts = session.namespaces['eip155']?.accounts;
      if (accounts == null || accounts.isEmpty) {
        logger.w('No accounts found in WalletConnect session');
        throw Exception(
            'No accounts found in wallet session. Please reconnect your wallet.');
      }

      logger.d('WalletConnect session validated successfully');
      _updateStatus('Preparing transaction...');

      final abiList = json.decode(abi) as List<dynamic>;

      final contract = DeployedContract(
        ContractAbi.fromJson(json.encode(abiList), ''),
        EthereumAddress.fromHex(contractAddress),
      );

      final function = contract.function(functionName);
      final encodedFunction = function.encodeCall(params);
      final targetChainId = chainId ?? _currentChainId ?? _correctChainId;

      if (_currentChainId != targetChainId) {
        logger.w(
            'Target chain ($targetChainId) differs from current chain ($_currentChainId)');
        _updateStatus(
            'Chain mismatch detected. Current: $_currentChainId, Target: $targetChainId');
      }

      final rpcUrl = getChainDetails(targetChainId).first['rpcUrl'] as String?;
      final httpClient = http.Client();
      final ethClient = Web3Client(rpcUrl as String, httpClient);

      final nonce = await ethClient.getTransactionCount(
        EthereumAddress.fromHex(_currentAddress!),
      );

      BigInt estimatedGas = gasLimit ?? BigInt.from(100000);
      if (gasLimit == null) {
        try {
          estimatedGas = await ethClient.estimateGas(
            sender: EthereumAddress.fromHex(_currentAddress!),
            to: EthereumAddress.fromHex(contractAddress),
            data: encodedFunction,
            value: value != null ? EtherAmount.inWei(value) : null,
          );
          estimatedGas = (estimatedGas * BigInt.from(120)) ~/ BigInt.from(100);
        } catch (e) {
          logger.w('Gas estimation failed, using default: $e');
        }
      }

      final gasPrice = await ethClient.getGasPrice();
      httpClient.close();

      final transaction = {
        'from': _currentAddress!,
        'to': contractAddress,
        'data':
            '0x${encodedFunction.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}',
        'gas': '0x${estimatedGas.toRadixString(16)}',
        'gasPrice': '0x${gasPrice.getInWei.toRadixString(16)}',
        'nonce': '0x${nonce.toRadixString(16)}',
      };

      if (value != null && value > BigInt.zero) {
        transaction['value'] = '0x${value.toRadixString(16)}';
      }

      _updateStatus('Opening wallet for transaction approval...');
      final requestParams = SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [transaction],
      );
      final requestFuture = _web3App!.request(
        topic: session.topic,
        chainId: 'eip155:$targetChainId',
        request: requestParams,
      );
      await _openConnectedWalletForTransaction(session);
      _updateStatus('Waiting for transaction approval in wallet...');
      final result = await requestFuture.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Transaction approval timeout - please try again');
        },
      );

      final txHash = result.toString();
      _updateStatus('Transaction sent: ${txHash.substring(0, 10)}...');
      logger.i('Transaction hash: $txHash');

      return txHash;
    } catch (e) {
      _updateStatus('Transaction failed: ${e.toString()}');
      logger.e('Error writing to contract: $e');
      throw Exception('Failed to write to contract: $e');
    }
  }

  Future<void> _openConnectedWalletForTransaction(SessionData session) async {
    try {
      final peerMetadata = session.peer.metadata;
      final walletName = peerMetadata.name.toLowerCase();
      WalletOption? matchedWallet;

      for (final wallet in walletOptionsList) {
        final walletNameLower = wallet.name.toLowerCase();
        if (walletName.contains(walletNameLower) ||
            walletNameLower
                .contains(walletName.split(' ').first.toLowerCase())) {
          matchedWallet = wallet;
          break;
        }
      }

      if (matchedWallet != null) {
        logger.d('Opening ${matchedWallet.name} for transaction approval');
        await _openWalletAppForTransaction(matchedWallet);
      } else {
        logger.d('Unknown wallet: $walletName, trying generic approach');
        await _openGenericWallet(walletName);
      }
    } catch (e) {
      logger.w('Failed to auto-open wallet app: $e');
    }
  }

  Future<void> _openWalletAppForTransaction(WalletOption wallet) async {
    try {
      String deepLinkBase = wallet.deepLink.replaceAll('wc?uri=', '');
      if (!deepLinkBase.endsWith('://')) {
        deepLinkBase = deepLinkBase.replaceAll('://', '://');
      }

      final Uri deepLink = Uri.parse('${deepLinkBase}wc');
      bool launched = false;

      if (await canLaunchUrl(deepLink)) {
        launched = await launchUrl(
          deepLink,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched && wallet.fallbackUrl != null) {
        String fallbackBase = wallet.fallbackUrl!.replaceAll('wc?uri=', '');
        final Uri fallbackUri = Uri.parse('${fallbackBase}wc');
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(
            fallbackUri,
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } catch (e) {
      logger.w('Failed to open ${wallet.name}: $e');
    }
  }

  Future<void> _openGenericWallet(String walletName) async {
    try {
      final List<String> commonSchemes = [
        '${walletName.replaceAll(' ', '').toLowerCase()}://',
        '${walletName.replaceAll(' ', '').toLowerCase()}wallet://',
        '${walletName.split(' ').first.toLowerCase()}://',
      ];

      for (final scheme in commonSchemes) {
        try {
          final Uri uri = Uri.parse('${scheme}wc');
          if (await canLaunchUrl(uri)) {
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (launched) {
              logger.d('Successfully opened wallet with scheme: $scheme');
              return;
            }
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      logger.w('Failed to open wallet with generic approach: $e');
    }
  }

  Future<String> signMessage(String message, {String? chainId}) async {
    try {
      if (!_isConnected || _web3App == null || _currentAddress == null) {
        throw Exception('Wallet not connected');
      }

      _updateStatus('Signing message...');

      final sessions = _web3App!.sessions.getAll();
      if (sessions.isEmpty) {
        throw Exception('No active WalletConnect session');
      }

      final targetChainId = chainId ?? _currentChainId ?? _correctChainId;
      final result = await _web3App!.request(
        topic: sessions.first.topic,
        chainId: 'eip155:$targetChainId',
        request: SessionRequestParams(
          method: 'personal_sign',
          params: [
            '0x${utf8.encode(message).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}',
            _currentAddress!,
          ],
        ),
      );

      final signature = result.toString();
      _updateStatus('Message signed');

      return signature;
    } catch (e) {
      _updateStatus('Message signing failed: ${e.toString()}');
      logger.e('Error signing message: $e');
      throw Exception('Failed to sign message: $e');
    }
  }

  Future<void> disconnectWallet() async {
    if (!_isConnected) return;
    logger.d("Tried to disconnect");
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
