/// ============================================================================
/// ARWEAVE INTEGRATION GUIDE - HACKATHON REFERENCE
/// ============================================================================
/// 
/// This file demonstrates how Arweave has been integrated throughout the app
/// as a replacement for IPFS storage. Use this as a reference for implementing
/// Arweave in other parts of the application.
/// 
/// Key Architecture Decisions:
/// 1. Service Layer (arweave_services.dart):
///    - Handles all direct Arweave interactions
///    - Returns ArweaveUploadResult with transaction IDs
///    - Provides batch upload and verification functions
///
/// 2. Provider Layer (arweave_provider.dart):
///    - State management for upload operations
///    - Caches transaction IDs to avoid re-uploads
///    - Manages loading/error states for UI
///
/// 3. Model Layer (media_file.dart):
///    - Unified data structure for multiple storage backends
///    - Supports IPFS (legacy) and Arweave seamlessly
///    - Can be persisted to database/blockchain
///
/// 4. UI Layer (mint_nft_images.dart):
///    - Updated to use Arweave instead of IPFS
///    - Shows transaction IDs instead of IPFS hashes
///    - Collects TX IDs for blockchain submission
/// ============================================================================

// ============================================================================
// EXAMPLE 1: Single Image Upload with Arweave
// ============================================================================
///
/// Replace old IPFS upload:
/// ```dart
/// // OLD: IPFS
/// String? hash = await uploadToIPFS(imageFile, setLoadingState);
///
/// // NEW: Arweave
/// ArweaveUploadResult? result = await uploadToArweave(
///   imageFile,
///   setLoadingState,
///   metadata: {'owner': userId, 'type': 'profilePhoto'},
/// );
///
/// if (result != null) {
///   // result.transactionId = permanent reference (43 chars)
///   // result.fileUrl = https://arweave.net/{txId}
///   // Send result.transactionId to blockchain contract
///   await contract.updateUserProfile(userId, result.transactionId);
/// }
/// ```

// ============================================================================
// EXAMPLE 2: Batch Upload (NFT with Multiple Images)
// ============================================================================
///
/// ```dart
/// final arweaveProvider = Provider.of<ArweaveProvider>(context, listen: false);
///
/// // Upload 3 images
/// final results = await arweaveProvider.uploadBatchToArweave(
///   [imageFile1, imageFile2, imageFile3],
///   identifiers: ['nft_001_main', 'nft_001_photo1', 'nft_001_photo2'],
/// );
///
/// // Collect transaction IDs for blockchain
/// final txIds = results
///     .whereType<ArweaveUploadResult>()
///     .map((r) => r.transactionId)
///     .toList();
///
/// // Send to blockchain contract
/// await nftContract.createTreeNFT(
///   treeId: '001',
///   imageTransactionIds: txIds,
///   metadata: mintProvider.toNftMetadataJson(),
/// );
/// ```

// ============================================================================
// EXAMPLE 3: Using MintNftProvider with Arweave
// ============================================================================
///
/// ```dart
/// final mintProvider = Provider.of<MintNftProvider>(context, listen: false);
///
/// // After successful Arweave upload
/// mintProvider.addArweavePhoto(
///   'tree_image_1',
///   arweaveResult.transactionId,
///   metadata: {
///     'uploadedAt': DateTime.now().toIso8601String(),
///     'fileUrl': arweaveResult.fileUrl,
///   },
/// );
///
/// // Get all Arweave transaction IDs for blockchain
/// List<String> txIds = mintProvider.getArweaveTransactionIds();
///
/// // Export complete NFT metadata as JSON
/// Map<String, dynamic> metadata = mintProvider.toNftMetadataJson();
/// // Returns: {
/// //   'photos': {'ipfs': [], 'arweave': [txId1, txId2]},
/// //   'arweaveMetadata': {...},
/// //   ...other fields
/// // }
/// ```

// ============================================================================
// EXAMPLE 4: Media File Model (Database Storage)
// ============================================================================
///
/// ```dart
/// // Create Arweave media record for database
/// final mediaFile = MediaFile(
///   id: 'tree_001_image',
///   provider: StorageProvider.arweave,
///   transactionId: arweaveResult.transactionId,
///   fileUrl: arweaveResult.fileUrl,
///   fileSize: arweaveResult.fileSize,
///   mimeType: 'image/jpeg',
///   uploadedAt: DateTime.now(),
///   metadata: {'owner': userId, 'nftId': 'tree_001'},
///   isVerified: true,
/// );
///
/// // Save to database
/// final json = mediaFile.toJson();
/// await database.saveMedia(json);
///
/// // Later: Retrieve and use
/// final retrieved = MediaFile.fromJson(dbRecord);
/// Image.network(retrieved.fileUrl); // Uses Arweave gateway
/// ```

// ============================================================================
// EXAMPLE 5: NFT Asset with Multiple Media Files
// ============================================================================
///
/// ```dart
/// final nftAsset = NFTMediaAsset(
///   nftId: 'tree_001',
///   primaryImage: arweaveMediaMain,
///   additionalImages: [arweaveMediaPhoto1, arweaveMediaPhoto2],
///   metadataFile: arweaveMetadataJson,
///   createdAt: DateTime.now(),
///   collectionName: 'TreePlantingProtocol-Collection',
/// );
///
/// // Get all transaction IDs for blockchain storage
/// final txIds = nftAsset.getArweaveTransactionIds();
/// // => [mainImageTxId, photo1TxId, photo2TxId, metadataJsonTxId]
///
/// // Save NFT asset to database
/// await database.saveNFTAsset(nftAsset.toJson());
///
/// // Later: Display NFT with Arweave images
/// Image.network(nftAsset.primaryImage.fileUrl); // Permanent access
/// ```

// ============================================================================
// EXAMPLE 6: User Profile Photo Upload (Register Page Update)
// ============================================================================
///
/// Replace in register_user_page.dart:
/// ```dart
/// // OLD CODE:
/// String? hash = await uploadToIPFS(imageFile, setLoadingState);
///
/// // NEW CODE:
/// ArweaveUploadResult? result = await uploadToArweave(
///   imageFile,
///   (isUploading) {
///     setState(() {
///       _isUploading = isUploading;
///     });
///   },
///   metadata: {
///     'userId': walletProvider.address,
///     'type': 'profilePhoto',
///     'app': 'TreePlantingProtocol',
///   },
/// );
///
/// if (result != null) {
///   _profilePhotoTransactionId = result.transactionId;
///   // Send to blockchain
///   await contract.registerUser(
///     name: nameController.text,
///     profilePhotoTxId: result.transactionId,
///   );
/// }
/// ```

// ============================================================================
// EXAMPLE 7: Tree Details Page Update
// ============================================================================
///
/// Replace in tree_details_page.dart:
/// ```dart
/// // OLD: uploadToIPFS in _uploadImages()
/// for (File image in _selectedImages) {
///   final hash = await uploadToIPFS(image, setProgress);
///   _uploadedHashes.add(hash);
/// }
///
/// // NEW: uploadToArweave with verification
/// for (int i = 0; i < _selectedImages.length; i++) {
///   final result = await uploadToArweave(
///     _selectedImages[i],
///     (isUploading) {
///       setState(() {
///         _uploadProgress = ((i + 1) / _selectedImages.length * 100).toInt();
///       });
///     },
///     metadata: {
///       'treeId': widget.treeId,
///       'index': '${i + 1}',
///       'timestamp': DateTime.now().toIso8601String(),
///     },
///   );
///
///   if (result != null) {
///     _uploadedTransactionIds.add(result.transactionId);
///     
///     // Verify transaction is available before using
///     final isValid = await verifyArweaveTransaction(result.transactionId);
///     if (isValid) {
///       // Safe to store on blockchain
///       await contract.addTreePhoto(treeId, result.transactionId);
///     }
///   }
/// }
/// ```

// ============================================================================
// EXAMPLE 8: Organisation Logo Upload Update
// ============================================================================
///
/// Replace in create_organisation.dart:
/// ```dart
/// // OLD: _uploadImageToIPFS
/// Future<void> _uploadImageToArweave() async {
///   if (_selectedImage == null) return;
///
///   final result = await uploadToArweave(
///     _selectedImage!,
///     (isUploading) {
///       setState(() {
///         _isUploading = isUploading;
///       });
///     },
///     metadata: {
///       'organisationName': nameController.text,
///       'type': 'logo',
///     },
///   );
///
///   if (result != null) {
///     setState(() {
///       _uploadedTransactionId = result.transactionId;
///     });
///   }
/// }
/// ```

// ============================================================================
// EXAMPLE 9: Environment Variables (.env file)
// ============================================================================
///
/// Add these to your .env file for Arweave configuration:
/// ```
/// # Arweave Configuration
/// ARWEAVE_GATEWAY=https://arweave.net
/// ARWEAVE_API_KEY=your_api_key_here  # Optional: for faster uploads
///
/// # Legacy IPFS (keep for backward compatibility)
/// PINATA_API_KEY=your_pinata_key
/// PINATA_API_SECRET=your_pinata_secret
/// ```

// ============================================================================
// EXAMPLE 10: Blockchain Contract Integration
// ============================================================================
///
/// Smart Contract function for storing Arweave TX IDs:
/// ```solidity
/// // In your Tree NFT contract
/// struct TreeNFT {
///     uint256 id;
///     string name;
///     string species;
///     // OLD: string[] ipfsHashes;
///     // NEW: Store Arweave transaction IDs instead
///     string[] arweaveTransactionIds;
///     string[] arweaveImageUrls;
///     uint256 createdAt;
/// }
///
/// function createTreeNFT(
///     string memory name,
///     string memory species,
///     string[] memory arweaveTransactionIds
/// ) public {
///     TreeNFT memory newNFT = TreeNFT({
///         id: nextId++,
///         name: name,
///         species: species,
///         arweaveTransactionIds: arweaveTransactionIds,
///         arweaveImageUrls: _buildArweaveUrls(arweaveTransactionIds),
///         createdAt: block.timestamp
///     });
/// }
///
/// function _buildArweaveUrls(string[] memory txIds)
///     internal
///     pure
///     returns (string[] memory)
/// {
///     // Build full URLs: https://arweave.net/{txId}
///     string[] memory urls = new string[](txIds.length);
///     for (uint i = 0; i < txIds.length; i++) {
///         urls[i] = string(abi.encodePacked("https://arweave.net/", txIds[i]));
///     }
///     return urls;
/// }
/// ```

// ============================================================================
// TESTING CHECKLIST FOR ARWEAVE IMPLEMENTATION
// ============================================================================
///
/// - [x] Single image upload returns valid transaction ID
/// - [x] Batch uploads return multiple transaction IDs
/// - [x] Transaction IDs cached in ArweaveProvider
/// - [x] Arweave URLs accessible via Image.network()
/// - [x] Transaction verification works
/// - [x] MintNftProvider stores Arweave TX IDs correctly
/// - [x] MediaFile model supports Arweave
/// - [x] NFTMediaAsset exports TX IDs for blockchain
/// - [x] Error handling for failed uploads
/// - [x] UI displays Arweave TX IDs instead of hashes
/// - [x] Backward compatibility with IPFS
/// - [x] Metadata properly tagged in Arweave transactions

// ============================================================================
// PERFORMANCE CONSIDERATIONS
// ============================================================================
///
/// 1. Upload Speed:
///    - Arweave uploads are slower than IPFS (2-5 minutes typical)
///    - Show progress indicators to users
///    - Consider bundling multiple files with Bundlr service
///
/// 2. Cost:
///    - Arweave costs depend on file size (~5 cents/MB)
///    - Paid once, guaranteed forever
///    - IPFS had ongoing pinning costs
///
/// 3. Bandwidth:
///    - First access slower due to permanent storage
///    - Subsequent accesses cached by gateways
///    - Multiple gateway options available
///
/// 4. Verification:
///    - Always verify TX ID is available before storing on-chain
///    - Use verifyArweaveTransaction() function
///    - Add redundancy with multiple gateways

// ============================================================================
// HACKATHON TALKING POINTS
// ============================================================================
///
/// 1. Permanent Storage:
///    "Unlike IPFS which relies on pinning services, Arweave guarantees
///     data persistence through economic incentives. Your tree photos
///     are stored forever for ~5 cents per MB."
///
/// 2. On-Chain References:
///    "Arweave transaction IDs are immutable references that can be stored
///     on any blockchain. This enables true Web3 data integrity."
///
/// 3. Clean Architecture:
///    "We separated storage logic (service) from state management (provider),
///     making it trivial to swap between IPFS, Arweave, Filecoin, etc."
///
/// 4. User Trust:
///    "When you mint a Tree NFT, your photos are permanently stored on
///     Arweave and referenced by immutable transaction IDs in the contract.
///     This creates a true Web3-native application."
///
/// 5. Scalability:
///    "Batch uploads with our ArweaveProvider let you mint NFT collections
///     with confidence that all media is permanently available."

