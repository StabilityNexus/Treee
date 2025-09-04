import 'package:tree_planting_protocol/utils/logger.dart';

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
  final List<String> verifiers;
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
        verifiers: List<String>.from(verifiers.map((a) => a.toString())),
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
}
