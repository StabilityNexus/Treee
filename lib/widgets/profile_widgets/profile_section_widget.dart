import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final String userAddress;

  const ProfileSectionWidget({super.key, required this.userAddress});

  @override
  State<ProfileSectionWidget> createState() => _ProfileSectionWidgetState();
}

class _ProfileSectionWidgetState extends State<ProfileSectionWidget> {
  bool _isLoading = false;
  String? _errorMessage = "";
  UserProfileData? _userProfileData;
  List<VerificationDetails> _verifierTokens = [];
  bool _isNotRegistered = false;
  int _displayedTokensCount = 5;
  String? _expandedTokenAddress;

  // For tree icon variety
  String _getTreeIcon(int index) {
    // Use modulo to cycle through tree-1.png to tree-13.png
    // Add offset based on previous index to avoid adjacent duplicates
    final treeNumber = ((index * 3) % 13) + 1; // Multiply by 3 for more variety
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

      logger.d("Calling ContractReadFunctions.getProfileDetails...");
      final String currentAddress = widget.userAddress;
      final result = await ContractReadFunctions.getProfileDetails(
        walletProvider: walletProvider,
        currentAddress: currentAddress,
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
            _userProfileData = null;
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
          _errorMessage = 'Error loading User profile details: $e';
          _userProfileData = null;
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
                              // Support both Pinata (legacy) and Web3.Storage URLs
                              if (originalUrl.contains('pinata.cloud') || 
                                  originalUrl.contains('w3s.link')) {
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
              width: 165,
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
                  child: Center(
                    child: Builder(builder: (context) {
                      return Text(
                          'Reported Spam : ${_userProfileData!.reportedSpam}',
                          style: TextStyle(
                            color: getThemeColors(context)['textPrimary'],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
              width: 165,
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
                            fontSize: 12,
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
              width: 165,
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
                  child: Center(
                    child: Builder(builder: (context) {
                      return Text(
                          'Verifications Revoked : ${_userProfileData!.verificationsRevoked}',
                          style: TextStyle(
                            color: getThemeColors(context)['textPrimary'],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
              width: 165,
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
                            fontSize: 12,
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

    final tokensToDisplay =
        _verifierTokens.take(_displayedTokensCount).toList();
    final hasMoreTokens = _verifierTokens.length > _displayedTokensCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            'Verifier Tokens',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),

          // Tokens display
          if (_verifierTokens.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No verifier tokens found',
                  style: TextStyle(
                    color: getThemeColors(context)['textPrimary'],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            // Bubble-style grid layout - wraps automatically
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.start,
              children: List.generate(
                tokensToDisplay.length,
                (index) => _buildTokenBubble(tokensToDisplay[index], index),
              ),
            ),

          // Load More button
          if (hasMoreTokens)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: SizedBox(
                  height: 40,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(buttonCircularRadius),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _displayedTokensCount += 5;
                        });
                      },
                      borderRadius: BorderRadius.circular(buttonCircularRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: getThemeColors(context)['primary'],
                          border: Border.all(
                            color: getThemeColors(context)['border']!,
                            width: buttonborderWidth,
                          ),
                          borderRadius:
                              BorderRadius.circular(buttonCircularRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Load More',
                              style: TextStyle(
                                color: getThemeColors(context)['textPrimary'],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.expand_more,
                              size: 16,
                              color: getThemeColors(context)['textPrimary'],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTokenBubble(VerificationDetails token, int index) {
    final double tokenAmount = token.numberOfTrees / 1e18;

    // Format with appropriate decimal places based on size
    String formattedAmount;
    if (tokenAmount >= 1000000) {
      formattedAmount = tokenAmount.toStringAsFixed(0);
    } else if (tokenAmount >= 1000) {
      formattedAmount = tokenAmount.toStringAsFixed(1);
    } else if (tokenAmount >= 1) {
      formattedAmount = tokenAmount.toStringAsFixed(2);
    } else {
      formattedAmount = tokenAmount.toStringAsFixed(4);
    }

    final bool isExpanded =
        _expandedTokenAddress == token.verifierPlanterTokenAddress;

    // Alternating colors for bubble effect
    final color = index % 2 == 0
        ? getThemeColors(context)['primary']
        : getThemeColors(context)['secondary'];

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedTokenAddress = null;
          } else {
            _expandedTokenAddress = token.verifierPlanterTokenAddress;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(
          minWidth: isExpanded ? 280 : 80,
          maxWidth: isExpanded ? 300 : 80,
          minHeight: isExpanded ? 120 : 80,
          maxHeight: isExpanded ? 140 : 80,
        ),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(isExpanded ? 16 : 40),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: getThemeColors(context)['border']!,
                width: buttonborderWidth,
              ),
              borderRadius: BorderRadius.circular(isExpanded ? 16 : 40),
            ),
            child: ClipRect(
              child: isExpanded
                  ? _buildExpandedTokenContent(token, formattedAmount)
                  : _buildCollapsedTokenContent(formattedAmount, index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedTokenContent(String amount, int index) {
    // Format large numbers (e.g., 1000000 -> 1M, 1500 -> 1.5K)
    String formatAmount(String amt) {
      try {
        double value = double.parse(amt);
        if (value >= 1000000) {
          return '${(value / 1000000).toStringAsFixed(1)}M';
        } else if (value >= 1000) {
          return '${(value / 1000).toStringAsFixed(1)}K';
        }
        return amt;
      } catch (e) {
        return amt;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          _getTreeIcon(index),
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to coin emoji if image fails to load
            return const Text(
              '🪙',
              style: TextStyle(fontSize: 24),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          formatAmount(amount),
          style: TextStyle(
            color: getThemeColors(context)['textPrimary'],
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildExpandedTokenContent(VerificationDetails token, String amount) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token Amount',
                      style: TextStyle(
                        color: getThemeColors(context)['textPrimary'],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      style: TextStyle(
                        color: getThemeColors(context)['textPrimary'],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: token.verifierPlanterTokenAddress));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Address copied!'),
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
          ),
          const SizedBox(height: 8),
          Text(
            'Contract Address',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${token.verifierPlanterTokenAddress.substring(0, 10)}...${token.verifierPlanterTokenAddress.substring(token.verifierPlanterTokenAddress.length - 8)}',
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 10,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (token.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              token.description.length > 40
                  ? '${token.description.substring(0, 40)}...'
                  : token.description,
              style: TextStyle(
                color: getThemeColors(context)['textPrimary'],
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
          Material(
            elevation: 4,
            shape: const CircleBorder(),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: getThemeColors(context)['primary'],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: Icon(
                Icons.person_add,
                size: 60,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Tree Planting Protocol!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: getThemeColors(context)['textPrimary'],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'You haven\'t registered yet. Create your profile to start your tree planting journey!',
            style: TextStyle(
              fontSize: 16,
              color: getThemeColors(context)['textPrimary'],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(buttonCircularRadius),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(buttonCircularRadius),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/register-user');
                  },
                  icon: Icon(
                    Icons.app_registration,
                    size: 20,
                    color: getThemeColors(context)['textPrimary'],
                  ),
                  label: Text(
                    'Register Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getThemeColors(context)['primary'],
                    foregroundColor: getThemeColors(context)['textPrimary'],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(buttonCircularRadius - 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(buttonCircularRadius),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(buttonCircularRadius),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: TextButton.icon(
                  onPressed: () => _loadUserProfileData(),
                  icon: Icon(
                    Icons.refresh,
                    size: 18,
                    color: getThemeColors(context)['textPrimary'],
                  ),
                  label: Text(
                    'Check Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: getThemeColors(context)['textPrimary'],
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: getThemeColors(context)['secondary'],
                    foregroundColor: getThemeColors(context)['textPrimary'],
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(buttonCircularRadius - 2),
                    ),
                  ),
                ),
              ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? _buildLoadingState()
          : _isNotRegistered
              ? _buildNotRegisteredState()
              : _userProfileData == null
                  ? _buildErrorState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First row: Profile overview and token stats
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _profileOverview(),
                              const SizedBox(width: 15),
                              _tokenWidget(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Second row: Verifier tokens
                        _verifierTokensWidget(),
                      ],
                    ),
    );
  }
}
