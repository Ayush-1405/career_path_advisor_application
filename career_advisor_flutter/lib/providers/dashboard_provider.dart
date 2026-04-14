import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardData>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DashboardNotifier(apiService);
});

class DashboardData {
  final User? user;
  final List<dynamic> suggestions;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> socialStats;

  DashboardData({
    this.user,
    this.suggestions = const [],
    this.stats = const {
      'resumeUploaded': false,
      'resumeCount': 0,
      'suggestionsAvailable': 0,
      'skillsAssessed': false,
      'completionRate': 0,
      'totalActivities': 0,
      'recentActivities': [],
      'appliedCount': 0,
    },
    this.socialStats = const {'connectionsCount': 0},
  });

  DashboardData copyWith({
    User? user,
    List<dynamic>? suggestions,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? socialStats,
  }) {
    return DashboardData(
      user: user ?? this.user,
      suggestions: suggestions ?? this.suggestions,
      stats: stats ?? this.stats,
      socialStats: socialStats ?? this.socialStats,
    );
  }
}

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardData>> {
  final ApiService _apiService;

  DashboardNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData({bool background = false}) async {
    if (!background && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }

    try {
      // 1. User Profile
      final profileMap = await _apiService.getUserProfile();
      final user = User.fromJson(profileMap);

      // 2. Stats
      final statsMap = await _apiService.fetchDashboardStats();
      
      // 3. Social Stats
      final socialStatsMap = await _apiService.fetchUserSocialStats();

      // 4. Suggestions
      final suggestionsList = await _apiService.fetchCareerRecommendations();

      state = AsyncValue.data(DashboardData(
        user: user,
        stats: statsMap as Map<String, dynamic>? ?? {},
        socialStats: socialStatsMap as Map<String, dynamic>? ?? {'connectionsCount': 0},
        suggestions: suggestionsList as List<dynamic>? ?? [],
      ));
    } catch (e, st) {
      if (!background && state.valueOrNull == null) {
        state = AsyncValue.error(e, st);
      } else {
        // Silent error if background or have data
        print('Dashboard sync error: $e');
      }
    }
  }
}
