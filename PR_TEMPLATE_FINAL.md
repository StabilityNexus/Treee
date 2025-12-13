## 🎯 Add Image Loader Widget for IPFS/Network Images

### Problem Solved
Users see blank/loading state while images fetch from IPFS without any progress indication or error handling. This creates a poor UX experience.

### Solution
Created a reusable `ImageLoaderWidget` that displays:
- ✅ Circular progress indicator while loading
- ✅ Download progress (file size tracking)
- ✅ Graceful error handling with fallback UI
- ✅ Support for IPFS gateways (Pinata, ipfs.io, custom)
- ✅ CORS-enabled headers

### What Changed

**New Widget:**
- `lib/widgets/image_loader_widget.dart` - 181 lines
  - `ImageLoaderWidget` - For rectangular images
  - `CircularImageLoaderWidget` - For circular images (profiles, logos)

**Updated 6 Files:**
1. `profile_section_widget.dart` - Profile photo loader
2. `user_profile_viewer_widget.dart` - User profiles
3. `recent_trees_widget.dart` - Tree NFT images
4. `organisation_details_page.dart` - Organisation logos
5. `tree_nft_view_details_with_map.dart` - Photo gallery
6. `tree_nft_details_verifiers_widget.dart` - Verification proofs

### Code Quality Impact
- 🔴 Removed: 8 duplicate `Image.network()` implementations
- 🟢 Added: 1 centralized widget
- 📉 Reduced: 50+ lines of error handling code
- ✨ Cleaner, more maintainable code

### How It Works

**Before:**
```dart
Image.network(
  imageUrl,
  errorBuilder: (context, error, stackTrace) {
    // Manual fallback logic
    // IPFS gateway retry logic
    // Error logging
  },
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator();
  },
)
```

**After:**
```dart
CircularImageLoaderWidget(
  imageUrl: imageUrl,
  radius: 50,
)
```

### Testing Covered
- ✓ Profile photos from IPFS
- ✓ Tree NFT images from HTTP
- ✓ Organisation logos from IPFS
- ✓ Verification proof images
- ✓ Error scenarios with fallback icons

### No Breaking Changes
- Drop-in replacement for `Image.network()`
- All existing functionality preserved
- Zero new dependencies
- Fully backward compatible

---

**Type:** Enhancement  
**Impact:** UI/UX  
**Risk:** Low (isolated widget, no logic changes)
