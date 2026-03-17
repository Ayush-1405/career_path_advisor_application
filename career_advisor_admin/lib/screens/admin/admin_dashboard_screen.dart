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
        context.go('/login');
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

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.adminPrimaryRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'System Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio:
                      1.25, // Increased from 1.1 to prevent overflow
                ),
                delegate: SliverChildListDelegate([
                  _AdminStatCard(
                    icon: Icons.group_add_rounded,
                    value: '${_stats['totalUsers']}',
                    label: 'Total Users',
                    color: const Color(0xFF3B82F6),
                    subtitle: '+${_stats['newUsersToday']} new today',
                    trend: 12.5,
                  ),
                  _AdminStatCard(
                    icon: Icons.verified_rounded,
                    value: '${_stats['verifiedUsers']}',
                    label: 'Verified',
                    color: const Color(0xFF10B981),
                    subtitle:
                        '${_stats['verificationRate'].toStringAsFixed(1)}% verification',
                    trend: 5.2,
                  ),
                  _AdminStatCard(
                    icon: Icons.document_scanner_rounded,
                    value: '${_stats['resumesParsed']}',
                    label: 'Resumes',
                    color: const Color(0xFF8B5CF6),
                    subtitle: '${_stats['completionRate']}% parse rate',
                    trend: -2.1,
                  ),
                  _AdminStatCard(
                    icon: Icons.bolt_rounded,
                    value: '${_stats['activeUsers']}',
                    label: 'Active Now',
                    color: const Color(0xFFF59E0B),
                    subtitle: 'In last 24 hours',
                    trend: 8.4,
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.adminPrimaryRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Management Hub',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio:
                      1.15, // Increased from 1.0 to prevent overflow
                ),
                delegate: SliverChildListDelegate([
                  _AdminActionCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Users',
                    description: 'Manage accounts',
                    color: const Color(0xFF3B82F6),
                    onTap: () => context.push('/users'),
                  ),
                  _AdminActionCard(
                    icon: Icons.description_rounded,
                    title: 'Resumes',
                    description: 'Analysis history',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/resumes'),
                  ),
                  _AdminActionCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Analytics',
                    description: 'System health',
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.push('/analytics'),
                  ),
                  _AdminActionCard(
                    icon: Icons.map_rounded,
                    title: 'Paths',
                    description: 'Career roadmaps',
                    color: const Color(0xFF10B981),
                    onTap: () => context.push('/career-paths'),
                  ),
                  _AdminActionCard(
                    icon: Icons.assignment_turned_in_rounded,
                    title: 'Applications',
                    description: 'Review requests',
                    color: const Color(0xFFEF4444),
                    onTap: () => context.push('/applications'),
                  ),
                  _AdminActionCard(
                    icon: Icons.settings_suggest_rounded,
                    title: 'Settings',
                    description: 'Global config',
                    color: const Color(0xFF64748B),
                    onTap: () => context.push('/settings'),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 240.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.adminPrimaryRed,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {}, // TODO: Add drawer
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: _handleLogout,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        expandedTitleScale: 1.2,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi, ${_admin?.name ?? 'Admin'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              'System Administrator',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.adminPrimaryRed,
                    AppTheme.adminPrimaryRed.withBlue(100),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -20,
              child: Icon(
                Icons.admin_panel_settings,
                size: 200,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            Positioned(
              left: 20,
              top: 60,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 32,
                ),
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
  final String subtitle;
  final double trend;

  const _AdminStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.subtitle,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (trend >= 0 ? Colors.green : Colors.red).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      trend >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: trend >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trend.abs()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: trend >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -1,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
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
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
