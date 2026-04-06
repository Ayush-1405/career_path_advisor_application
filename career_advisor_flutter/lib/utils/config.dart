class AppConfig {
  // Backend base URL
  static const String productionUrl = 'http://172.20.10.2:8080';
  static String _overrideUrl = productionUrl;

  static const String witAiToken = 'JNK2GIILYFJNSXMX4AWZE6KOFYSBLRSP';
  static const String witAiApiVersion = '20260319';

  static String get baseUrl {
    return _overrideUrl.endsWith('/')
        ? _overrideUrl.substring(0, _overrideUrl.length - 1)
        : _overrideUrl;
  }

  static set baseUrl(String url) {
    _overrideUrl = url;
  }
}
