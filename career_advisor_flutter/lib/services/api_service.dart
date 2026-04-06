import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/network/dio_provider.dart';

part 'api_service.g.dart';

@Riverpod(keepAlive: true)
ApiService apiService(Ref ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
}

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // Helper to handle response
  dynamic _handleResponse(Response response) {
    
    final data = response.data;

    // Handle standard API response wrapper { success: true, data: ... }
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }

    return data;
  }

  // Skills Assessment
  Future<List<Map<String, dynamic>>> getSkillsQuestions() async {
    
    return [
      {
        'question': 'How would you rate your JavaScript skills?',
        'options': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
      },
      {
        'question': 'How would you rate your problem-solving skills?',
        'options': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
      },
      {
        'question': 'How would you rate your communication skills?',
        'options': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
      },
      {
        'question': 'How would you rate your Flutter/Dart skills?',
        'options': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
      },
      {
        'question': 'How familiar are you with Git version control?',
        'options': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
      },
    ];
  }

  // Auth endpoints
  Future<dynamic> verifyLoginOtp(String email, String code) async {
    final response = await _dio.post(
      '/api/auth/verify-login',
      queryParameters: {'email': email, 'code': code},
    );
    return _handleResponse(response);
  }

  Future<void> deleteUserProfile() async {
    await _dio.delete('/api/user/profile');
  }

  Future<dynamic> loginUser(String email, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    return _handleResponse(response);
  }

  Future<dynamic> registerUser(Map<String, dynamic> payload) async {
    final response = await _dio.post('/api/auth/register', data: payload);
    return _handleResponse(response);
  }

  Future<void> forgotPassword(String email, String redirectBaseUrl) async {
    await _dio.post(
      '/api/auth/forgot-password',
      queryParameters: {'email': email, 'redirectBaseUrl': redirectBaseUrl},
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
  }

  Future<void> validateResetToken(String token, String email) async {
    await _dio.get(
      '/api/auth/reset-password/validate',
      queryParameters: {'token': token, 'email': email},
    );
  }

  Future<void> resetPassword(
    String token,
    String email,
    String newPassword,
  ) async {
    await _dio.post(
      '/api/auth/reset-password',
      queryParameters: {
        'token': token,
        'email': email,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> sendEmailVerificationOtp(String email) async {
    await _dio.post(
      '/api/auth/verify/email/send',
      queryParameters: {'email': email},
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
  }

  Future<dynamic> verifyEmailOtp(String email, String code) async {
    final response = await _dio.post(
      '/api/auth/verify/email/confirm',
      queryParameters: {'email': email, 'code': code},
    );
    return _handleResponse(response);
  }

  Future<String> testEmailSend(String email) async {
    final resp = await _dio.get(
      '/api/auth/test-email',
      queryParameters: {'email': email},
    );
    final data = _handleResponse(resp);
    if (data is String) return data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Test email request completed';
  }

  // Career paths
  Future<dynamic> fetchCareerPaths() async {
    final response = await _dio.get('/api/career-paths');
    return _handleResponse(response);
  }

  Future<dynamic> fetchCareerPathsAdmin() async {
    final response = await _dio.get(
      '/api/career-paths',
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> fetchCareerPathById(String id) async {
    final response = await _dio.get('/api/career-paths/$id');
    return _handleResponse(response);
  }

  // Resume
  Future<dynamic> submitResume(Map<String, dynamic> payload) async {
    final response = await _dio.post('/api/resumes', data: payload);
    return _handleResponse(response);
  }

  /// New dynamic resume flow (no dummy data)
  Future<dynamic> uploadResumeFile({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final resp = await _dio.post(
      '/api/resume/upload',
      data: formData,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return _handleResponse(resp);
  }

  Future<dynamic> uploadResumeBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final resp = await _dio.post(
      '/api/resume/upload',
      data: formData,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return _handleResponse(resp);
  }

  Future<dynamic> fetchResumeProfile(String userId) async {
    final resp = await _dio.get('/api/resume/$userId');
    return _handleResponse(resp);
  }

  Future<dynamic> updateResumeProfile(Map<String, dynamic> payload) async {
    final resp = await _dio.put('/api/resume/update', data: payload);
    return _handleResponse(resp);
  }

  Future<Uint8List> generateResumePdf(String userId) async {
    final resp = await _dio.post(
      '/api/resume/generate-pdf',
      data: {'userId': userId},
      options: Options(responseType: ResponseType.bytes),
    );
    final data = resp.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw Exception('Invalid PDF bytes from server');
  }

  Future<List<dynamic>> fetchMyResumes() async {
    try {
      final response = await _dio.get('/api/resumes/me');
      final data = _handleResponse(response);
      return data is List ? data : [];
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteResume(String id) async {
    await _dio.delete('/api/resumes/$id');
  }

  Future<dynamic> getResumeAnalysis(String id) async {
    final response = await _dio.get('/api/resumes/$id/analysis');
    return _handleResponse(response);
  }

  Future<dynamic> uploadResume(String filePath, String fileName) async {
    try {
      // 1. Upload the resume file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final uploadResponse = await _dio.post(
        '/api/uploads/resume',
        data: formData,
      );
      final uploadData = _handleResponse(uploadResponse);

      if (uploadData is! Map<String, dynamic>) {
        throw Exception('Failed to upload resume file');
      }

      // 2. Submit resume for analysis
      // Backend expects JSON payload at /api/resumes
      final payload = {
        'fileName': fileName,
        'filePath': uploadData['path'] ?? filePath,
        'fileSize': int.tryParse(uploadData['size'] ?? '0') ?? 0,
        'fileType': fileName.split('.').last,
      };

      final response = await _dio.post('/api/resumes', data: payload);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Error uploading resume: $e');
      rethrow;
    }
  }

  Future<String?> uploadChatFile({String? filePath, Uint8List? bytes, required String filename}) async {
    final MultipartFile multipartFile;
    if (filePath != null && filePath.isNotEmpty) {
      multipartFile = await MultipartFile.fromFile(filePath, filename: filename);
    } else if (bytes != null) {
      multipartFile = MultipartFile.fromBytes(bytes, filename: filename);
    } else {
      return null;
    }

    try {
      final response = await _dio.post(
        '/api/uploads/chat',
        data: FormData.fromMap({'file': multipartFile}),
      );
      final data = _handleResponse(response);
      if (data is Map && data.containsKey('url')) {
        String url = data['url'];
        if (!url.startsWith('http')) {
          final base = _dio.options.baseUrl.endsWith('/')
              ? _dio.options.baseUrl.substring(0, _dio.options.baseUrl.length - 1)
              : _dio.options.baseUrl;
          return url.startsWith('/') ? '$base$url' : '$base/$url';
        }
        return url;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // User dashboard
  Future<dynamic> fetchDashboardStats() async {
    final response = await _dio.get('/api/users/me/stats');
    return _handleResponse(response);
  }

  Future<dynamic> trackUserActivity(
    String activityType, {
    Map<String, dynamic>? activityData,
  }) async {
    final response = await _dio.post(
      '/api/users/me/activity',
      queryParameters: {
        'activityType': activityType,
        if (activityData != null) 'activityData': jsonEncode(activityData),
      },
    );
    return _handleResponse(response);
  }

  // User Profile
  Future<dynamic> getUserProfile() async {
    final response = await _dio.get('/api/user/profile');
    return _handleResponse(response);
  }

  Future<dynamic> updateUserProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/user/profile', data: data);
    return _handleResponse(response);
  }

  /// Upload profile photo from a file path (mobile/desktop) or bytes (web).
  Future<dynamic> uploadProfilePhoto({
    String? filePath,
    Uint8List? bytes,
    required String filename,
  }) async {
    if ((filePath == null || filePath.isEmpty) &&
        (bytes == null || bytes.isEmpty)) {
      throw ArgumentError('Either filePath or bytes must be provided');
    }

    final MultipartFile multipartFile;
    if (filePath != null && filePath.isNotEmpty) {
      multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: filename,
      );
    } else {
      multipartFile = MultipartFile.fromBytes(bytes!, filename: filename);
    }

    // Backend expects POST /api/uploads/image with @RequestParam("file")
    Map<String, dynamic>? uploadData;
    DioException? lastError;
    final attempts = <Map<String, String>>[
      {'path': '/api/uploads/image', 'field': 'file'},
      {'path': '/api/uploads/image', 'field': 'image'},
    ];
    for (final attempt in attempts) {
      try {
        final uploadResponse = await _dio.post(
          attempt['path']!,
          data: FormData.fromMap({attempt['field']!: multipartFile}),
          options: Options(contentType: Headers.multipartFormDataContentType),
        );
        uploadData = _handleResponse(uploadResponse);
        lastError = null;
        break;
      } on DioException catch (e) {
        lastError = e;
        continue;
      }
    }
    if (uploadData == null && lastError != null) {
      throw lastError;
    }

    // 2. Update the user profile with the new image URL
    if (uploadData is Map<String, dynamic>) {
      String? imageUrl;
      if (uploadData.containsKey('url')) {
        imageUrl = uploadData['url']?.toString();
      } else if (uploadData.containsKey('fileUrl')) {
        imageUrl = uploadData['fileUrl']?.toString();
      } else if (uploadData.containsKey('path')) {
        imageUrl = uploadData['path']?.toString();
      } else if (uploadData.containsKey('location')) {
        imageUrl = uploadData['location']?.toString();
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (!imageUrl.startsWith('http')) {
          final base = _dio.options.baseUrl.endsWith('/')
              ? _dio.options.baseUrl.substring(
                  0,
                  _dio.options.baseUrl.length - 1,
                )
              : _dio.options.baseUrl;
          imageUrl = imageUrl.startsWith('/')
              ? '$base$imageUrl'
              : '$base/$imageUrl';
        }
        await updateUserProfile({'profilePictureUrl': imageUrl});
        return imageUrl;
      }
    }

    return uploadData;
  }

  // Career Suggestions

  Future<List<dynamic>> fetchRecentActivity({
    int page = 0,
    int limit = 10,
  }) async {
    try {
      // The standalone endpoint /api/users/me/activity is POST only.
      // We must fetch stats to get recent activities.
      final response = await _dio.get('/api/users/me/stats');
      final data = _handleResponse(response);

      if (data is Map<String, dynamic> &&
          data.containsKey('recentActivities')) {
        final activities = data['recentActivities'];
        if (activities is List) {
          return activities;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // AI Assistant
  Future<dynamic> chatWithAssistant(String message) async {
    final response = await _dio.post(
      '/api/assistant/chat',
      data: {'message': message},
    );
    return _handleResponse(response);
  }

  // Reports
  Future<dynamic> generateReport(String role, {String? name}) async {
    final response = await _dio.post(
      '/api/report/generate',
      data: {'role': role, 'name': name},
    );
    return _handleResponse(response);
  }

  Future<dynamic> downloadReportPdf(String role, {String? name}) async {
    final response = await _dio.post(
      '/api/report/pdf',
      data: {'role': role, 'name': name},
      options: Options(responseType: ResponseType.bytes),
    );
    // Return bytes directly as it's a file download
    return response.data;
  }

  // Applications
  Future<dynamic> applyForCareerPath(String careerPathId) async {
    final response = await _dio.post('/api/career-paths/$careerPathId/apply');
    return _handleResponse(response);
  }

  Future<dynamic> fetchMyApplications() async {
    final response = await _dio.get('/api/career-paths/my-applications');
    return _handleResponse(response);
  }

  Future<dynamic> fetchApplicationsByUserId(String userId) async {
    final response = await _dio.get(
      '/api/career-paths/user/$userId/applications',
    );
    return _handleResponse(response);
  }

  Future<dynamic> fetchAllApplications() async {
    final response = await _dio.get(
      '/api/admin/applications',
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> adminSeedApplications() async {
    final response = await _dio.post(
      '/api/admin/applications/seed',
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    final response = await _dio.put(
      '/api/admin/applications/$applicationId/status',
      data: {'status': status},
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  // Saved careers
  Future<List<dynamic>> fetchMySavedCareers() async {
    final response = await _dio.get('/api/career-paths/my-saved');
    final data = _handleResponse(response);
    return data is List ? data : [];
  }

  Future<void> saveCareerPath(String careerPathId) async {
    await _dio.post('/api/career-paths/$careerPathId/save');
  }

  Future<void> unsaveCareerPath(String careerPathId) async {
    await _dio.delete('/api/career-paths/$careerPathId/save');
  }

  // Admin dashboard
  Future<dynamic> fetchAdminDashboardStats() async {
    final response = await _dio.get(
      '/api/admin/dashboard/stats',
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> fetchAdminUsers({
    int page = 0,
    int size = 10,
    String? query,
  }) async {
    final Map<String, dynamic> queryParams = {'page': page, 'size': size};
    if (query != null && query.isNotEmpty) {
      queryParams['query'] = query;
      final response = await _dio.get(
        '/api/admin/users/search',
        queryParameters: queryParams,
        options: Options(extra: {'isAdmin': true}),
      );
      return _handleResponse(response);
    } else {
      final response = await _dio.get(
        '/api/admin/users',
        queryParameters: queryParams,
        options: Options(extra: {'isAdmin': true}),
      );
      return _handleResponse(response);
    }
  }

  Future<dynamic> deleteUser(String userId) async {
    final response = await _dio.delete(
      '/api/admin/users/$userId',
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateUser(String userId, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '/api/admin/users/$userId',
      data: data,
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateUserRoleAndStatus(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put(
      '/api/admin/users/$userId/role-status',
      data: data,
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> createCareerPath(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/api/career-paths',
      data: data,
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateCareerPath(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '/api/career-paths/$id',
      data: data,
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> deleteCareerPath(String id) async {
    final response = await _dio.delete(
      '/api/career-paths/$id',
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> fetchAdminResumes() async {
    final response = await _dio.get(
      '/api/admin/resumes',
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> fetchAdminAnalytics() async {
    final response = await _dio.get(
      '/api/admin/analytics',
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> fetchAdminReportsOverview({String? period}) async {
    final Map<String, dynamic> queryParams = {};
    if (period != null) {
      queryParams['period'] = period;
    }

    final response = await _dio.get(
      '/api/admin/reports/overview',
      queryParameters: queryParams,
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  /// Export admin report. Backend must implement GET /api/admin/reports/export?format=.
  /// Returns bytes or throws if endpoint is not available (e.g. 404).
  Future<List<int>> exportAdminReport(String format) async {
    try {
      final response = await _dio.get(
        '/api/admin/reports/export',
        queryParameters: {'format': format},
        options: Options(
          extra: {'isAdmin': true},
          responseType: ResponseType.bytes,
        ),
      );
      final data = response.data;
      if (data == null) return [];
      if (data is List<int>) return data;
      if (data is Uint8List) return data.toList();
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Report export is not available on the server.');
      }
      rethrow;
    }
  }

  Future<dynamic> fetchAdminSettings() async {
    final response = await _dio.get(
      '/api/admin/settings',
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateAdminSettings(Map<String, dynamic> payload) async {
    final response = await _dio.put(
      '/api/admin/settings',
      data: payload,
      options: Options(extra: {'isAdmin': true}),
    );
    return _handleResponse(response);
  }

  // Social Feed
  Future<dynamic> fetchFeed() async {
    final response = await _dio.get('/api/feed');
    return _handleResponse(response);
  }

  Future<dynamic> createPost(
    String content, {
    bool isAchievement = false,
    List<String>? mediaUrls,
    String? mediaType,
  }) async {
    final response = await _dio.post(
      '/api/feed',
      data: {
        'content': content,
        'isAchievement': isAchievement,
        if (mediaUrls != null && mediaUrls.isNotEmpty) 'mediaUrls': mediaUrls,
        if (mediaType != null) 'mediaType': mediaType,
      },
    );
    return _handleResponse(response);
  }

  /// Upload a single image or video file. Automatically picks the right endpoint.
  Future<String> uploadMediaFile(String filePath, String fileName) async {
    final ext = fileName.toLowerCase().split('.').last;
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext);
    final endpoint = isVideo ? '/api/uploads/video' : '/api/uploads/image';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      endpoint,
      data: formData,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        // 5 min timeout for large video files
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    final data = response.data;
    // The upload endpoint returns raw JSON (not wrapped in {success,data})
    String? url;
    if (data is Map) {
      url = data['url'] as String?;
    }
    if (url == null || url.isEmpty) {
      throw Exception('Upload failed: server did not return a URL');
    }
    return url;
  }

  Future<dynamic> likePost(String postId) async {
    final response = await _dio.post('/api/feed/$postId/like');
    return _handleResponse(response);
  }

  Future<dynamic> commentOnPost(String postId, String text) async {
    final response = await _dio.post(
      '/api/feed/$postId/comment',
      data: {'text': text},
    );
    return _handleResponse(response);
  }

  Future<dynamic> updatePost(String postId, String content) async {
    final response = await _dio.put(
      '/api/feed/$postId',
      data: {'content': content},
    );
    return _handleResponse(response);
  }

  Future<dynamic> deletePost(String postId) async {
    final response = await _dio.delete('/api/feed/$postId');
    return _handleResponse(response);
  }

  Future<dynamic> fetchMyPosts() async {
    final response = await _dio.get('/api/feed/my-posts');
    return _handleResponse(response);
  }

  Future<dynamic> fetchUserSocialStats({String? userId}) async {
    final endpoint = userId != null 
        ? '/api/connections/stats/$userId'
        : '/api/connections/stats';
    final response = await _dio.get(endpoint);
    return _handleResponse(response);
  }

  Future<dynamic> fetchUserProfile(String userId) async {
    final response = await _dio.get('/api/user/profile/$userId');
    return _handleResponse(response);
  }

  Future<dynamic> fetchUserPosts(String userId) async {
    final response = await _dio.get('/api/feed/user/$userId');
    return _handleResponse(response);
  }

  // Connections
  Future<dynamic> fetchMyNetwork() async {
    final response = await _dio.get('/api/connections/network');
    return _handleResponse(response);
  }

  Future<dynamic> fetchSuggestedFriends() async {
    final response = await _dio.get('/api/connections/suggestions');
    return _handleResponse(response);
  }

  Future<dynamic> followUser(String userId) async {
    final response = await _dio.post('/api/connections/follow/$userId');
    return _handleResponse(response);
  }

  Future<dynamic> fetchInvitations() async {
    final response = await _dio.get('/api/connections/invitations');
    return _handleResponse(response);
  }

  Future<dynamic> fetchSentRequests() async {
    final response = await _dio.get('/api/connections/sent');
    return _handleResponse(response);
  }

  Future<dynamic> acceptRequest(String userId) async {
    final response = await _dio.post('/api/connections/accept/$userId');
    return _handleResponse(response);
  }

  Future<dynamic> rejectRequest(String userId) async {
    final response = await _dio.post('/api/connections/reject/$userId');
    return _handleResponse(response);
  }

  // Chats
  Future<dynamic> fetchMyChats() async {
    final response = await _dio.get('/api/chats');
    return _handleResponse(response);
  }

  Future<List<dynamic>> fetchCareerRecommendations() async {
    final response = await _dio.get('/api/career-paths/recommendations');
    return _handleResponse(response);
  }

  Future<List<dynamic>> fetchCareerSuggestions() async {
    return fetchCareerRecommendations();
  }

  Future<dynamic> fetchMessages(String roomId) async {
    final response = await _dio.get('/api/chats/$roomId');
    return _handleResponse(response);
  }

  Future<String?> getOrCreateChatRoom(String otherUserId) async {
    try {
      final response = await _dio.get('/api/chats/room/$otherUserId');
      final data = _handleResponse(response);
      if (data is Map && data.containsKey('chatRoomId')) {
        return data['chatRoomId']?.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> sendMessage(String receiverId, String content) async {
    final response = await _dio.post(
      '/api/chats/send/$receiverId',
      data: {'content': content},
    );
    return _handleResponse(response);
  }

  Future<void> pingUserActivity() async {
    try {
      await _dio.post('/api/user/ping');
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getUserStatus(String userId) async {
    try {
      final response = await _dio.get('/api/user/status/$userId');
      final data = _handleResponse(response);
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> markMessagesAsRead(String roomId) async {
    try {
      await _dio.put('/api/chats/$roomId/read');
    } catch (_) {}
  }

  Future<void> deleteChat(String roomId) async {
    await _dio.delete('/api/chats/$roomId');
  }

  Future<void> clearMessages(String roomId) async {
    await _dio.delete('/api/chats/$roomId/messages');
  }

  Future<void> clearAllChats() async {
    await _dio.delete('/api/chats/all');
  }

  // Notifications
  Future<dynamic> fetchNotifications() async {
    final response = await _dio.get('/api/notifications');
    return _handleResponse(response);
  }

  Future<dynamic> markNotificationAsRead(String id) async {
    final response = await _dio.put('/api/notifications/$id/read');
    return _handleResponse(response);
  }

  Future<dynamic> markAllNotificationsAsRead() async {
    final response = await _dio.put('/api/notifications/read-all');
    return _handleResponse(response);
  }
}
