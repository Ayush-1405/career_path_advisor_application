class AppConfig {
  // Backend base URL
  static const String productionUrl = 'http://172.20.10.1:8080';

  static const String _physicalDeviceIp = '172.20.10.1';

  static const String witAiToken = 'JNK2GIILYFJNSXMX4AWZE6KOFYSBLRSP';
  static const String witAiApiVersion = '20260319';

  static String get baseUrl {
    return productionUrl.endsWith('/')
        ? productionUrl.substring(0, productionUrl.length - 1)
        : productionUrl;
  }
}
