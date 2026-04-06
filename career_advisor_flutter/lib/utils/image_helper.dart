import 'config.dart';

class ImageHelper {
  static String? getImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final baseUrl = AppConfig.baseUrl; // No trailing slash
    final formattedUrl = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$formattedUrl';
  }
}
