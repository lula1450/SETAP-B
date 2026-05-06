import 'package:flutter/foundation.dart';

/// Helper class for handling URLs based on platform
class UrlHelper {
  /// Converts image URLs to work on both web and mobile platforms
  /// - For web: replaces 10.0.2.2 with localhost
  /// - For mobile: replaces localhost with 10.0.2.2
  static String getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (!imageUrl.startsWith('http')) return imageUrl;
    
    // For web, use localhost; for mobile, use 10.0.2.2
    if (kIsWeb) {
      return imageUrl.replaceFirst('http://10.0.2.2', 'http://localhost');
    }
    return imageUrl.replaceFirst('http://localhost', 'http://10.0.2.2');
  }
}
