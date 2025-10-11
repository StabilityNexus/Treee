import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/constants/ui/dimensions.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_read_services.dart';

class VerificationDetails {
  final String verifier;
  final int timestamp;
  final List<String> proofHashes;
  final String description;
  final bool isHidden;
  final int numberOfTrees;
  final String verifierPlanterTokenAddress;

  VerificationDetails({
    required this.verifier,
    required this.timestamp,
    required this.proofHashes,
    required this.description,
    required this.isHidden,
    required this.numberOfTrees,
    required this.verifierPlanterTokenAddress,
  });

  factory VerificationDetails.fromContractData(dynamic data) {
    logger.d("VerificationDetails.fromContractData - Raw data: $data");
    logger.d(
        "VerificationDetails.fromContractData - Data type: ${data.runtimeType}");
    logger.d(
        "VerificationDetails.fromContractData - Data length: ${data is List ? data.length : 'N/A'}");

    try {
      if (data is List && data.length >= 7) {
        logger.d("VerificationDetails - Parsing fields:");
        logger.d("  verifier: ${data[0]} (${data[0].runtimeType})");
        logger.d("  timestamp: ${data[1]} (${data[1].runtimeType})");
        logger.d("  proofHashes: ${data[2]} (${data[2].runtimeType})");
        logger.d("  description: ${data[3]} (${data[3].runtimeType})");
        logger.d("  isHidden: ${data[4]} (${data[4].runtimeType})");
        logger.d("  numberOfTrees: ${data[5]} (${data[5].runtimeType})");
        logger.d(
            "  verifierPlanterTokenAddress: ${data[6]} (${data[6].runtimeType})");
      }

      final verificationDetails = VerificationDetails(
        verifier: data[0]?.toString() ?? '',
        timestamp: _toIntStatic(data[1]),
        proofHashes: data[2] is List
            ? (data[2] as List).map((e) => e?.toString() ?? '').toList()
            : [],
        description: data[3]?.toString() ?? '',
        isHidden:
            data[4] == true || data[4]?.toString().toLowerCase() == 'true',
        numberOfTrees: _toIntStatic(data[5]),
        verifierPlanterTokenAddress: data[6]?.toString() ?? '',
      );

      logger.d("VerificationDetails parsed successfully:");
      logger.d("  verifier: ${verificationDetails.verifier}");
      logger.d("  timestamp: ${verificationDetails.timestamp}");
      logger.d("  proofHashes: ${verificationDetails.proofHashes}");
      logger.d("  description: ${verificationDetails.description}");
      logger.d("  isHidden: ${verificationDetails.isHidden}");
      logger.d("  numberOfTrees: ${verificationDetails.numberOfTrees}");
      logger.d(
          "  verifierPlanterTokenAddress: ${verificationDetails.verifierPlanterTokenAddress}");

      return verificationDetails;
    } catch (e) {
      logger.e("Error parsing VerificationDetails: $e");
      logger.e("Data received: $data");
      logger.e("Data type: ${data.runtimeType}");
      return VerificationDetails(
        verifier: '',
        timestamp: 0,
        proofHashes: [],
        description: '',
        isHidden: false,
        numberOfTrees: 0,
        verifierPlanterTokenAddress: '',
      );
    }
  }

  static int _toIntStatic(dynamic value) {
    try {
      logger.d("_toIntStatic: Converting value: $value (${value.runtimeType})");
      if (value == null) {
        logger.d("_toIntStatic: Value is null, returning 0");
        return 0;
      }
      if (value is BigInt) {
        final result = value.toInt();
        logger.d("_toIntStatic: Converted BigInt $value to int $result");
        return result;
      }
      if (value is int) {
        logger.d("_toIntStatic: Value is already int: $value");
        return value;
      }
      final parsed = int.tryParse(value.toString());
      logger.d(
          "_toIntStatic: Parsed ${value.runtimeType} '$value' to int: $parsed");
      return parsed ?? 0;
    } catch (e) {
      logger.e(
          "_toIntStatic: Error converting $value (${value.runtimeType}) to int: $e");
      return 0;
    }
  }
}

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
  List<VerificationDetails> _verifierTokens = [];
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

      logger.d("Calling ContractReadFunctions.getProfileDetails...");

      final result = await ContractReadFunctions.getProfileDetails(
        walletProvider: walletProvider,
      );

      logger.d("Contract call completed:");
      logger.d("  - Success: ${result.success}");
      logger.d("  - Data not null: ${result.data != null}");
      logger.d("  - Full result data: ${result.data}");

      if (result.data != null) {
        logger.d("Result data keys: ${result.data.keys}");
        logger.d("Profile exists: ${result.data.containsKey('profile')}");
        logger.d(
            "VerifierTokens exists: ${result.data.containsKey('verifierTokens')}");
      }

      if (result.success && result.data != null) {
        final List data = result.data['profile'] ?? [];
        final List verifierTokensData = result.data['verifierTokens'] ?? [];
        logger.d("Profile data from contract result: $data");
        logger.d(
            "Verifier tokens data from contract result: $verifierTokensData");
        logger
            .d("Verifier tokens data type: ${verifierTokensData.runtimeType}");
        logger.d("Verifier tokens data isEmpty: ${verifierTokensData.isEmpty}");

        setState(() {
          _userProfileData = UserProfileData.fromContractData(data);

          logger.d("Processing verifier tokens data...");
          logger.d(
              "Raw verifier tokens data type: ${verifierTokensData.runtimeType}");
          logger.d(
              "Raw verifier tokens data length: ${verifierTokensData.length}");

          for (int i = 0; i < verifierTokensData.length; i++) {
            logger.d("Processing verifier token $i: ${verifierTokensData[i]}");
          }

          _verifierTokens = verifierTokensData.map((tokenData) {
            logger.d("Mapping token data: $tokenData");
            return VerificationDetails.fromContractData(tokenData);
          }).toList();

          logger.d(
              "State updated with UserProfileData: ${_userProfileData?.name}, Care: ${_userProfileData?.careTokens}, Legacy: ${_userProfileData?.legacyTokens}");
          logger.d("Verifier tokens loaded: ${_verifierTokens.length} tokens");

          for (int i = 0; i < _verifierTokens.length; i++) {
            final token = _verifierTokens[i];
            logger.d("Verifier token $i:");
            logger.d("  - verifier: ${token.verifier}");
            logger.d("  - numberOfTrees: ${token.numberOfTrees}");
            logger.d("  - description: ${token.description}");
            logger.d("  - timestamp: ${token.timestamp}");
            logger.d("  - isHidden: ${token.isHidden}");
          }
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

  Widget _verifierTokensWidget() {
    logger.d(
        "Building verifier tokens widget, tokens count: ${_verifierTokens.length}");

    return Container(
      width: 300,
      height: 200, // Fixed height to ensure it's visible
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background'],
        border: Border.all(
          color: getThemeColors(context)['primaryBorder'] ?? Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (getThemeColors(context)['shadow'] ?? Colors.grey)
                .withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: getThemeColors(context)['primary'],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: getThemeColors(context)['textSecondary'],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Verifier Tokens',
                  style: TextStyle(
                    color: getThemeColors(context)['textSecondary'],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tokens List
          Builder(
            builder: (context) {
              logger.d(
                  "Building verifier tokens content, isEmpty: ${_verifierTokens.isEmpty}");

              if (_verifierTokens.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['secondaryBackground'] ??
                        Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: getThemeColors(context)['border'] ?? Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: getThemeColors(context)['textPrimary'] ??
                            Colors.black,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No verifier tokens found',
                        style: TextStyle(
                          color: getThemeColors(context)['textPrimary'] ??
                              Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                return Column(
                  children: List.generate(
                    _verifierTokens.length > 3 ? 3 : _verifierTokens.length,
                    (index) =>
                        _buildVerifierTokenCard(_verifierTokens[index], index),
                  ),
                );
              }
            },
          ),

          if (_verifierTokens.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: getThemeColors(context)['secondary'],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '+${_verifierTokens.length - 3} more tokens',
                  style: TextStyle(
                    color: getThemeColors(context)['textPrimary'],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerifierTokenCard(VerificationDetails token, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getThemeColors(context)['secondaryBackground'],
        border: Border.all(
          color: getThemeColors(context)['border']!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verifier address and tree count
          Row(
            children: [
              Expanded(
                child: Text(
                  '${token.verifier.substring(0, 6)}...${token.verifier.substring(token.verifier.length - 4)}',
                  style: TextStyle(
                    color: getThemeColors(context)['textPrimary'],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getThemeColors(context)['primary'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${token.numberOfTrees} 🌳',
                  style: TextStyle(
                    color: getThemeColors(context)['textSecondary'],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Description if available
          if (token.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              token.description.length > 50
                  ? '${token.description.substring(0, 50)}...'
                  : token.description,
              style: TextStyle(
                color: getThemeColors(context)['textPrimary'],
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Timestamp
          const SizedBox(height: 4),
          Text(
            'Verified: ${DateTime.fromMillisecondsSinceEpoch(token.timestamp * 1000).toString().substring(0, 10)}',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary']!,
              fontSize: 9,
            ),
          ),
        ],
      ),
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
    logger.d(
        "Building ProfileSectionWidget - isLoading: $_isLoading, isNotRegistered: $_isNotRegistered, userProfileData: ${_userProfileData?.name}");

    return Container(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? _buildLoadingState()
            : _isNotRegistered
                ? _buildNotRegisteredState()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _profileOverview(),
                        SizedBox(
                          width: 15,
                        ),
                        _tokenWidget(),
                        SizedBox(
                          width: 15,
                        ),
                        _verifierTokensWidget(),
                      ],
                    ),
                  ));
  }
}
