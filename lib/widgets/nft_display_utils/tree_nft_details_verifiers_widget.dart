import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/wallet_provider.dart';
import 'package:tree_planting_protocol/utils/logger.dart';
import 'package:tree_planting_protocol/utils/services/contract_write_functions.dart';

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
    logger.d("User data, Verifiers and Owner");
    logger.d(userData);
    logger.d(verifiers);
    logger.d(owner);
    try {
      return Tree(
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
        verifiers: _parseVerifiers(verifiers),
        owner: owner,
      );
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

    for (var verifierEntry in verifiersData) {
      if (verifierEntry is List && verifierEntry.length >= 6) {
        try {
          verifiers.add(Verifier.fromList(verifierEntry));
        } catch (e) {
          logger.e("Error parsing verifier: $e");
        }
      }
    }

    return verifiers;
  }
}

Future<void> _removeVerifier(Verifier verifier, BuildContext context,
    Tree? treeDetails, Function loadTreeDetails) async {
  final messenger = ScaffoldMessenger.of(context);
  logger.d("Removing verifier: ${verifier.address}");
  try {
    final provider = Provider.of<WalletProvider>(context, listen: false);
    final result = await ContractWriteFunctions.removeVerification(
      walletProvider: provider,
      treeId: treeDetails!.id,
      address: verifier.address.toString(),
    );

    if (result.success) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text("Verifier removed successfully!"),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await loadTreeDetails();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Failed to remove verifier: ${result.errorMessage}"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Widget treeVerifiersSection(String? loggedInUser, Tree? treeDetails,
    Function loadTreeDetails, BuildContext context) {
  if (treeDetails?.verifiers == null || treeDetails!.verifiers.isEmpty) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_off,
            color: Colors.grey.shade400,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            "No Verifiers Yet",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This tree hasn't been verified by anyone",
            style: TextStyle(
              color: Colors.grey.shade500,
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
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified_user,
              color: Colors.blue.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              "Tree Verifiers",
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${treeDetails.verifiers.length}",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isOwner
              ? "Tap the ✕ to remove a verifier (owner only)"
              : "Users who have verified this tree",
          style: TextStyle(
            color: Colors.blue.shade600,
            fontSize: 14,
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
  return Container(
    margin: const EdgeInsets.only(bottom: 8.0),
    padding: const EdgeInsets.all(12.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(color: Colors.blue.shade100),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Verifier ${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    verifier.shortAddress,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (canRemove)
              GestureDetector(
                onTap: () => _showRemoveVerifierDialog(
                    verifier, index, context, treeDetails, loadTreeDetails),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.red.shade600,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
        if (verifier.description.isNotEmpty || verifier.proofHashes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (verifier.description.isNotEmpty) ...[
                    Text(
                      "Description:",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      verifier.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        verifier.formattedTimestamp,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      if (verifier.proofHashes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${verifier.proofHashes.length} proof${verifier.proofHashes.length != 1 ? 's' : ''}",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
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
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text("Remove Verifier"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure you want to remove this verifier?",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          verifier.address,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (verifier.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Description: ${verifier.description}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    "Verified: ${verifier.formattedTimestamp}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
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
                color: Colors.grey.shade700,
              ),
            ),
            _buildRemovalPoint("• Will require gas fees"),
            _buildRemovalPoint("• Cannot be undone"),
            _buildRemovalPoint("• Removes verification permanently"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _removeVerifier(
                  verifier, context, treeDetails, loadTreeDetails);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text("Remove"),
          ),
        ],
      );
    },
  );
}

Widget _buildRemovalPoint(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
      ),
    ),
  );
}
