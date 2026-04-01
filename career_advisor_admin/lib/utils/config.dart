class AppConfig {
  // Local Backend URL (Railway expired)
  static const String productionUrl = 'http://172.20.10.1:8080';

  static String get baseUrl {
    // Return production URL for all platforms by default
    // Ensure no trailing slash to avoid double slashes in paths
    return productionUrl.endsWith('/')
        ? productionUrl.substring(0, productionUrl.length - 1)
        : productionUrl;
  }
}
