import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/config.dart';

final witAiServiceProvider = Provider<WitAiService>((ref) {
  return WitAiService();
});

class WitAiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.wit.ai',
    headers: {
      'Authorization': 'Bearer ${AppConfig.witAiToken}',
    },
  ));

  Future<Map<String, dynamic>> getMessageAnalysis(String text) async {
    final response = await _dio.get(
      '/message',
      queryParameters: {
        'v': AppConfig.witAiApiVersion,
        'q': text,
      },
    );
    return response.data;
  }
}
