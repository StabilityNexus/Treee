import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_read_services.dart';
import 'package:tree_planting_protocol/widgets/image_loader_widget.dart';
import 'package:tree_planting_protocol/widgets/profile_widgets/profile_section_widget.dart';

class UserProfileViewerWidget extends StatefulWidget {
  final String userAddress;

  const UserProfileViewerWidget({
    super.key,
    required this.userAddress,
  });

  @override
  State<UserProfileViewerWidget> createState() =>
      _UserProfileViewerWidgetState();
}

class _UserProfileViewerWidgetState extends State<UserProfileViewerWidget> {
  bool _isLoading = false;
  String? _errorMessage;
  UserProfileData? _userProfileData;
  List<VerificationDetails> _verifierTokens = [];
  bool _isNotRegistered = false;
  int _displayedTokensCount = 5;
  String? _expandedTokenAddress;

  String _getTreeIcon(int index) {
    final treeNumber = ((index * 3) % 13) + 1;
    return 'assets/tree-navbar-images/tree-$treeNumber.png';
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfileData();
  }

  Future<void> _loadUserProfileData({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isNotRegistered = false;
      if (!loadMore) {
        _errorMessage = null;
      }
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      final result = await ContractReadFunctions.getProfileDetailsByAddress(
        walletProvider: walletProvider,
        userAddress: widget.userAddress,
      );

      if (result.success && result.data != null) {
        final List data = result.data['profile'] ?? [];
        final List verifierTokensData = result.data['verifierTokens'] ?? [];

        setState(() {
          _isLoading = false;
          if (data.isEmpty) {
            _isNotRegistered = true;
          } else {
            _userProfileData = UserProfileData.fromContractData(data);
            _verifierTokens = verifierTokensData
                .map((token) => VerificationDetails.fromContractData(token))
                .toList();
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.errorMessage ?? 'Failed to load user profile';
          if (result.errorMessage?.contains('not registered') ?? false) {
            _isNotRegistered = true;
          }
        });
      }
    } catch (e) {
      logger.e("Error loading user profile", error: e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isNotRegistered) {
      return _buildNotRegisteredWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_userProfileData == null) {
      return const Center(
        child: Text('No profile data available'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 16),
        _buildProfileInfo(),
        const SizedBox(height: 20),
        if (_verifierTokens.isNotEmpty) ...[
          _buildVerifierTokensWidget(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: getThemeColors(context)['border']!,
                width: 3,
              ),
            ),
            child: _userProfileData!.profilePhoto.isNotEmpty
                ? CircularImageLoaderWidget(
                    imageUrl: _userProfileData!.profilePhoto,
                    radius: 50,
                  )
                : Container(
                    color: getThemeColors(context)['secondary'],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfileData!.name.isNotEmpty
                ? _userProfileData!.name
                : 'Anonymous User',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildAddressRow(),
        ],
      ),
    );
  }

  Widget _buildAddressRow() {
    final shortAddress = widget.userAddress.length > 18
        ? '${widget.userAddress.substring(0, 10)}...${widget.userAddress.substring(widget.userAddress.length - 8)}'
        : widget.userAddress;

    return Row(
      children: [
        Text(
          shortAddress,
          style: TextStyle(
            color: getThemeColors(context)['textSecondary'],
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.userAddress));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Address copied to clipboard!'),
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

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Care Tokens',
                _userProfileData!.careTokens.toString(),
                Icons.favorite,
              ),
              _buildStatColumn(
                'Legacy Tokens',
                _userProfileData!.legacyTokens.toString(),
                Icons.stars,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Reports',
                _userProfileData!.reportedSpam.toString(),
                Icons.flag,
              ),
              _buildStatColumn(
                'Revoked',
                _userProfileData!.verificationsRevoked.toString(),
                Icons.remove_circle,
              ),
            ],
          ),
          if (_userProfileData!.dateJoined > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: getThemeColors(context)['textSecondary'],
                ),
                const SizedBox(width: 8),
                Text(
                  'Joined: ${DateTime.fromMillisecondsSinceEpoch(_userProfileData!.dateJoined * 1000).toString().split(' ')[0]}',
                  style: TextStyle(
                    color: getThemeColors(context)['textSecondary'],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: getThemeColors(context)['primary'],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: getThemeColors(context)['textPrimary'],
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: getThemeColors(context)['textSecondary'],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifierTokensWidget() {
    if (_verifierTokens.isEmpty) return const SizedBox.shrink();

    final tokensToShow = _verifierTokens.take(_displayedTokensCount).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verifier Tokens',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: tokensToShow
                .asMap()
                .entries
                .map((entry) => _buildTokenBubble(entry.value, entry.key))
                .toList(),
          ),
          if (_verifierTokens.length > _displayedTokensCount) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _displayedTokensCount += 5;
                  });
                },
                child: Text(
                  'Load More (${_verifierTokens.length - _displayedTokensCount} remaining)',
                  style: TextStyle(
                    color: getThemeColors(context)['primary'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTokenBubble(VerificationDetails token, int index) {
    final isExpanded =
        _expandedTokenAddress == token.verifierPlanterTokenAddress;
    final bubbleColor = index % 2 == 0
        ? getThemeColors(context)['primary']!
        : getThemeColors(context)['secondary']!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedTokenAddress =
              isExpanded ? null : token.verifierPlanterTokenAddress;
        });
      },
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        child: ClipRect(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isExpanded ? 280 : 80,
            height: isExpanded ? 120 : 80,
            decoration: BoxDecoration(
              color: bubbleColor,
              border: Border.all(
                color: getThemeColors(context)['border']!,
                width: buttonborderWidth,
              ),
              borderRadius: BorderRadius.circular(buttonCircularRadius),
            ),
            child: isExpanded
                ? _buildExpandedTokenContent(token)
                : _buildCollapsedTokenContent(token, index),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedTokenContent(VerificationDetails token, int index) {
    final formattedAmount = _formatTokenAmount(token.numberOfTrees / 1e18);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          _getTreeIcon(index),
          width: 32,
          height: 32,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.park,
              size: 32,
              color: getThemeColors(context)['textPrimary'],
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          formattedAmount,
          style: TextStyle(
            color: getThemeColors(context)['textPrimary'],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExpandedTokenContent(VerificationDetails token) {
    final formattedAmount =
        _formatDetailedTokenAmount(token.numberOfTrees / 1e18);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Amount: $formattedAmount',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Verifier: ${token.verifierPlanterTokenAddress.substring(0, 8)}...${token.verifierPlanterTokenAddress.substring(token.verifierPlanterTokenAddress.length - 6)}',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          if (token.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              token.description,
              style: TextStyle(
                color: getThemeColors(context)['textPrimary'],
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Date: ${DateTime.fromMillisecondsSinceEpoch(token.timestamp * 1000).toString().split('.')[0]}',
            style: TextStyle(
              color: getThemeColors(context)['textSecondary'],
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTokenAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDetailedTokenAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    } else if (amount >= 1) {
      return amount.toStringAsFixed(2);
    }
    return amount.toStringAsFixed(4);
  }

  Widget _buildNotRegisteredWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: getThemeColors(context)['textSecondary'],
          ),
          const SizedBox(height: 16),
          Text(
            'User Not Registered',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This address is not registered in the system',
            style: TextStyle(
              color: getThemeColors(context)['textSecondary'],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: getThemeColors(context)['error']!,
        borderRadius: BorderRadius.circular(buttonCircularRadius),
        border: Border.all(
          color: getThemeColors(context)['error']!,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: getThemeColors(context)['error'],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Profile',
            style: TextStyle(
              color: getThemeColors(context)['error'],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyle(
              color: getThemeColors(context)['textSecondary'],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadUserProfileData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: getThemeColors(context)['primary'],
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
