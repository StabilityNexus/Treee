import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/components/transaction_dialog.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/constants/ui/color_constants.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_functions/tree_nft_contract/tree_nft_contract_write_functions.dart';
import 'package:tree_planting_protocol/widgets/image_loader_widget.dart';

class Verifier {
  final String address;
  final int timestamp;
  final List<String> proofHashes;
  final String description;
  final bool isActive;
  final int verificationId;

  Verifier({
    required this.address,
    required this.timestamp,
    required this.proofHashes,
    required this.description,
    required this.isActive,
    required this.verificationId,
  });

  factory Verifier.fromList(List<dynamic> data) {
    logger.d("Creating Verifier from data: $data");
    try {
      return Verifier(
        address: data[0].toString(),
        timestamp: data[1] is BigInt
            ? (data[1] as BigInt).toInt()
            : int.parse(data[1].toString()),
        proofHashes: data[2] is List
            ? List<String>.from(data[2].map((p) => p.toString()))
            : [],
        description: data[3].toString(),
        isActive: data[4] == true || data[4].toString().toLowerCase() == 'true',
        verificationId: data[5] is BigInt
            ? (data[5] as BigInt).toInt()
            : int.parse(data[5].toString()),
      );
    } catch (e) {
      logger.e("Error in Verifier.fromList: $e");
      logger.e("Data that caused error: $data");
      rethrow;
    }
  }

  String get formattedTimestamp {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String get shortAddress {
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }
}

class Tree {
  final int id;
  final int latitude;
  final int longitude;
  final int planting;
  final int death;
  final String species;
  final String imageUri;
  final String qrIpfsHash;
  final String metadata;
  final List<String> photos;
  final String geoHash;
  final List<String> ancestors;
  final int lastCareTimestamp;
  final int careCount;
  final List<Verifier> verifiers;
  final String owner;

  Tree({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.planting,
    required this.death,
    required this.species,
    required this.imageUri,
    required this.qrIpfsHash,
    required this.metadata,
    required this.photos,
    required this.geoHash,
    required this.ancestors,
    required this.lastCareTimestamp,
    required this.careCount,
    required this.verifiers,
    required this.owner,
  });

  factory Tree.fromContractData(
      List<dynamic> userData, List<dynamic> verifiers, String owner) {
    try {
      final parsedVerifiers = _parseVerifiers(verifiers);
      final tree = Tree(
        id: _toInt(userData[0]),
        latitude: _toInt(userData[1]),
        longitude: _toInt(userData[2]),
        planting: _toInt(userData[3]),
        death: _toInt(userData[4]),
        species: userData[5]?.toString() ?? '',
        imageUri: userData[6]?.toString() ?? '',
        qrIpfsHash: userData[7]?.toString() ?? '',
        metadata: userData[8]?.toString() ?? '',
        photos: userData[9] is List
            ? List<String>.from(userData[9].map((p) => p.toString()))
            : [],
        geoHash: userData[10]?.toString() ?? '',
        ancestors: userData[11] is List
            ? List<String>.from(userData[11].map((a) => a.toString()))
            : [],
        lastCareTimestamp: _toInt(userData[12]),
        careCount: _toInt(userData[13]),
        verifiers: parsedVerifiers,
        owner: owner,
      );
      return tree;
    } catch (e) {
      return Tree(
        id: 0,
        latitude: 0,
        longitude: 0,
        planting: 0,
        death: 0,
        species: 'Unknown',
        imageUri: '',
        qrIpfsHash: '',
        metadata: '',
        photos: [],
        geoHash: '',
        ancestors: [],
        lastCareTimestamp: 0,
        careCount: 0,
        verifiers: [],
        owner: '',
      );
    }
  }

  static int _toInt(dynamic value) {
    if (value is BigInt) return value.toInt();
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static List<Verifier> _parseVerifiers(List<dynamic> verifiersData) {
    List<Verifier> verifiers = [];
    for (int i = 0; i < verifiersData.length; i++) {
      var verifierEntry = verifiersData[i];

      try {
        if (verifierEntry is String) {
          verifiers.add(Verifier(
            address: verifierEntry,
            timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            proofHashes: [],
            description: "Verified",
            isActive: true,
            verificationId: i,
          ));
        } else if (verifierEntry is List) {
          if (verifierEntry.isNotEmpty) {
            if (verifierEntry.length == 1) {
              verifiers.add(Verifier(
                address: verifierEntry[0].toString(),
                timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                proofHashes: [],
                description: "Verified",
                isActive: true,
                verificationId: i,
              ));
            } else if (verifierEntry.length >= 6) {
              verifiers.add(Verifier.fromList(verifierEntry));
            } else {
              verifiers.add(Verifier(
                address: verifierEntry[0].toString(),
                timestamp: verifierEntry.length > 1
                    ? (verifierEntry[1] is BigInt
                        ? (verifierEntry[1] as BigInt).toInt()
                        : int.tryParse(verifierEntry[1].toString()) ??
                            DateTime.now().millisecondsSinceEpoch ~/ 1000)
                    : DateTime.now().millisecondsSinceEpoch ~/ 1000,
                proofHashes:
                    verifierEntry.length > 2 && verifierEntry[2] is List
                        ? List<String>.from(
                            verifierEntry[2].map((p) => p.toString()))
                        : [],
                description: verifierEntry.length > 3
                    ? verifierEntry[3].toString()
                    : "Verified",
                isActive: verifierEntry.length > 4
                    ? (verifierEntry[4] == true ||
                        verifierEntry[4].toString().toLowerCase() == 'true')
                    : true,
                verificationId: verifierEntry.length > 5
                    ? (verifierEntry[5] is BigInt
                        ? (verifierEntry[5] as BigInt).toInt()
                        : int.tryParse(verifierEntry[5].toString()) ?? i)
                    : i,
              ));
            }
            logger.d("Successfully parsed verifier $i");
          } else {
            logger.w("Verifier entry $i is an empty list");
          }
        } else {
          logger.w(
              "Verifier entry $i is neither string nor list: ${verifierEntry.runtimeType}");
        }
      } catch (e) {
        logger.e("Error parsing verifier $i: $e");
        if (verifierEntry != null) {
          verifiers.add(Verifier(
            address: verifierEntry.toString(),
            timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            proofHashes: [],
            description: "Verified (partial data)",
            isActive: true,
            verificationId: i,
          ));
        }
      }
    }

    logger.d("Total parsed verifiers: ${verifiers.length}");
    return verifiers;
  }
}

void _copyToClipboard(String text, BuildContext context) {
  Clipboard.setData(ClipboardData(text: text));

  final scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text("Address copied to clipboard!"),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

Future<void> _removeVerifier(Verifier verifier, BuildContext context,
    Tree? treeDetails, Function loadTreeDetails) async {
  logger.d("Removing verifier: ${verifier.address}");

  try {
    final provider = Provider.of<WalletProvider>(context, listen: false);
    final result = await ContractWriteFunctions.removeVerification(
      walletProvider: provider,
      treeId: treeDetails!.id,
      address: verifier.address.toString(),
    );

    if (context.mounted) {
      if (result.success) {
        TransactionDialog.showSuccess(
          context,
          title: 'Verifier Removed!',
          message: 'The verifier has been successfully removed.',
          transactionHash: result.transactionHash,
          onClose: () async {
            await loadTreeDetails();
          },
        );
      } else {
        TransactionDialog.showError(
          context,
          title: 'Failed to Remove Verifier',
          message: result.errorMessage ?? 'An unknown error occurred',
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      TransactionDialog.showError(
        context,
        title: 'Error',
        message: e.toString(),
      );
    }
  }
}

Widget treeVerifiersSection(
  String? loggedInUser,
  Tree? treeDetails,
  Function loadTreeDetails,
  BuildContext context, {
  int currentCount = 0,
  int totalCount = 0,
  int visibleCount = 0,
}) {
  final themeColors = getThemeColors(context);

  if (treeDetails?.verifiers == null || treeDetails!.verifiers.isEmpty) {
    logger.d("No verifiers found, showing empty state");
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: getThemeColors(context)['background']!,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: getThemeColors(context)['border']!, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_off,
            color: getThemeColors(context)['icon'],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            "No Verifiers Yet",
            style: TextStyle(
              color: getThemeColors(context)['textPrimary'],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This tree hasn't been verified by anyone",
            style: TextStyle(
              color: getThemeColors(context)['textPrimary']!,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  final isOwner = treeDetails.owner == loggedInUser;

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 16.0),
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: themeColors['background'],
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(color: Colors.black, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: themeColors['primary'],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  "Tree Verifiers",
                  style: TextStyle(
                    color: getThemeColors(context)['textPrimary']!,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (visibleCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColors['primary'],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  "$currentCount of $visibleCount",
                  style: TextStyle(
                    color: themeColors['textPrimary'],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isOwner
              ? "Tap any verifier to view details • Tap ✕ to remove (owner only)"
              : "Tap any verifier to view verification details",
          style: TextStyle(
            color: themeColors['textSecondary']!,
            fontSize: 12,
          ),
        ),
        if (visibleCount > currentCount)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Scroll down to load more verifiers",
              style: TextStyle(
                color: themeColors['textSecondary']!,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 16),
        ...treeDetails.verifiers.asMap().entries.map((entry) {
          final index = entry.key;
          final verifier = entry.value;
          return _buildVerifierCard(
              verifier, index, isOwner, loadTreeDetails, treeDetails, context);
        }),
      ],
    ),
  );
}

Widget _buildVerifierCard(Verifier verifier, int index, bool canRemove,
    Function loadTreeDetails, Tree? treeDetails, BuildContext context) {
  final themeColors = getThemeColors(context);

  return Container(
    margin: const EdgeInsets.only(bottom: 8.0),
    child: Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showVerifierDetailsModal(verifier, context, themeColors);
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: primaryYellowColor),
                boxShadow: [
                  BoxShadow(
                    color: themeColors['primaryLight']!,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: getThemeColors(context)['primary'],
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: themeColors['primary']!,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _copyToClipboard(verifier.address, context);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    verifier.shortAddress,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                        color: getThemeColors(
                                            context)['textPrimary']),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.copy,
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                            if (verifier.proofHashes.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      size: 10,
                                      color: getThemeColors(context)['icon'],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${verifier.proofHashes.length}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: getThemeColors(
                                            context)['textPrimary'],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              verifier.formattedTimestamp,
                              style: TextStyle(
                                fontSize: 11,
                                color: getThemeColors(context)['textPrimary'],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (canRemove)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showRemoveVerifierDialog(
                      verifier, index, context, treeDetails, loadTreeDetails);
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: getThemeColors(context)['error'],
                    shape: BoxShape.circle,
                    border: Border.all(width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: getThemeColors(context)['icon'],
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

void _showVerifierDetailsModal(
    Verifier verifier, BuildContext context, Map<String, Color> themeColors) {
  final screenSize = MediaQuery.of(context).size;
  final dialogWidth =
      screenSize.width * 0.9 > 400 ? 400.0 : screenSize.width * 0.9;
  final dialogHeight =
      screenSize.height * 0.8 > 500 ? 500.0 : screenSize.height * 0.8;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: dialogHeight,
            maxWidth: dialogWidth,
          ),
          decoration: BoxDecoration(
            color: getThemeColors(context)['background'],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: getThemeColors(context)['primary'],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  border: const Border(
                    bottom: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: getThemeColors(context)['background'],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: getThemeColors(context)['primary'],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Verification Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: getThemeColors(context)['textPrimary'],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close,
                          color: getThemeColors(context)['textPrimary']),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_circle,
                                  color: getThemeColors(context)['icon'],
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Verifier Address",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      getThemeColors(context)['textPrimary']!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () =>
                                _copyToClipboard(verifier.address, context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: getThemeColors(context)['background'],
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      verifier.address,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                        color: getThemeColors(
                                            context)['textPrimary'],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: getThemeColors(context)['primary'],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                          "Verified On",
                          verifier.formattedTimestamp,
                          Icons.access_time,
                          context),
                      const SizedBox(height: 12),
                      if (verifier.description.isNotEmpty) ...[
                        _buildDetailRow("Description", verifier.description,
                            Icons.description, context),
                        const SizedBox(height: 12),
                      ],
                      if (verifier.proofHashes.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.photo_library,
                                color: getThemeColors(context)['icon'],
                                size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Proof Images (${verifier.proofHashes.length})",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: getThemeColors(context)['textPrimary'],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: verifier.proofHashes.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.black, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: ImageLoaderWidget(
                                    imageUrl: verifier.proofHashes[index],
                                    fit: BoxFit.cover,
                                    placeholderColor: Colors.grey.shade100,
                                    errorWidget: Container(
                                      color: Colors.grey.shade100,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey.shade400,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: verifier.isActive
                              ? getThemeColors(context)['primary']
                              : getThemeColors(context)['secondary'],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              verifier.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: getThemeColors(context)['textPrimary'],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              verifier.isActive
                                  ? "Active Verification"
                                  : "Verification Removed",
                              style: TextStyle(
                                color: getThemeColors(context)['textPrimary'],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getThemeColors(context)['primary'],
                          foregroundColor:
                              getThemeColors(context)['textPrimary'],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildDetailRow(
    String label, String value, IconData icon, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: getThemeColors(context)['icon'], size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: getThemeColors(context)['textPrimary'],
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: getThemeColors(context)['background'],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ),
    ],
  );
}

void _showRemoveVerifierDialog(Verifier verifier, int index,
    BuildContext context, Tree? treeDetails, Function loadTreeDetails) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        backgroundColor: getThemeColors(context)['background'],
        title: Row(
          children: [
            Icon(Icons.warning, color: getThemeColors(context)['error']),
            const SizedBox(width: 8),
            Text(
              "Remove Verifier",
              style: TextStyle(
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to remove this verifier?",
              style: TextStyle(
                fontSize: 16,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getThemeColors(context)['background'],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person,
                          color: getThemeColors(context)['primary']),
                      const SizedBox(width: 8),
                      Text(
                        "Address:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: getThemeColors(context)['textPrimary'],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _copyToClipboard(verifier.address, context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: getThemeColors(context)['background'],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              verifier.address,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: getThemeColors(context)['textPrimary'],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.copy,
                            size: 14,
                            color: getThemeColors(context)['primary'],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (verifier.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Description: ${verifier.description}",
                      style: TextStyle(
                        fontSize: 12,
                        color: getThemeColors(context)['textSecondary'],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    "Verified: ${verifier.formattedTimestamp}",
                    style: TextStyle(
                      fontSize: 11,
                      color: getThemeColors(context)['textSecondary'],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "This action:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: getThemeColors(context)['textPrimary'],
              ),
            ),
            _buildRemovalPoint("• Will require gas fees", context),
            _buildRemovalPoint("• Cannot be undone", context),
            _buildRemovalPoint("• Removes verification permanently", context),
          ],
        ),
        actions: [
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: getThemeColors(context)['textPrimary'],
                  ),
                ),
              ),
            ),
          ),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _removeVerifier(
                      verifier, context, treeDetails, loadTreeDetails);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: getThemeColors(context)['error'],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text("Remove",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildRemovalPoint(String text, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: getThemeColors(context)['textSecondary'],
      ),
    ),
  );
}
