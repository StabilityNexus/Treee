import 'package:flutter/material.dart';

/// A reusable widget that loads images from network sources (IPFS, HTTP, etc.)
/// with a loading indicator while the image is being fetched.
class ImageLoaderWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final Widget? errorWidget;
  final Map<String, String>? headers;
  final Duration loadingDuration;

  const ImageLoaderWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderColor,
    this.errorWidget,
    this.headers,
    this.loadingDuration = const Duration(seconds: 2),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          imageUrl,
          fit: fit,
          headers: headers ?? {'Access-Control-Allow-Origin': '*'},
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            final totalBytes = loadingProgress.expectedTotalBytes;
            final downloadedBytes = loadingProgress.cumulativeBytesLoaded;

            return Container(
              color: placeholderColor ?? Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: totalBytes != null
                            ? downloadedBytes / totalBytes
                            : null,
                        strokeWidth: 3,
                      ),
                    ),
                    if (totalBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
          },
        ),
      ),
    );
  }
}

/// A variant that displays images with a circular shape, useful for profile pictures
class CircularImageLoaderWidget extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? placeholderColor;
  final Widget? errorWidget;
  final Map<String, String>? headers;

  const CircularImageLoaderWidget({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholderColor,
    this.errorWidget,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          headers: headers ?? {'Access-Control-Allow-Origin': '*'},
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              color: placeholderColor ?? Colors.grey[300],
              child: Center(
                child: SizedBox(
                  width: radius * 0.8,
                  height: radius * 0.8,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: radius * 0.6,
                      color: Colors.grey[600],
                    ),
                  ),
                );
          },
        ),
      ),
    );
  }
}
