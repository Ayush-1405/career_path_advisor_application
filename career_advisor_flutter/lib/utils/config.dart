import 'dart:io';

class AppConfig {
  // Backend base URL
  static const String productionUrl =
      'https://careerpathadvisorapplication-production.up.railway.app/';

  static const String _physicalDeviceIp =
      '172.20.10.2'; // Updated automatically

  static const String witAiToken = 'JNK2GIILYFJNSXMX4AWZE6KOFYSBLRSP';
  static const String witAiApiVersion = '20260319';

  static String get baseUrl {
    return productionUrl.endsWith('/')
        ? productionUrl.substring(0, productionUrl.length - 1)
        : productionUrl;
  }
}
