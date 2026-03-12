import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import '../../providers/base_url_provider.dart';
import '../../utils/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../widgets/animated_screen.dart';

/// Staggered delay for entrance animations (ms)
int _staggerDelay(int index) => 50 + (index * 60);

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  User? _user;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _suggestions = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic> _stats = {
    'resumeUploaded': false,
    'resumeCount': 0,
    'suggestionsAvailable': 0,
    'skillsAssessed': false,
    'completionRate': 0,
    'totalActivities': 0,
    'recentActivities': [],
    'appliedCount': 0,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    _animationController.reset();

    try {
      final apiService = ref.read(apiServiceProvider);

      // Try to get fresh profile
      User? user;
      try {
        final profileMap = await apiService.getUserProfile();
        user = User.fromJson(profileMap);
      } catch (e) {
        debugPrint('Failed to fetch fresh profile: $e');
        if (!mounted) return;
        user = await ref.read(authServiceProvider).getCurrentUser();
      }

      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      setState(() {
        _user = user;
      });

      // Fetch data
      final results = await Future.wait([
        apiService.fetchDashboardStats().then((data) => data).catchError((e) {
          debugPrint('Error fetching stats: $e');
          return <String, dynamic>{};
        }),
        apiService.fetchCareerSuggestions().then((data) => data).catchError((
          e,
        ) {
          debugPrint('Error fetching suggestions: $e');
          return <Map<String, dynamic>>[];
        }),
        apiService.fetchMyResumes().then((data) => data).catchError((e) {
          debugPrint('Error fetching resumes: $e');
          return [];
        }),
        apiService.fetchMyApplications().then((data) => data).catchError((e) {
          debugPrint('Error fetching applications: $e');
          return [];
        }),
      ]);

      final stats = results[0] as Map<String, dynamic>? ?? {};
      final suggestions = results[1] as List<dynamic>? ?? [];
      final resumes = results[2] as List<dynamic>? ?? [];
      final applications = results[3] as List<dynamic>? ?? [];
      final activities = stats['recentActivities'];
      bool skillsAssessed = false;
      final rawSkills = stats['skillsAssessed'];
      if (rawSkills is bool) {
        skillsAssessed = rawSkills;
      } else if (rawSkills is String) {
        final v = rawSkills.trim().toLowerCase();
        skillsAssessed = v == 'true' || v == 'done' || v == 'completed';
      }
      if (!skillsAssessed && activities is List) {
        for (final a in activities) {
          if (a is Map) {
            final desc = (a['description'] ?? a['message'] ?? a['title'] ?? '')
                .toString()
                .toLowerCase();
            final type = (a['type'] ?? a['activityType'] ?? '')
                .toString()
                .toLowerCase();
            if (type.contains('skills_assessment') ||
                type.contains('skills_assessment_completed') ||
                desc.contains('skills assessment')) {
              skillsAssessed = true;
              break;
            }
          }
        }
      }
      // Fallback: local cache when user completed skills test (backend may not have synced)
      if (!skillsAssessed) {
        try {
          final prefs = await SharedPreferences.getInstance();
          skillsAssessed = prefs.getBool('skills_assessment_completed') ?? false;
        } catch (_) {}
      }

      // Prefer backend completionRate; use profile-based when backend returns 0/empty
      // blend with profile-based completion for better UX
      final rawRate = stats['completionRate'];
      final parsedRate = (rawRate is int)
          ? rawRate
          : (rawRate is num)
              ? (rawRate as num).round()
              : null;
      final rawTotal = stats['totalActivities'];
      final activitiesList = activities is List ? List<dynamic>.from(activities) : <dynamic>[];
      final parsedTotal = (rawTotal is int)
          ? rawTotal
          : (rawTotal is num)
              ? (rawTotal as num).toInt()
              : null;

      // Backend completionRate from UserProfileCompletion (resume+skills+career+edu).
      // When backend returns 0 or null, use profile form completion so user sees accurate status.
      final profileBasedRate = _user != null
          ? (_user!.calculatedCompletionPercentage * 100).round()
          : 0;
      final backendRate = parsedRate ?? 0;
      final finalCompletionRate = (backendRate > 0)
          ? backendRate
          : (_user?.profileCompletion ?? profileBasedRate);

      // Build activities: use backend list when present; otherwise synthesize from known data
      List<dynamic> finalActivities = activitiesList;
      if (finalActivities.isEmpty && _user != null) {
        finalActivities = _buildSyntheticActivities(
          resumesCount: resumes.length,
          applicationsCount: applications.length,
          skillsDone: skillsAssessed,
        );
      }

      if (mounted) {
        setState(() {
          _stats = {
            'resumeUploaded': stats['resumeUploaded'] ?? (resumes.isNotEmpty),
            'resumeCount': resumes.length,
            'suggestionsAvailable':
                stats['suggestionsAvailable'] ?? suggestions.length,
            'skillsAssessed': skillsAssessed,
            'completionRate': (finalCompletionRate.clamp(0, 100)).round(),
            'totalActivities': (parsedTotal != null && parsedTotal > 0)
                ? parsedTotal
                : finalActivities.length,
            'recentActivities': finalActivities,
            'appliedCount': applications.length,
          };
          _suggestions = suggestions;
          _isLoading = false;
        });
        _animationController.forward();
      }

      try {
        await ref.read(apiServiceProvider).trackUserActivity('dashboard_visit');
      } catch (e) {
        // Ignore tracking errors
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildSyntheticActivities({
    required int resumesCount,
    required int applicationsCount,
    required bool skillsDone,
  }) {
    final now = DateTime.now().toIso8601String();
    final activities = <Map<String, dynamic>>[];
    if (resumesCount > 0) {
      activities.add({
        'type': 'resume_uploaded',
        'activityType': 'resume_uploaded',
        'description': 'Resume uploaded',
        'message': 'Resume uploaded',
        'timestamp': now,
        'status': 'completed',
      });
    }
    if (applicationsCount > 0) {
      activities.add({
        'type': 'career_application',
        'activityType': 'career_application',
        'description': 'Applied to $applicationsCount career(s)',
        'message': 'Applied to career',
        'timestamp': now,
        'status': 'completed',
      });
    }
    if (skillsDone) {
      activities.add({
        'type': 'skills_assessment_completed',
        'activityType': 'skills_assessment_completed',
        'description': 'Skills assessment completed',
        'message': 'Skills assessment completed',
        'timestamp': now,
        'status': 'completed',
      });
    }
    if (activities.isEmpty) {
      activities.add({
        'type': 'profile_viewed',
        'activityType': 'profile_viewed',
        'description': 'Profile viewed',
        'message': 'Welcome! Complete your profile to get personalized suggestions.',
        'timestamp': now,
        'status': 'pending',
      });
    }
    return activities;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _user == null) {
      return AnimatedScreen(child: _buildShimmerLoading());
    }

    if (_error != null) {
      return AnimatedScreen(
        child: Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final completionRate =
        (_stats['completionRate'] as num?)?.round() ?? 0;
    final recentActivities =
        _stats['recentActivities'] is List ? _stats['recentActivities'] as List : <dynamic>[];

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: AppTheme.gray50,
        appBar: AppBar(
          title: const Text('Dashboard'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadData,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.userPrimaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Completion Card
              _buildAnimatedCard(
                index: 0,
                child: _buildProfileCompletionCard(completionRate),
              ),

              const SizedBox(height: 24),

              // 2. Key Stats Grid
              _buildAnimatedCard(
                index: 1,
                child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    title: 'Resumes',
                    value: '${_stats['resumeCount']}',
                    icon: Icons.description,
                    color: (_stats['resumeCount'] as int) > 0
                        ? Colors.green
                        : Colors.orange,
                    onTap: () => context.push('/my-resumes'),
                  ),
                  _buildStatCard(
                    title: 'Skills',
                    value: _stats['skillsAssessed'] ? 'Done' : 'Not Done',
                    icon: Icons.psychology,
                    color: _stats['skillsAssessed']
                        ? AppTheme.userPrimaryPurple
                        : Colors.blue,
                    onTap: () => context.push('/skills-assessment'),
                  ),
                  _buildStatCard(
                    title: 'Applied Careers',
                    value: '${_stats['appliedCount']}',
                    icon: Icons.send,
                    color: (_stats['appliedCount'] as int) > 0
                        ? Colors.deepOrange
                        : Colors.grey,
                    onTap: () => context.push('/my-applications'),
                  ),
                  _buildStatCard(
                    title: 'Activities',
                    value: '${_stats['totalActivities']}',
                    icon: Icons.history_edu,
                    color: Colors.indigo,
                    onTap: () => _showAllActivities(context),
                  ),
                ],
              ),
              ),

              const SizedBox(height: 32),

              // 3. Quick Actions
              _buildAnimatedCard(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio:
                    1.3, // Slightly taller for better touch target
                children: [
                  _buildActionCard(
                    title: 'My Resumes',
                    icon: Icons.folder_shared_outlined,
                    color: Colors.blue,
                    onTap: () => context.push('/my-resumes'),
                  ),
                  _buildActionCard(
                    title: 'Resume Builder',
                    icon: Icons.description_outlined,
                    color: Colors.indigo,
                    onTap: () => context.push('/resume-builder'),
                  ),
                  _buildActionCard(
                    title: 'Career Paths',
                    icon: Icons.explore_outlined,
                    color: AppTheme.userPrimaryPurple,
                    onTap: () => context.push('/suggestions'),
                  ),
                  // _buildActionCard(
                  //   title: 'My Applications',
                  //   icon: Icons.assignment,
                  //   color: Colors.amber.shade700,
                  //   onTap: () => context.push('/my-applications'),
                  // ),
                  // _buildActionCard(
                  //   title: 'Saved Careers',
                  //   icon: Icons.bookmark_border,
                  //   color: Colors.deepOrange,
                  //   onTap: () => context.pushNamed('saved_careers'),
                  // ),
                  _buildActionCard(
                    title: 'Skills Assessment',
                    icon: Icons.assignment_outlined,
                    color: Colors.teal,
                    onTap: () => context.push('/skills-assessment'),
                  ),
                  _buildActionCard(
                    title: 'AI Assistant',
                    icon: Icons.smart_toy_outlined,
                    color: Colors.pink,
                    onTap: () => context.push('/ai-assistant'),
                  ),
                ],
              ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 4. Recommended Career Paths
              if (_suggestions.isNotEmpty) ...[
                _buildAnimatedCard(
                  index: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recommended For You',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gray900,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/suggestions'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - value), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/suggestions'),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.userPrimaryBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.work_outline,
                                      color: AppTheme.userPrimaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    suggestion['careerPath'] ?? 'Career Path',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${suggestion['matchScore'] ?? 0}% Match',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 5. Recent Activity
              _buildAnimatedCard(
                index: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 16),
              if (recentActivities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: const Center(
                    child: Text(
                      'No recent activity yet. Start by uploading your resume!',
                      style: TextStyle(color: AppTheme.gray500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentActivities.take(5).length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final activity = recentActivities[index];
                    final timestamp = activity['timestamp'];
                    final type = activity['type']?.toString().toLowerCase();
                    final status = (activity['status'] ?? 'completed')
                        .toString()
                        .toLowerCase();
                    final message =
                        activity['message'] ??
                        activity['description'] ??
                        'Activity';

                    IconData iconData = Icons.history;
                    Color iconColor = AppTheme.gray600;

                    if (type != null) {
                      if (type.contains('resume')) {
                        iconData = Icons.description;
                        iconColor = Colors.green;
                      } else if (type.contains('skill')) {
                        iconData = Icons.psychology;
                        iconColor = Colors.purple;
                      } else if (type.contains('apply') ||
                          type.contains('application')) {
                        iconData = Icons.send;
                        iconColor = Colors.indigo;
                      } else if (type.contains('save')) {
                        iconData = Icons.bookmark;
                        iconColor = Colors.pink;
                      } else if (type.contains('login') ||
                          type.contains('dashboard_visit')) {
                        iconData = Icons.login;
                        iconColor = Colors.blue;
                      } else if (type.contains('profile')) {
                        iconData = Icons.person_outline;
                        iconColor = Colors.orange;
                      } else if (type.contains('email_verified') ||
                          type.contains('verification')) {
                        iconData = Icons.mark_email_read;
                        iconColor = Colors.teal;
                      } else if (type.contains('registration') ||
                          type.contains('user_registration')) {
                        iconData = Icons.person_add;
                        iconColor = Colors.green;
                      }
                    }

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (index * 80)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(iconData, color: iconColor, size: 20),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(
                              message,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: status.contains('completed') || status == 'done'
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.contains('completed') || status == 'done'
                                    ? 'Completed'
                                    : (status.contains('pending') ? 'Pending' : status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: status.contains('completed') || status == 'done'
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: timestamp != null
                            ? Text(
                                timestamp.toString(),
                                style: const TextStyle(
                                  color: AppTheme.gray500,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      body: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _shimmerCard(100)),
                  const SizedBox(width: 16),
                  Expanded(child: _shimmerCard(100)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _shimmerCard(100)),
                  const SizedBox(width: 16),
                  Expanded(child: _shimmerCard(100)),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                height: 20,
                width: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _shimmerCard(100)),
                  const SizedBox(width: 16),
                  Expanded(child: _shimmerCard(100)),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerCard(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildProfileCompletionCard(int completionRate) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: completionRate / 100),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.getUserGradient().copyWith(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.userPrimaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Status',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completionRate% Complete',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (completionRate < 100)
                      ElevatedButton(
                        onPressed: () => context.push('/profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.userPrimaryBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Complete Profile'),
                      )
                    else
                      const Chip(
                        label: Text('All Set!'),
                        backgroundColor: Colors.white24,
                        labelStyle: TextStyle(color: Colors.white),
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: value,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      strokeWidth: 8,
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, scale, _) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: _user?.profilePictureUrl != null &&
                                    (_user!.profilePictureUrl ?? '').isNotEmpty
                                ? Image.network(
                                    _resolveImageUrl(_user!.profilePictureUrl!),
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildProfileAvatarFallback();
                                    },
                                  )
                                : _buildProfileAvatarFallback(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = ref.read(baseUrlProvider);
    final baseClean = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return url.startsWith('/') ? '$baseClean$url' : '$baseClean/$url';
  }

  Widget _buildProfileAvatarFallback() {
    return Center(
      child: Text(
        _user?.name.isNotEmpty == true
            ? _user!.name[0].toUpperCase()
            : 'U',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.userPrimaryBlue,
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({
    required int index,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + _staggerDelay(index)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  void _showAllActivities(BuildContext context) {
    final activities = _stats['recentActivities'] is List
        ? _stats['recentActivities'] as List
        : <dynamic>[];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Activities',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No activities found.',
                    style: TextStyle(color: AppTheme.gray500),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: activities.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: AppTheme.gray600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        activity['message'] ??
                            activity['description'] ??
                            'Activity',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: activity['timestamp'] != null
                          ? Text(
                              activity['timestamp'].toString(),
                              style: const TextStyle(
                                color: AppTheme.gray500,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.gray500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: AppTheme.gray900,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
