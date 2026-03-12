import 'dart:io';

class AppConfig {
  // Backend base URL - Updated to Deployed Server
  static const String _deployedUrl =
      'https://careeradvisoraiapplication-production.up.railway.app';

  static String get baseUrl {
    // Return the deployed production URL
    return _deployedUrl;
  }
}
