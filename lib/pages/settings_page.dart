import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';
import 'package:tree_planting_protocol/utils/services/switch_chain_utils.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/planter_token_contract/planter_token_read_services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _tokenAddressController = TextEditingController();
  final TextEditingController _userAddressController = TextEditingController();
  bool _isLoadingToken = false;
  Map<String, dynamic>? _tokenDetails;
  String? _tokenError;

  @override
  void dispose() {
    _tokenAddressController.dispose();
    _userAddressController.dispose();
    super.dispose();
  }

  Future<void> _checkPlanterToken() async {
    if (_tokenAddressController.text.trim().isEmpty) {
      setState(() {
        _tokenError = 'Please enter a token contract address';
      });
      return;
    }

    setState(() {
      _isLoadingToken = true;
      _tokenError = null;
      _tokenDetails = null;
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      final result = await PlanterTokenReadFunctions.getPlanterTokenDetails(
        walletProvider: walletProvider,
        tokenContractAddress: _tokenAddressController.text.trim(),
      );

      if (result.success && result.data != null) {
        setState(() {
          _tokenDetails = result.data;
          _isLoadingToken = false;
        });
      } else {
        setState(() {
          _tokenError = result.errorMessage ?? 'Failed to fetch token details';
          _isLoadingToken = false;
        });
      }
    } catch (e) {
      setState(() {
        _tokenError = 'Error: ${e.toString()}';
        _isLoadingToken = false;
      });
    }
  }

  void _viewUserProfile() {
    final address = _userAddressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a user address'),
          backgroundColor: getThemeColors(context)['error'],
        ),
      );
      return;
    }

    // Navigate to user profile page with address
    context.push('/user-profile/$address');
  }

  String _formatAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Unknown';
    }
    if (address.length <= 18) {
      return address;
    }
    return '${address.substring(0, 10)}...${address.substring(address.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Settings & Tools",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Wallet Information',
              child: Consumer<WalletProvider>(
                builder: (ctx, walletProvider, __) {
                  final address = walletProvider.userAddress ?? '';
                  final shortAddress = address.isNotEmpty && address.length > 18
                      ? '${address.substring(0, 10)}...${address.substring(address.length - 8)}'
                      : address.isNotEmpty
                          ? address
                          : 'Not connected';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Address:',
                        shortAddress,
                        copyable: address.isNotEmpty ? address : null,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Network:',
                        '${walletProvider.currentChainName} (${walletProvider.currentChainId})',
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'Switch Chain',
                        Icons.swap_horiz,
                        () => showChainSelector(context, walletProvider),
                        getThemeColors(context)['primary']!,
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Planter Token Checker Section
            _buildSectionCard(
              title: 'Check Planter Token',
              subtitle: 'View owner and planter address of any token contract',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _tokenAddressController,
                    decoration: InputDecoration(
                      hintText: 'Enter token contract address',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                        borderSide: BorderSide(
                          color: getThemeColors(context)['border']!,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                        borderSide: BorderSide(
                          color: getThemeColors(context)['border']!,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                        borderSide: BorderSide(
                          color: getThemeColors(context)['primary']!,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    'Check Token',
                    Icons.search,
                    _isLoadingToken ? null : _checkPlanterToken,
                    getThemeColors(context)['secondary']!,
                  ),
                  if (_isLoadingToken) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_tokenError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: getThemeColors(context)['error']!,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: getThemeColors(context)['error']!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _tokenError!,
                        style: TextStyle(
                          color: getThemeColors(context)['error'],
                        ),
                      ),
                    ),
                  ],
                  if (_tokenDetails != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: getThemeColors(context)['secondary'],
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                        border: Border.all(
                          color: getThemeColors(context)['border']!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Token Details',
                            style: TextStyle(
                              color: getThemeColors(context)['textPrimary'],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Name:',
                            _tokenDetails!['name'] ?? 'Unknown',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Symbol:',
                            _tokenDetails!['symbol'] ?? 'Unknown',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Owner:',
                            _formatAddress(_tokenDetails!['owner'] as String?),
                            copyable: _tokenDetails!['owner'] as String?,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Planter:',
                            _formatAddress(
                                _tokenDetails!['planterAddress'] as String?),
                            copyable:
                                _tokenDetails!['planterAddress'] as String?,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // User Profile Viewer Section
            _buildSectionCard(
              title: 'View User Profile',
              subtitle: 'Check profile and NFTs of any user by address',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _userAddressController,
                    decoration: InputDecoration(
                      hintText: 'Enter user wallet address',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                        borderSide: BorderSide(
                          color: getThemeColors(context)['border']!,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                        borderSide: BorderSide(
                          color: getThemeColors(context)['border']!,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(buttonCircularRadius),
                        borderSide: BorderSide(
                          color: getThemeColors(context)['primary']!,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    'View Profile',
                    Icons.person,
                    _viewUserProfile,
                    getThemeColors(context)['primary']!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: getThemeColors(context)['textSecondary'],
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {String? copyable}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: getThemeColors(context)['textSecondary'],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ),
        if (copyable != null)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyable));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copied to clipboard!'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: getThemeColors(context)['primary'],
                ),
              );
            },
            icon: Icon(
              Icons.copy,
              size: 16,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback? onPressed,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(buttonCircularRadius),
          child: Container(
            decoration: BoxDecoration(
              color: onPressed == null ? Colors.grey : color,
              border: Border.all(
                color: getThemeColors(context)['border']!,
                width: buttonborderWidth,
              ),
              borderRadius: BorderRadius.circular(buttonCircularRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: getThemeColors(context)['textPrimary'],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: getThemeColors(context)['textPrimary'],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
