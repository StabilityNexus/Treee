import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_read_services.dart';

class UserProfileData {
  String name;
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
      return UserProfileData(
        name: actualData[2].toString(),
        userAddress: actualData[0].toString(),
        profilePhotoIpfs: actualData[1].toString(),
        dateJoined: _toInt(actualData[3]),
        verificationsRevoked: _toInt(actualData[4]),
        reportedSpam: _toInt(actualData[5]),
        verifierTokens: _toInt(actualData[6]),
        careTokens: _toInt(actualData[9]),
        planterTokens: _toInt(actualData[7]),
        legacyTokens: _toInt(actualData[8]),
      );
    } catch (e) {
      logger.d("Error parsing Tree data: $e");
      logger.d("Data received: $data");
      logger.d("Data type: ${data.runtimeType}");

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
        final List data = result.data['profile'] ?? [];

        setState(() {
          _userProfileData = UserProfileData.fromContractData(data);
        });
      } else {
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
            _errorMessage =
                result.errorMessage ?? 'Failed to load profile data';
          });
        }
      }
    } catch (e) {
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
          _errorMessage = 'Errorloading User profile details: $e';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _profileOverview() {
    return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: ClipOval(
                child: _userProfileData!.profilePhotoIpfs.isNotEmpty
                    ? Image.network(
                        _userProfileData!.profilePhotoIpfs,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.black,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const CircularProgressIndicator(
                            color: Colors.black,
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
            Text(
              _userProfileData!.name.isNotEmpty
                  ? _userProfileData!.name
                  : 'Anonymous User',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(width: 16),
            Text(
              '${_userProfileData!.userAddress.substring(0, 6)}...${_userProfileData!.userAddress.substring(_userProfileData!.userAddress.length - 4)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: SizedBox(
                height: 40,
                width: 135,
                child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4E63),
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12, // shadow color
                          blurRadius: 6, // shadow softness
                          offset: Offset(0, 3), // shadow position
                        ),
                      ],
                    ),
                    child: Center(child: Text('Organisations'))),
              ),
            ),
          ],
        ));
  }

  Widget _tokenWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            height: 40,
            width: 150,
            child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 251, 251, 99),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12, // shadow color
                      blurRadius: 6, // shadow softness
                      offset: Offset(0, 3), // shadow position
                    ),
                  ],
                ),
                child: Center(
                    child: Text(
                        'Planter Tokens : ${_userProfileData!.planterTokens}'))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            height: 40,
            width: 150,
            child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 28, 211, 129),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                    child:
                        Text('Care Tokens : ${_userProfileData!.careTokens}'))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            height: 40,
            width: 150,
            child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 251, 251, 99),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                    child: Text(
                        'Verifier Tokens : ${_userProfileData!.verifierTokens}'))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            height: 40,
            width: 150,
            child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 28, 211, 129),
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                    child: Text(
                        'Legacy Tokens : ${_userProfileData!.legacyTokens}'))),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
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
              onPressed: () {
                context.push('/register-user');
              },
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _profileOverview(),
                      SizedBox(
                        width: 15,
                      ),
                      _tokenWidget()
                    ],
                  ));
  }
}
