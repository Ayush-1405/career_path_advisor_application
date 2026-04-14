import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/user.dart';
import '../../providers/social_feed_provider.dart';
import '../../models/post.dart';
import '../../providers/base_url_provider.dart';

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
  Map<String, dynamic> _socialStats = {'connectionsCount': 0};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );

    // Populate initial state from provider if data is already available
    final initialData = ref.read(dashboardProvider).valueOrNull;
    if (initialData != null) {
      _user = initialData.user;
      _stats = initialData.stats;
      _socialStats = initialData.socialStats;
      _suggestions = initialData.suggestions;
      _isLoading = false;
      _animationController.forward();
    } else {
      // Trigger initial load if no data exists
      ref.read(dashboardProvider.notifier).loadData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    ref.read(dashboardProvider.notifier).loadData(background: true);
    _animationController.reset();
    _animationController.forward();
  }

  List<Map<String, dynamic>> _buildSyntheticActivities({
    required int resumesCount,
    required int applicationsCount,
    required bool skillsDone,
    User? user,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Sync provider data to local state
    ref.listen<AsyncValue<DashboardData>>(dashboardProvider, (previous, next) {
      next.whenData((data) {
        if (mounted) {
          setState(() {
            _user = data.user;
            _stats = data.stats;
            _socialStats = data.socialStats;
            _suggestions = data.suggestions;
            _isLoading = false;
            _error = null;
          });
          _animationController.forward();
        }
      });
    });

    final myPostsState = ref.watch(myPostsProvider);

    if (_isLoading && _user == null) {
      return AnimatedScreen(child: _buildShimmerLoading());
    }

    if (_error != null) {
      return AnimatedScreen(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/feed');
                }
              },
            ),
            title: const Text('Dashboard'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.gray700,
                  ),
                ),
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

    final completionRate = (_stats['completionRate'] as num?)?.round() ?? 0;
    final recentActivities = _stats['recentActivities'] is List
        ? _stats['recentActivities'] as List
        : <dynamic>[];

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/feed');
              }
            },
          ),
          title: const Text('Dashboard'),
          centerTitle: false,
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: isDark ? Colors.white70 : AppTheme.gray700,
                  onPressed: () {
                    _showNotificationsSheet(context, isDark);
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
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
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.gray900,
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
                            Text(
                              'Recommended For You',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.gray900,
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
                                duration: Duration(
                                  milliseconds: 400 + (index * 100),
                                ),
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
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withOpacity(0.2)
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.userPrimaryBlue
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.work_outline,
                                                color: AppTheme.userPrimaryBlue,
                                                size: 20,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              suggestion['careerPath'] ??
                                                  'Career Path',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppTheme.gray900,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${suggestion['matchScore'] ?? 0}% Match',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.greenAccent
                                                    : Colors.green.shade700,
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

                // 5. User Feed Activity
                _buildAnimatedCard(
                  index: 4,
                  child: _buildUserFeedActivity(isDark, myPostsState),
                ),

                const SizedBox(height: 32),

                // 6. Recent Activity
                _buildAnimatedCard(
                  index: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (recentActivities.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white10 : AppTheme.gray200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No recent activity yet. Start by uploading your resume!',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : AppTheme.gray500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentActivities.take(5).length,
                          separatorBuilder: (context, index) => Divider(
                            color: isDark ? Colors.white10 : AppTheme.gray200,
                          ),
                          itemBuilder: (context, index) {
                            final activity = recentActivities[index];
                            final timestamp = activity['timestamp'];
                            final type = activity['type']
                                ?.toString()
                                .toLowerCase();
                            final status = (activity['status'] ?? 'completed')
                                .toString()
                                .toLowerCase();
                            final message =
                                activity['message'] ??
                                activity['description'] ??
                                'Activity';

                            IconData iconData = Icons.history;
                            Color iconColor = isDark
                                ? Colors.white38
                                : AppTheme.gray600;

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
                              duration: Duration(
                                milliseconds: 300 + (index * 80),
                              ),
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
                                    color: iconColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: iconColor,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        message,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.gray900,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            status.contains('completed') ||
                                                status == 'done'
                                            ? Colors.green.withValues(
                                                alpha: 0.15,
                                              )
                                            : Colors.orange.withValues(
                                                alpha: 0.15,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.contains('completed') ||
                                                status == 'done'
                                            ? 'Completed'
                                            : (status.contains('pending')
                                                  ? 'Pending'
                                                  : status),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              status.contains('completed') ||
                                                  status == 'done'
                                              ? (isDark
                                                    ? Colors.greenAccent
                                                    : Colors.green.shade700)
                                              : (isDark
                                                    ? Colors.orangeAccent
                                                    : Colors.orange.shade700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: timestamp != null
                                    ? Text(
                                        timestamp.toString(),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : AppTheme.gray500,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.gray50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/feed');
            }
          },
        ),
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      body: Shimmer.fromColors(
        baseColor: isDark ? Colors.white12 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(12) : Colors.white,
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
                color: Colors.white.withOpacity(0.05),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildProfileCompletionCard(int completionRate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: completionRate / 100),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.userPrimaryBlue, AppTheme.userPrimaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(76)
                    : AppTheme.userPrimaryBlue.withAlpha(76),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFollowInfo(
                          'Connections',
                          _socialStats['connectionsCount'] ?? 0,
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                        child: GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 2),
                              image:
                                  _user?.profilePictureUrl != null &&
                                      (_user!.profilePictureUrl ?? '')
                                          .isNotEmpty
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        _resolveImageUrl(
                                          _user!.profilePictureUrl!,
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                _user?.profilePictureUrl == null ||
                                    (_user!.profilePictureUrl ?? '').isEmpty
                                ? _buildProfileAvatarFallback()
                                : null,
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
    final baseClean = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return url.startsWith('/') ? '$baseClean$url' : '$baseClean/$url';
  }

  Widget _buildProfileAvatarFallback() {
    return Center(
      child: Text(
        _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.userPrimaryBlue,
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required int index, required Widget child}) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.gray900,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : AppTheme.gray700,
                  ),
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

  Widget _buildUserFeedActivity(
    bool isDark,
    AsyncValue<List<Post>> myPostsState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Feed Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.gray900,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/feed'),
              child: const Text('Go to Feed'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        myPostsState.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppTheme.gray200,
                  ),
                ),
                child: const Center(child: Text('No posts yet.')),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.take(3).length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final post = posts[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppTheme.gray200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              post.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditPostDialog(post, isDark);
                              } else if (value == 'delete') {
                                _confirmDeletePost(post.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.thumb_up_outlined,
                            size: 14,
                            color: AppTheme.gray500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likesCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.gray500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.comment_outlined,
                            size: 14,
                            color: AppTheme.gray500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.gray500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => const Center(child: Text('Failed to load posts')),
        ),
      ],
    );
  }

  void _showEditPostDialog(Post post, bool isDark) {
    final controller = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(socialFeedProvider.notifier)
                    .updatePost(post.id, controller.text.trim());
                ref.invalidate(myPostsProvider);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(socialFeedProvider.notifier).deletePost(postId);
              ref.invalidate(myPostsProvider);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowInfo(String label, int count, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : AppTheme.gray500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.gray900,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
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
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.gray700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.gray900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.forum, color: Colors.white),
                      ),
                      title: Text('New messages available', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      subtitle: const Text('Check your inbox in My Network.'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/chat-list');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.work, color: Colors.white),
                      ),
                      title: Text('Your application was viewed!', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      subtitle: const Text('An admin has opened your career path submission.'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.star, color: Colors.white),
                      ),
                      title: Text('New matching career paths', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      subtitle: const Text('We found 3 new careers matching your skills.'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

