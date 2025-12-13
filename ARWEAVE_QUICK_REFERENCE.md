/// ============================================================================
/// ARWEAVE QUICK REFERENCE - 60 SECOND GUIDE
/// ============================================================================

/*

🔗 ARWEAVE vs IPFS - Quick Comparison
┌─────────────────────┬──────────────────────┬────────────────────┐
│ Feature             │ IPFS                 │ Arweave (NEW)      │
├─────────────────────┼──────────────────────┼────────────────────┤
│ Data Guarantee      │ Dependent on pinners │ 200+ years         │
│ Cost Model          │ Recurring pinning    │ One-time payment   │
│ Reference Type      │ Content hash         │ Transaction ID     │
│ Hash Format         │ Qm... (46 chars)     │ 43 char string     │
│ Storage Time        │ As long as pinned    │ Forever guaranteed │
│ Blockchain Ready    │ Sort of              │ Perfect fit        │
│ Gateway Reliability │ Variable             │ Designed for it    │
└─────────────────────┴──────────────────────┴────────────────────┘

═══════════════════════════════════════════════════════════════════════════════

📚 KEY FILES REFERENCE

┌─ Service (Low-level API)
│  lib/utils/services/arweave_services.dart
│  └─ Functions: uploadToArweave(), verifyArweaveTransaction()
│  └─ Model: ArweaveUploadResult
│
├─ Provider (State Management)
│  lib/providers/arweave_provider.dart
│  └─ Class: ArweaveProvider extends ChangeNotifier
│  └─ Purpose: Cache TX IDs, manage upload state
│
├─ Data Models
│  lib/models/media_file.dart
│  └─ Classes: MediaFile, NFTMediaAsset
│  └─ Purpose: Store media with provider type (IPFS vs Arweave)
│
└─ Updated UI
   lib/pages/mint_nft/mint_nft_images.dart
   └─ Now uses Arweave instead of IPFS

═══════════════════════════════════════════════════════════════════════════════

⚡ MOST COMMON USAGE PATTERNS

1️⃣ UPLOAD SINGLE IMAGE:
   
   final result = await uploadToArweave(
     imageFile,
     (isLoading) => setState(() { _loading = isLoading; }),
     metadata: {'owner': userId},
   );
   
   if (result != null) {
     print('TX ID: ${result.transactionId}');
     print('URL: ${result.fileUrl}');
     // Send result.transactionId to blockchain
   }

2️⃣ UPLOAD MULTIPLE IMAGES:
   
   final results = await uploadMultipleToArweave(
     [file1, file2, file3],
     (current, total) => print('$current/$total'),
   );
   
   final txIds = results
     .whereType<ArweaveUploadResult>()
     .map((r) => r.transactionId)
     .toList();

3️⃣ USE PROVIDER FOR STATE:
   
   final arweaveProvider = 
     Provider.of<ArweaveProvider>(context, listen: false);
   
   final result = await arweaveProvider.uploadFileToArweave(
     'my_file_id',
     imageFile,
   );

4️⃣ VERIFY BEFORE STORING ON-CHAIN:
   
   final isValid = await verifyArweaveTransaction(txId);
   if (isValid) {
     await contract.submitData(txId);
   }

═══════════════════════════════════════════════════════════════════════════════

🎯 IMPORTANT CONCEPTS

TX ID (Transaction ID):
  • Permanent reference to data
  • 43 character string
  • Can be stored in smart contracts
  • Enables Web3 data integrity
  • Example: "fCuK_sHFD72tM6x5XhDXXXXXXXXXXXXXX"

Gateway URL:
  • Full URL: "https://arweave.net/{txId}"
  • Use in Image.network() directly
  • Can fallback to other gateways

ArweaveUploadResult:
  • Returned from uploadToArweave()
  • Contains: transactionId, fileUrl, fileSize, uploadedAt
  • Has toJson() for persistence

Metadata:
  • Optional tags stored with transaction
  • Indexed by Arweave network
  • Useful for categorizing uploads
  • Example: {'owner': userId, 'type': 'nft'}

═══════════════════════════════════════════════════════════════════════════════

✅ CHECKLIST: Using Arweave in a New Feature

□ Import arweave_services and arweave_provider
□ Call uploadToArweave() to upload files
□ Capture the transactionId from result
□ Use ArweaveProvider for loading state
□ Create MediaFile model for persistence
□ Send transactionId to blockchain
□ Verify transaction before storing on-chain
□ Display TX ID (optional) for transparency
□ Cache TX ID in provider to avoid re-uploads
□ Handle errors gracefully

═══════════════════════════════════════════════════════════════════════════════

🔍 COMMON ERRORS & FIXES

ERROR: "No transaction ID in response"
FIX: Check Arweave gateway is accessible
     Verify file format and size

ERROR: "Upload timeout"
FIX: Files >5MB may take 5+ minutes
     Increase timeout or use Bundlr

ERROR: "Transaction not verified"
FIX: Wait a few seconds before verifying
     Check gateway accessibility
     Try alternative gateway

ERROR: "Image won't load"
FIX: Verify TX ID is correct
     Check arweave.net gateway is up
     Use alternative gateway URL

═══════════════════════════════════════════════════════════════════════════════

🌐 ARWEAVE GATEWAYS

Primary: https://arweave.net
Backup:  https://ar-io.dev
Backup:  https://gateway.irys.xyz

All serve the same data, can use any in Image.network()

═══════════════════════════════════════════════════════════════════════════════

💰 COST ESTIMATE

File Size    │ Arweave Cost  │ Forever Guarantee
─────────────┼───────────────┼──────────────────
100 KB       │ <$0.01        │ 200+ years
1 MB         │ ~$0.05        │ 200+ years
10 MB        │ ~$0.50        │ 200+ years
100 MB       │ ~$5.00        │ 200+ years

One-time cost, permanent storage. No recurring fees!

═══════════════════════════════════════════════════════════════════════════════

🎓 LEARNING RESOURCES

White Paper: https://arweave.org/yellow-paper.pdf
Docs: https://docs.arweave.org
API: https://arweave.dev/docs
Examples: https://github.com/ArweaveTeam/arweave-js

═══════════════════════════════════════════════════════════════════════════════

🚀 NEXT: Check these files for implementation examples:

• lib/utils/ARWEAVE_INTEGRATION_GUIDE.dart (10 examples)
• lib/pages/mint_nft/mint_nft_images.dart (working implementation)
• ARWEAVE_MIGRATION_SUMMARY.md (architecture overview)

═══════════════════════════════════════════════════════════════════════════════
*/

// Quick copy-paste template for new uploads:

/*
import 'package:tree_planting_protocol/utils/services/arweave_services.dart';
import 'package:tree_planting_protocol/providers/arweave_provider.dart';

// In your StatefulWidget:
final arweaveProvider = Provider.of<ArweaveProvider>(context, listen: false);

// Upload file:
final result = await uploadToArweave(
  selectedFile,
  (isLoading) => setState(() { _isUploading = isLoading; }),
  metadata: {
    'featureName': 'YourFeature',
    'timestamp': DateTime.now().toIso8601String(),
  },
);

if (result != null) {
  // Success! Use transaction ID
  print('🎉 Uploaded! TX: ${result.transactionId}');
  print('📸 View at: ${result.fileUrl}');
  
  // Store on blockchain or database
  final mediaFile = MediaFile(
    id: 'feature_file_1',
    provider: StorageProvider.arweave,
    transactionId: result.transactionId,
    fileUrl: result.fileUrl,
    fileSize: result.fileSize,
    uploadedAt: result.uploadedAt,
  );
}
*/
