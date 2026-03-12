import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../widgets/animated_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  User? _admin;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'verifiedUsers': 0.0,
    'resumesParsed': 0,
    'activeUsers': 0,
    'newUsersToday': 0,
    'successfulLogins': 0,
    'verificationRate': 0,
    'completionRate': 0,
    'systemUptime': 98.5,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    final authService = ref.read(authServiceProvider);
    final apiService = ref.read(apiServiceProvider);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final admin = await authService.getCurrentAdmin();
      if (admin == null || !admin.isAdmin) {
        if (!mounted) return;
        context.go('/admin/login');
        return;
      }

      setState(() {
        _admin = admin;
      });

      final stats = await apiService.fetchAdminDashboardStats();
      if (mounted) {
        setState(() {
          _stats = {
            'totalUsers': stats['totalUsers'] ?? 0,
            'verifiedUsers': stats['verifiedUsers'] ?? 0,
            'resumesParsed': stats['resumesParsed'] ?? 0,
            'activeUsers': stats['activeUsers'] ?? 0,
            'newUsersToday': stats['newUsersToday'] ?? 0,
            'successfulLogins': stats['successfulLogins'] ?? 0,
            'verificationRate': stats['verificationRate'] ?? 0,
            'completionRate': stats['completionRate'] ?? 0,
            'systemUptime': stats['systemUptime'] ?? 98.5,
          };
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin dashboard stats: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logoutAdmin();
    // Redirect handled by router listener in AppRouter
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AnimatedScreen(
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_error != null) {
      return AnimatedScreen(
        child: Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      ),
      );
    }

    return AnimatedScreen(
      child: Scaffold(
      backgroundColor: AppTheme.gray50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.adminPrimaryRed,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: AppTheme.getAdminGradient(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome, ${_admin?.name ?? 'Admin'}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'CareerPath AI Administration',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _handleLogout,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 2;
                    final itemWidth = (constraints.maxWidth - 16) / 2;
                    final double childAspectRatio = itemWidth / 160;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _AdminStatCard(
                          icon: Icons.people_outline,
                          value: '${_stats['totalUsers']}',
                          label: 'Total Users',
                          color: AppTheme.userPrimaryBlue,
                          subtitle: '+${_stats['newUsersToday']} today',
                        ),
                        _AdminStatCard(
                          icon: Icons.verified_user_outlined,
                          value: '${_stats['verifiedUsers']}',
                          label: 'Verified Users',
                          color: Colors.green,
                          subtitle:
                              '${_stats['verificationRate'].toStringAsFixed(2)}% rate',
                        ),
                        _AdminStatCard(
                          icon: Icons.description_outlined,
                          value: '${_stats['resumesParsed']}',
                          label: 'Resumes Parsed',
                          color: AppTheme.userPrimaryPurple,
                          subtitle: '${_stats['completionRate']}%\n complete',
                        ),
                        _AdminStatCard(
                          icon: Icons.person_outline,
                          value: '${_stats['activeUsers']}',
                          label: 'Active Users',
                          color: Colors.orange,
                          subtitle: 'Last 24 hours',
                        ),
                        _AdminStatCard(
                          icon: Icons.login,
                          value: '${_stats['successfulLogins']}',
                          label: 'Logins',
                          color: Colors.indigo,
                          subtitle: 'This month',
                        ),
                        _AdminStatCard(
                          icon: Icons.trending_up,
                          value: '${_stats['systemUptime']}%',
                          label: 'System Uptime',
                          color: Colors.red,
                          subtitle: 'Last 30 days',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 2;
                    final itemWidth = (constraints.maxWidth - 16) / 2;
                    final double childAspectRatio = itemWidth / 210;

                    return GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _AdminActionCard(
                          icon: Icons.people,
                          title: 'Manage Users',
                          description: 'View and edit user accounts',
                          color: Colors.blue,
                          onTap: () => context.push('/admin/users'),
                        ),
                        _AdminActionCard(
                          icon: Icons.description,
                          title: 'View Resumes',
                          description: 'Analyze uploaded resumes',
                          color: Colors.purple,
                          onTap: () => context.push('/admin/resumes'),
                        ),
                        _AdminActionCard(
                          icon: Icons.analytics,
                          title: 'Analytics',
                          description: 'Detailed system reports',
                          color: Colors.orange,
                          onTap: () => context.push('/admin/analytics'),
                        ),
                        _AdminActionCard(
                          icon: Icons.summarize,
                          title: 'Reports',
                          description: 'Generate PDF reports',
                          color: Colors.green,
                          onTap: () => context.push('/admin/reports'),
                        ),
                        _AdminActionCard(
                          icon: Icons.alt_route,
                          title: 'Career Paths',
                          description: 'Manage recommendations',
                          color: Colors.teal,
                          onTap: () => context.push('/admin/career-paths'),
                        ),
                        _AdminActionCard(
                          icon: Icons.assignment,
                          title: 'Applications',
                          description: 'User applications',
                          color: Colors.deepOrange,
                          onTap: () {
                            debugPrint('Navigating to applications...');
                            context.push('/admin/applications');
                          },
                        ),
                        _AdminActionCard(
                          icon: Icons.settings,
                          title: 'Settings',
                          description: 'System configuration',
                          color: Colors.grey,
                          onTap: () => context.push('/admin/settings'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? subtitle;

  const _AdminStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray600,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.gray200),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
