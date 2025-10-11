import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_read_services.dart';

class UserProfileData {
  String name;
  final String userAddress;
  final String profilePhoto;
  final int dateJoined;
  final int verificationsRevoked;
  final int reportedSpam;
  final int careTokens;
  final int legacyTokens;

  UserProfileData(
      {required this.name,
      required this.userAddress,
      required this.profilePhoto,
      required this.dateJoined,
      required this.verificationsRevoked,
      required this.reportedSpam,
      required this.careTokens,
      required this.legacyTokens});

  factory UserProfileData.fromContractData(dynamic data) {
    logger.d("Raw contract data: $data");
    logger.d("Data type: ${data.runtimeType}");
    logger.d("Data length: ${data is List ? data.length : 'N/A'}");

    try {
      dynamic actualData = data;

      if (actualData is! List || actualData.length < 8) {
        logger.e(
            "Invalid data: Expected List with at least 8 elements, got ${actualData.runtimeType} with length ${actualData is List ? actualData.length : 'N/A'}");
        throw Exception("Invalid contract data structure");
      }
      final userProfile = UserProfileData(
        userAddress: actualData[0]?.toString() ?? '',
        profilePhoto: actualData[1]?.toString() ?? '',
        name: actualData[2]?.toString() ?? '',
        dateJoined: _toInt(actualData[3]),
        verificationsRevoked: _toInt(actualData[4]),
        reportedSpam: _toInt(actualData[5]),
        legacyTokens: _toInt(actualData[6]),
        careTokens: _toInt(actualData[7]),
      );
      return userProfile;
    } catch (e) {

      return UserProfileData(
        name: '',
        userAddress: '',
        profilePhoto: '',
        dateJoined: 0,
        verificationsRevoked: 0,
        reportedSpam: 0,
        careTokens: 0,
        legacyTokens: 0,
      );
    }
  }

  static int _toInt(dynamic value) {
    try {
      if (value == null) {
        logger.d("_toInt: value is null, returning 0");
        return 0;
      }
      if (value is BigInt) {
        logger.d("_toInt: Converting BigInt $value to int");
        return value.toInt();
      }
      if (value is int) {
        logger.d("_toInt: Value is already int: $value");
        return value;
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        logger.d("_toInt: Parsing string '$value' to int: $parsed");
        return parsed ?? 0;
      }
      final parsed = int.tryParse(value.toString());
      logger.d(
          "_toInt: Converting ${value.runtimeType} '$value' to int: $parsed");
      return parsed ?? 0;
    } catch (e) {
      logger.e(
          "_toInt: Error converting $value (${value.runtimeType}) to int: $e");
      return 0;
    }
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
        logger.d("Profile data from contract result: $data");

        setState(() {
          _userProfileData = UserProfileData.fromContractData(data);
          logger.d(
              "State updated with UserProfileData: ${_userProfileData?.name}, Care: ${_userProfileData?.careTokens}, Legacy: ${_userProfileData?.legacyTokens}");
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
                child: Builder(
                  builder: (context) {
                    logger.d(
                        "UI: Profile photo URL: '${_userProfileData!.profilePhoto}'");
                    logger.d(
                        "UI: Profile photo isEmpty: ${_userProfileData!.profilePhoto.isEmpty}");

                    return _userProfileData!.profilePhoto.isNotEmpty
                        ? Image.network(
                            _userProfileData!.profilePhoto,
                            fit: BoxFit.cover,
                            headers: {
                              'Access-Control-Allow-Origin': '*',
                            },
                            errorBuilder: (context, error, stackTrace) {
                              logger.e(
                                  "Profile photo loading error for URL: ${_userProfileData!.profilePhoto}");
                              logger.e("Error: $error");
                              logger.e("Stack trace: $stackTrace");

                              // Try alternative IPFS gateway if original fails
                              String originalUrl =
                                  _userProfileData!.profilePhoto;
                              if (originalUrl.contains('pinata.cloud')) {
                                String ipfsHash =
                                    originalUrl.split('/ipfs/').last;
                                String alternativeUrl =
                                    'https://ipfs.io/ipfs/$ipfsHash';
                                logger.d(
                                    "Trying alternative IPFS gateway: $alternativeUrl");

                                return Image.network(
                                  alternativeUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error2, stackTrace2) {
                                    logger.e(
                                        "Alternative IPFS gateway also failed: $error2");
                                    return const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.black,
                                    );
                                  },
                                );
                              }

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
                          );
                  },
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: getThemeColors(context)['secondaryButton'],
                foregroundColor: getThemeColors(context)['textPrimary'],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonCircularRadius),
                ),
                elevation: 4,
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              onPressed: () {
                context.push('/organisations');
              },
              child: Text(
                "Organisations",
                style: TextStyle(
                  color: getThemeColors(context)['textPrimary'],
                ),
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
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(buttonCircularRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['secondary'],
                    border: Border.all(
                      color: getThemeColors(context)['border']!,
                      width: buttonborderWidth,
                    ),
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                  ),
                ),
              ),
            )),
        Padding(
            padding: const EdgeInsets.all(4.0),
            child: SizedBox(
              height: 40,
              width: 150,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(buttonCircularRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['primary'],
                    border: Border.all(
                      color: getThemeColors(context)['border']!,
                      width: buttonborderWidth,
                    ),
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                  ),
                  child: Center(
                    child: Builder(builder: (context) {
                      logger.d(
                          "UI: Displaying Care Tokens: ${_userProfileData!.careTokens}");
                      return Text(
                          'Care Tokens : ${_userProfileData!.careTokens}',
                          style: TextStyle(
                            color: getThemeColors(context)['textPrimary'],
                            fontWeight: FontWeight.bold,
                          ));
                    }),
                  ),
                ),
              ),
            )),
        Padding(
            padding: const EdgeInsets.all(4.0),
            child: SizedBox(
              height: 40,
              width: 150,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(buttonCircularRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['secondary'],
                    border: Border.all(
                      color: getThemeColors(context)['border']!,
                      width: buttonborderWidth,
                    ),
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                  ),
                ),
              ),
            )),
        Padding(
            padding: const EdgeInsets.all(4.0),
            child: SizedBox(
              height: 40,
              width: 150,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(buttonCircularRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['primary'],
                    border: Border.all(
                      color: getThemeColors(context)['border']!,
                      width: buttonborderWidth,
                    ),
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                  ),
                  child: Center(
                    child: Builder(builder: (context) {
                      logger.d(
                          "UI: Displaying Legacy Tokens: ${_userProfileData!.legacyTokens}");
                      return Text(
                          'Legacy Tokens : ${_userProfileData!.legacyTokens}',
                          style: TextStyle(
                            color: getThemeColors(context)['textPrimary'],
                            fontWeight: FontWeight.bold,
                          ));
                    }),
                  ),
                ),
              ),
            )),
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
              color: getThemeColors(context)['error']!,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: getThemeColors(context)['error']!,
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
            valueColor: AlwaysStoppedAnimation<Color>(
                getThemeColors(context)['primary']!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 16,
              color: getThemeColors(context)['primary'],
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
