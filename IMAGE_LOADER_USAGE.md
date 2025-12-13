# Image Loader Widget - Usage Guide

## Overview

The `ImageLoaderWidget` is a reusable Flutter widget that handles image loading from IPFS, HTTP, and other network sources with built-in loading indicators and error handling.

## Features

- **Loading Indicator**: Displays a circular progress indicator while images are being fetched
- **Progress Tracking**: Shows download progress (file size) for large images
- **Error Handling**: Graceful fallback UI when image loading fails
- **Customizable**: Supports custom dimensions, styling, and error widgets
- **CORS Support**: Pre-configured headers for cross-origin requests
- **Two Variants**: 
  - `ImageLoaderWidget` - For rectangular/general images
  - `CircularImageLoaderWidget` - For circular profile images

## Installation

The widget is already created in `lib/widgets/image_loader_widget.dart`. Import it where needed:

```dart
import 'package:tree_planting_protocol/widgets/image_loader_widget.dart';
```

## Usage Examples

### Basic Rectangular Image Loading

```dart
ImageLoaderWidget(
  imageUrl: 'https://example.com/image.jpg',
)
```

### With Custom Dimensions and Styling

```dart
ImageLoaderWidget(
  imageUrl: 'https://ipfs.io/ipfs/QmExample...',
  width: 200,
  height: 150,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
  placeholderColor: Colors.grey[200],
)
```

### Circular Profile Image (IPFS)

```dart
CircularImageLoaderWidget(
  imageUrl: _userProfileData.profilePhoto,
  radius: 50,
  placeholderColor: Colors.grey[300],
)
```

### With Custom Error Widget

```dart
ImageLoaderWidget(
  imageUrl: imageUrl,
  errorWidget: Center(
    child: Icon(
      Icons.image_not_supported,
      size: 50,
      color: Colors.red,
    ),
  ),
)
```

### With Custom Headers (for special IPFS gateways)

```dart
ImageLoaderWidget(
  imageUrl: pinataUrl,
  headers: {
    'Authorization': 'Bearer $pinataJwt',
    'Access-Control-Allow-Origin': '*',
  },
)
```

## Migration Guide

### Before (Original Code)

```dart
Image.network(
  _userProfileData!.profilePhoto,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    // Manual error handling
    return Icon(Icons.person);
  },
)
```

### After (Using ImageLoaderWidget)

```dart
CircularImageLoaderWidget(
  imageUrl: _userProfileData.profilePhoto,
  radius: 50,
)
```

## Widget Parameters

### ImageLoaderWidget

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `imageUrl` | String | Required | The URL of the image to load |
| `fit` | BoxFit | BoxFit.cover | How to fit the image in its container |
| `width` | double? | null | Width of the image container |
| `height` | double? | null | Height of the image container |
| `borderRadius` | BorderRadius? | BorderRadius.zero | Border radius for the image |
| `placeholderColor` | Color? | Colors.grey[300] | Background color while loading |
| `errorWidget` | Widget? | Default error UI | Custom widget to show on error |
| `headers` | Map<String, String>? | CORS headers | HTTP headers for the request |
| `loadingDuration` | Duration | 2 seconds | Animation duration |

### CircularImageLoaderWidget

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `imageUrl` | String | Required | The URL of the image to load |
| `radius` | double | Required | Radius of the circular image |
| `placeholderColor` | Color? | Colors.grey[300] | Background color while loading |
| `errorWidget` | Widget? | Default person icon | Custom widget to show on error |
| `headers` | Map<String, String>? | CORS headers | HTTP headers for the request |

## IPFS Gateway Support

The widget works with any IPFS gateway URL format:
- Pinata: `https://pinata.cloud/ipfs/{hash}`
- IPFS.io: `https://ipfs.io/ipfs/{hash}`
- Custom gateways: `https://your-gateway.com/ipfs/{hash}`

Example handling multiple gateways:

```dart
String selectIpfsGateway(String ipfsHash) {
  // Try Pinata first, then fallback to ipfs.io
  final pinataUrl = 'https://pinata.cloud/ipfs/$ipfsHash';
  return pinataUrl;
}

ImageLoaderWidget(
  imageUrl: selectIpfsGateway(treeNftImageHash),
)
```

## Advanced Usage

### Implementing Retry Logic

You can wrap the widget in a StatefulWidget to add retry functionality:

```dart
class RetryableImageLoader extends StatefulWidget {
  final String imageUrl;
  
  @override
  State<RetryableImageLoader> createState() => _RetryableImageLoaderState();
}

class _RetryableImageLoaderState extends State<RetryableImageLoader> {
  late String _currentUrl;
  
  @override
  void initState() {
    super.initState();
    _currentUrl = widget.imageUrl;
  }
  
  @override
  Widget build(BuildContext context) {
    return ImageLoaderWidget(
      imageUrl: _currentUrl,
      errorWidget: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Implement retry logic
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

## Performance Tips

1. **Cache Images**: Use a caching layer for frequently accessed images
2. **Optimize Sizes**: Request appropriately sized images from IPFS gateway
3. **Use IPFS Gateways Wisely**: Some gateways have rate limits; consider using a dedicated gateway

## Troubleshooting

### Images Not Loading from IPFS
- Check IPFS hash format
- Verify gateway is accessible
- Try alternative gateway (ipfs.io if Pinata fails)
- Check network connectivity

### Progress Not Showing
- Some servers don't report `Content-Length` header
- The widget will still load but without progress percentage

### Performance Issues
- Consider implementing image caching
- Use `cached_network_image` package if needed
- Optimize image sizes before storing on IPFS

## Files to Update

To use this widget throughout the app, update these files:

1. [lib/widgets/profile_widgets/profile_section_widget.dart](lib/widgets/profile_widgets/profile_section_widget.dart) - Profile photo loading
2. [lib/widgets/profile_widgets/user_profile_viewer_widget.dart](lib/widgets/profile_widgets/user_profile_viewer_widget.dart) - User profiles
3. [lib/widgets/nft_display_utils/recent_trees_widget.dart](lib/widgets/nft_display_utils/recent_trees_widget.dart) - NFT display
4. [lib/widgets/nft_display_utils/tree_nft_view_details_with_map.dart](lib/widgets/nft_display_utils/tree_nft_view_details_with_map.dart) - Tree details
5. [lib/pages/organisations_pages/organisation_details_page.dart](lib/pages/organisations_pages/organisation_details_page.dart) - Organization images

---

For more information or issues, refer to the Flutter Image documentation:
https://api.flutter.dev/flutter/widgets/Image-class.html
