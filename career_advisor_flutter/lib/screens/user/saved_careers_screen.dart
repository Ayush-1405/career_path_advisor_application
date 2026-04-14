import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/saved_careers_provider.dart';

class SavedCareersScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const SavedCareersScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<SavedCareersScreen> createState() => _SavedCareersScreenState();
}

class _SavedCareersScreenState extends ConsumerState<SavedCareersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(savedCareersTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savedState = ref.watch(savedCareersProvider);
    
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
      body: savedState.when(
        data: (data) => TabBarView(
          controller: _tabController,
          children: [
            _buildCareerList(data.saved, isApplied: false),
            _buildCareerList(data.applied, isApplied: true),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load data. Please try again.',
                style: TextStyle(color: AppTheme.gray600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(savedCareersProvider.notifier).loadData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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
