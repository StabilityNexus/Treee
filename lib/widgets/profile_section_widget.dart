import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_read_services.dart';

class UserProfileData {
  final String name;
  final String userAddress;
  final String profilePhotoIpfs;
  final int dateJoined;
  final int verificationsRevoked;
  final int reportedSpam;
  final int verifierTokens;
  final int careTokens;
  final int planterTokens;
  final int legacyTokens;

  UserProfileData(
      {required this.name,
      required this.userAddress,
      required this.profilePhotoIpfs,
      required this.dateJoined,
      required this.verificationsRevoked,
      required this.reportedSpam,
      required this.verifierTokens,
      required this.careTokens,
      required this.planterTokens,
      required this.legacyTokens});

  factory UserProfileData.fromContractData(dynamic data) {
    logger.d(data);
    try {
      dynamic actualData = data;
      if (data is List && data.length == 1) {
        actualData = data[0];
      }

      if (actualData is List) {
        return UserProfileData(
          name: actualData[2].toString() ?? '',
          userAddress: actualData[0].toString() ?? '',
          profilePhotoIpfs: actualData[1].toString() ?? '',
          dateJoined: _toInt(actualData[3]),
          verificationsRevoked: _toInt(actualData[4]),
          reportedSpam: _toInt(actualData[5]),
          verifierTokens: _toInt(actualData[6]),
          careTokens: _toInt(actualData[9]),
          planterTokens: _toInt(actualData[7]),
          legacyTokens: _toInt(actualData[8]),
        );
      }
      throw Exception("Unexpected data structure: ${actualData.runtimeType}");
    } catch (e) {
      debugPrint("Error parsing Tree data: $e");
      debugPrint("Data received: $data");
      debugPrint("Data type: ${data.runtimeType}");

      return UserProfileData(
        name: '',
        userAddress: '',
        profilePhotoIpfs: '',
        dateJoined: 0,
        verificationsRevoked: 0,
        reportedSpam: 0,
        verifierTokens: 0,
        careTokens: 0,
        planterTokens: 0,
        legacyTokens: 0,
      );
    }
  }

  static int _toInt(dynamic value) {
    if (value is BigInt) return value.toInt();
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

class ProfileSectionWidget extends StatefulWidget {
  const ProfileSectionWidget({super.key});

  @override
  State<ProfileSectionWidget> createState() => _ProfileSectionWidgetState();
}

class _ProfileSectionWidgetState extends State<ProfileSectionWidget> {
  bool _isLoading = false;
  String? _errorMessage = "";
  UserProfileData? _userProfileData;
  bool _isNotRegistered = false;

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

      final result = await ContractReadFunctions.getProfileDetails(
        walletProvider: walletProvider,
      );

      if (result.success && result.data != null) {
        final UserProfileData data = result.data['profile'] ?? [];

        setState(() {
          _userProfileData = data;
        });
      } else {
        // Check if the error is a revert error indicating user is not registered
        final errorMsg = result.errorMessage?.toLowerCase() ?? '';
        if (errorMsg.contains('revert') || 
            errorMsg.contains('not registered') || 
            errorMsg.contains('user not found') ||
            errorMsg.contains('execution reverted')) {
          setState(() {
            _isNotRegistered = true;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = result.errorMessage ?? 'Failed to load profile data';
          });
        }
      }
    } catch (e) {
      // Check if the exception indicates a revert/not registered error
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('revert') || 
          errorMsg.contains('not registered') || 
          errorMsg.contains('user not found') ||
          errorMsg.contains('execution reverted')) {
        setState(() {
          _isNotRegistered = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Error loading User profile details: $e';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Profile Photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: _userProfileData!.profilePhotoIpfs.isNotEmpty
                  ? Image.network(
                      'https://ipfs.io/ipfs/${_userProfileData!.profilePhotoIpfs}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator(
                          color: Colors.white,
                        );
                      },
                    )
                  : Container(
                      color: Colors.green.shade300,
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Name and Address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfileData!.name.isNotEmpty
                      ? _userProfileData!.name
                      : 'Anonymous User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_userProfileData!.userAddress.substring(0, 6)}...${_userProfileData!.userAddress.substring(_userProfileData!.userAddress.length - 4)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Joined ${_formatDate(_userProfileData!.dateJoined)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokensSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Token Balance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTokenCard(
                  'Verifier',
                  _userProfileData!.verifierTokens,
                  Icons.verified_user,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTokenCard(
                  'Care',
                  _userProfileData!.careTokens,
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTokenCard(
                  'Planter',
                  _userProfileData!.planterTokens,
                  Icons.eco,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTokenCard(
                  'Legacy',
                  _userProfileData!.legacyTokens,
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Verifications Revoked',
            _userProfileData!.verificationsRevoked,
            Icons.remove_circle_outline,
            _userProfileData!.verificationsRevoked > 0 ? Colors.orange : Colors.grey,
          ),
          const Divider(height: 20),
          _buildStatRow(
            'Reported as Spam',
            _userProfileData!.reportedSpam,
            Icons.report_problem_outlined,
            _userProfileData!.reportedSpam > 0 ? Colors.red : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, int value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotRegisteredState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add,
              size: 40,
              color: Colors.green.shade400,
            ),
          ),
          const SizedBox(height: 34),
          Text(
            'Welcome to Tree Planting Protocol!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'You haven\'t registered yet. Create your profile to start your tree planting journey!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _handleRegistration,
              icon: const Icon(Icons.app_registration, size: 20),
              label: const Text(
                'Register Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _loadUserProfileData(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Check Again'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleRegistration() {
    // Navigate to registration screen or show registration dialog
    // You can replace this with your actual registration logic
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration'),
          content: const Text(
            'This will navigate to the registration screen or trigger the registration process.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add your registration logic here
                // For example:
                // Navigator.pushNamed(context, '/register');
                // or call a registration function
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _loadUserProfileData(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? _buildLoadingState()
          : _isNotRegistered
              ? _buildNotRegisteredState()
              : _errorMessage != null && _errorMessage!.isNotEmpty
                  ? _buildErrorState()
                  : _userProfileData == null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: () => _loadUserProfileData(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildProfileHeader(),
                                const SizedBox(height: 20),
                                _buildTokensSection(),
                                const SizedBox(height: 20),
                                _buildStatsSection(),
                              ],
                            ),
                          ),
      ),
    );
  }
}