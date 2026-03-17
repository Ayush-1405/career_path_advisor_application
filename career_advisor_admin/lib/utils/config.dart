class AppConfig {
  // Production Backend URL
  // Note: If you get "Application not found", verify this URL in your Railway dashboard.
  static const String productionUrl =
      'https://careerpathadvisorapplication-production.up.railway.app/';

  static String get baseUrl {
    // Return production URL for all platforms by default
    // Ensure no trailing slash to avoid double slashes in paths
    return productionUrl.endsWith('/')
        ? productionUrl.substring(0, productionUrl.length - 1)
        : productionUrl;
  }
}
