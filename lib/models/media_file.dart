/// ============================================================================
/// MEDIA STORAGE MODEL - IPFS + ARWEAVE SUPPORT
/// ============================================================================
/// Unified model for handling media stored on different decentralized networks.
/// Supports migration from IPFS to Arweave while maintaining backward compatibility.
///
/// For hackathon: Demonstrates how to structure data models to support
/// multiple storage backends, allowing flexibility in blockchain projects.
/// ============================================================================

/// Enum for storage provider types
enum StorageProvider {
  /// Legacy IPFS storage (centralized gateways, data may not be guaranteed)
  ipfs,
  /// Arweave permanent storage (guaranteed 200+ year persistence)
  arweave,
}

/// Model representing a single media file stored on decentralized network
class MediaFile {
  /// Unique identifier for the media (filename, UUID, etc)
  final String id;
  
  /// Which storage provider hosts this file
  final StorageProvider provider;
  
  /// Transaction ID / IPFS Hash
  /// For Arweave: 43-character transaction ID
  /// For IPFS: typically 46-character hash (QmXxx...)
  final String transactionId;
  
  /// Full URL to access the file
  /// Can be used directly in Image.network() widgets
  final String fileUrl;
  
  /// File size in bytes
  final int fileSize;
  
  /// MIME type (e.g., 'image/jpeg', 'image/png')
  final String? mimeType;
  
  /// Timestamp when file was uploaded
  final DateTime uploadedAt;
  
  /// Additional metadata about the file
  final Map<String, String>? metadata;
  
  /// Whether this transaction has been verified as available on network
  bool isVerified;

  MediaFile({
    required this.id,
    required this.provider,
    required this.transactionId,
    required this.fileUrl,
    required this.fileSize,
    this.mimeType,
    required this.uploadedAt,
    this.metadata,
    this.isVerified = false,
  });

  /// Convert to JSON for database storage or blockchain submission
  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider.name,
        'transactionId': transactionId,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'uploadedAt': uploadedAt.toIso8601String(),
        'metadata': metadata,
        'isVerified': isVerified,
      };

  /// Parse from JSON
  factory MediaFile.fromJson(Map<String, dynamic> json) => MediaFile(
        id: json['id'] as String,
        provider: StorageProvider.values.firstWhere(
          (e) => e.name == (json['provider'] ?? 'arweave'),
        ),
        transactionId: json['transactionId'] as String,
        fileUrl: json['fileUrl'] as String,
        fileSize: json['fileSize'] as int,
        mimeType: json['mimeType'] as String?,
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
        metadata: (json['metadata'] as Map<String, dynamic>?)
            ?.cast<String, String>(),
        isVerified: json['isVerified'] as bool? ?? false,
      );

  @override
  String toString() =>
      'MediaFile(id: $id, provider: ${provider.name}, txId: $transactionId)';
}

/// Model for NFT media assets - typically includes multiple media files
/// (main image, thumbnail, metadata, etc)
class NFTMediaAsset {
  /// NFT identifier (tree ID, collection ID, etc)
  final String nftId;
  
  /// Primary image for the NFT
  final MediaFile primaryImage;
  
  /// Additional images (gallery photos, etc)
  final List<MediaFile> additionalImages;
  
  /// Metadata file (JSON metadata stored on-chain)
  final MediaFile? metadataFile;
  
  /// Timestamp when this NFT asset collection was created
  final DateTime createdAt;
  
  /// Collection name (for batch uploads)
  final String? collectionName;

  NFTMediaAsset({
    required this.nftId,
    required this.primaryImage,
    this.additionalImages = const [],
    this.metadataFile,
    required this.createdAt,
    this.collectionName,
  });

  /// Get all media files (primary + additional)
  List<MediaFile> getAllMediaFiles() => [
        primaryImage,
        ...additionalImages,
        if (metadataFile != null) metadataFile!,
      ];

  /// Get all Arweave transaction IDs for on-chain storage
  List<String> getArweaveTransactionIds() =>
      getAllMediaFiles()
          .where((m) => m.provider == StorageProvider.arweave)
          .map((m) => m.transactionId)
          .toList();

  /// Count of verified files
  int get verifiedCount => getAllMediaFiles().where((m) => m.isVerified).length;

  /// Whether all files are verified
  bool get allVerified =>
      getAllMediaFiles().every((m) => m.isVerified);

  /// Convert to JSON for database/blockchain
  Map<String, dynamic> toJson() => {
        'nftId': nftId,
        'primaryImage': primaryImage.toJson(),
        'additionalImages': additionalImages.map((i) => i.toJson()).toList(),
        'metadataFile': metadataFile?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'collectionName': collectionName,
      };

  /// Parse from JSON
  factory NFTMediaAsset.fromJson(Map<String, dynamic> json) => NFTMediaAsset(
        nftId: json['nftId'] as String,
        primaryImage: MediaFile.fromJson(json['primaryImage'] as Map<String, dynamic>),
        additionalImages: (json['additionalImages'] as List?)
                ?.cast<Map<String, dynamic>>()
                .map(MediaFile.fromJson)
                .toList() ??
            [],
        metadataFile: json['metadataFile'] != null
            ? MediaFile.fromJson(json['metadataFile'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        collectionName: json['collectionName'] as String?,
      );
}

/// ============================================================================
/// USAGE EXAMPLES FOR HACKATHON
/// ============================================================================
///
/// Create a single Arweave media file:
/// ```dart
/// final mediaFile = MediaFile(
///   id: 'tree_nft_001_image',
///   provider: StorageProvider.arweave,
///   transactionId: 'fCuK_sHFD72tM6x5XhDXXXXXXXXXXXXXX',
///   fileUrl: 'https://arweave.net/fCuK_sHFD72tM6x5XhDXXXXXXXXXXXXXXX',
///   fileSize: 524288,
///   mimeType: 'image/jpeg',
///   uploadedAt: DateTime.now(),
/// );
/// ```
///
/// Create an NFT asset with multiple Arweave files:
/// ```dart
/// final nftAsset = NFTMediaAsset(
///   nftId: 'tree_001',
///   primaryImage: primaryMediaFile,
///   additionalImages: [photo1, photo2, photo3],
///   createdAt: DateTime.now(),
///   collectionName: 'Tree Planting Collection',
/// );
///
/// // Get all Arweave TX IDs to send to blockchain
/// final txIds = nftAsset.getArweaveTransactionIds();
/// await treeContract.createNFT(
///   treeId: 'tree_001',
///   imageTransactionIds: txIds,
/// );
/// ```
///
/// Save and restore from database:
/// ```dart
/// final json = nftAsset.toJson();
/// await database.saveNFTAsset(json);
///
/// final restored = NFTMediaAsset.fromJson(jsonFromDatabase);
/// ```
