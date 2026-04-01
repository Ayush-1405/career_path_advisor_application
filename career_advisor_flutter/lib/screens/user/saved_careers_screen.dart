import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remixicon/remixicon.dart';
import 'dart:convert';
import '../../services/token_service.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class SavedCareersScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const SavedCareersScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<SavedCareersScreen> createState() => _SavedCareersScreenState();
}

class _SavedCareersScreenState extends ConsumerState<SavedCareersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedCareers = [];
  List<Map<String, dynamic>> _appliedCareers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await ref
          .read(tokenServiceProvider.notifier)
          .getUserToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _savedCareers = [];
            _appliedCareers = [];
            _isLoading = false;
            _error = 'Login required';
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/login');
        });
        return;
      }

      // Identify current user for per-user storage scoping
      final userMap = await ref.read(tokenServiceProvider.notifier).getUser();
      String userId =
          userMap?['id']?.toString() ?? userMap?['userId']?.toString() ?? '';
      if (userId.isEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length >= 2) {
            final normalized = base64Url.normalize(parts[1]);
            final payload = jsonDecode(
              utf8.decode(base64Url.decode(normalized)),
            );
            userId =
                payload['userId']?.toString() ??
                payload['id']?.toString() ??
                '';
          }
        } catch (_) {}
      }

      final prefs = await SharedPreferences.getInstance();

      // Use per-user keys; no legacy/global fallback
      final savedKey = 'bookmarked_career_paths_$userId';
      final appliedKey = 'applied_career_paths_$userId';

      // Server truth for saved careers
      final savedItems = await ref
          .read(apiServiceProvider)
          .fetchMySavedCareers();
      final savedCareers = <Map<String, dynamic>>[];
      final savedIds = <String>{};
      for (final item in savedItems) {
        if (item is Map<String, dynamic>) {
          final cp = item['careerPath'] as Map<String, dynamic>?;
          if (cp != null) {
            final id = cp['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              savedIds.add(id);
              savedCareers.add({
                'id': id,
                'title': cp['title'],
                'category': cp['category'],
              });
            }
          }
        }
      }

      // Server truth for applied careers (user-scoped, with admin status)
      final apps = await ref.read(apiServiceProvider).fetchMyApplications();
      final appliedCareers = <Map<String, dynamic>>[];
      final appliedIdSet = <String>{};
      for (final item in apps) {
        if (item is Map<String, dynamic>) {
          final userObj = item['user'] as Map<String, dynamic>?;
          final uid = userObj?['id']?.toString() ?? '';
          if (uid.isNotEmpty && uid != userId) {
            continue;
          }
          final cp = item['careerPath'] as Map<String, dynamic>?;
          if (cp != null) {
            final id = cp['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              appliedIdSet.add(id);
              appliedCareers.add({
                'id': id,
                'title': cp['title'],
                'category': cp['category'],
                'status': item['status']?.toString() ?? 'APPLIED',
                'updatedAt': item['updatedAt']?.toString(),
              });
            }
          }
        }
      }

      final saved = savedCareers;
      final applied = appliedCareers;

      if (mounted) {
        setState(() {
          _savedCareers = saved;
          _appliedCareers = applied;
          _isLoading = false;
        });
      }

      await prefs.setStringList(savedKey, savedIds.toList());
      await prefs.setStringList(appliedKey, appliedIdSet.toList());
    } catch (e) {
      debugPrint('Error loading saved careers: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              context.go('/home');
            }
          },
        ),
        title: const Text('My Career Paths'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.gray900,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.gray600,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Saved'),
            Tab(text: 'Applied'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.gray600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCareerList(_savedCareers, isApplied: false),
                _buildCareerList(_appliedCareers, isApplied: true),
              ],
            ),
    ),
    );
  }

  Widget _buildCareerList(
    List<Map<String, dynamic>> careers, {
    required bool isApplied,
  }) {
    if (careers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApplied ? Remix.send_plane_2_line : Remix.bookmark_3_line,
              size: 64,
              color: AppTheme.gray300,
            ),
            const SizedBox(height: 16),
            Text(
              isApplied
                  ? 'You haven\'t applied to any careers yet.'
                  : 'No saved career paths.',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Explore Careers'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: careers.length,
      itemBuilder: (context, index) {
        final career = careers[index];
        return _buildCareerCard(career, isApplied);
      },
    );
  }

  Widget _buildCareerCard(Map<String, dynamic> career, bool isApplied) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            Uri(
              path: '/career-paths',
              queryParameters: {'id': career['id'].toString()},
            ).toString(),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Remix.briefcase_line,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        career['title'] ?? 'Unknown Role',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        career['category'] ?? 'General',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isApplied)
                  _buildStatusChip(career['status']?.toString() ?? 'APPLIED')
                else
                  const Icon(Remix.arrow_right_s_line, color: AppTheme.gray400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'REJECTED':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'IN_PROGRESS':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      default:
        color = AppTheme.primaryColor;
        icon = Icons.send;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
