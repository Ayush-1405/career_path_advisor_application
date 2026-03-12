import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/config.dart';

// This provider will be overridden in main.dart
final baseUrlProvider = StateProvider<String>((ref) {
  return AppConfig.baseUrl;
});
