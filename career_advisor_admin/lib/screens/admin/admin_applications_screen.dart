import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_career_path.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import '../../widgets/animated_screen.dart';

class AdminApplicationsScreen extends ConsumerStatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  ConsumerState<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState
    extends ConsumerState<AdminApplicationsScreen> {
  List<UserCareerPath> _applications = [];
  bool _isLoading = true;
  String? _error;
  bool _autoRefresh = false;
  final Duration _refreshInterval = const Duration(seconds: 12);
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadApplications());
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    _refreshTimer?.cancel();
    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(_refreshInterval, (_) {
        if (!mounted) return;
        if (_isLoading) return;
        _loadApplications();
      });
    }
  }

  Future<void> _loadApplications() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final adminToken = await ref
          .read(tokenServiceProvider.notifier)
          .getAdminToken();
      if (adminToken == null) {
        if (mounted) {
          setState(() {
            _error = 'Admin session required';
            _isLoading = false;
          });
          // Navigate to admin login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.push('/login');
          });
        }
        return;
      }

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.fetchAllApplications();

      if (mounted) {
        setState(() {
          _applications = (response as List)
              .map((e) => UserCareerPath.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    final idx = _applications.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final previous = _applications[idx];
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _applications[idx] = UserCareerPath(
        id: previous.id,
        user: previous.user,
        careerPath: previous.careerPath,
        status: status,
        appliedAt: previous.appliedAt,
        updatedAt: DateTime.now(),
      );
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.updateApplicationStatus(id, status);
      messenger.showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
    } catch (e) {
      setState(() {
        _applications[idx] = previous;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Slate 50
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Career Path Applications',
            style: TextStyle(
              color: Color(0xFF0F172A), // Slate 900
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF64748B)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE2E8F0), height: 1), 
          ),
          actions: [
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _autoRefresh ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                ),
                color: _autoRefresh ? const Color(0xFFEFF6FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  _autoRefresh ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                  color: _autoRefresh ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                  size: 20,
                ),
                tooltip: _autoRefresh ? 'Auto-refresh: ON' : 'Auto-refresh: OFF',
                onPressed: () {
                  setState(() {
                    _autoRefresh = !_autoRefresh;
                  });
                  _setupAutoRefresh();
                },
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                    const SizedBox(height: 16),
                    Text('Error: $_error', style: const TextStyle(color: Color(0xFFEF4444))),
                  ],
                ),
              )
            : _applications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description_outlined, size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 16),
                    const Text('No applications found', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final api = ref.read(apiServiceProvider);
                          await api.adminSeedApplications();
                          await _loadApplications();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Seed failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      icon: const Icon(Icons.bolt_rounded, color: Color(0xFF2563EB)),
                      label: const Text('Seed Demo Applications', style: TextStyle(color: Color(0xFF2563EB))),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadApplications,
                color: const Color(0xFFEF4444), // Admin Primary Red
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final app = _applications[index];
                    return _buildApplicationCard(app);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildApplicationCard(UserCareerPath app) {
    Color statusColor;
    Color statusBgColor;
    switch (app.status) {
      case 'APPROVED':
        statusColor = const Color(0xFF059669); // Emerald 600
        statusBgColor = const Color(0xFFD1FAE5); // Emerald 100
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFDC2626); // Red 600
        statusBgColor = const Color(0xFFFEE2E2); // Red 100
        break;
      case 'IN_PROGRESS':
        statusColor = const Color(0xFFD97706); // Amber 600
        statusBgColor = const Color(0xFFFEF3C7); // Amber 100
        break;
      default:
        statusColor = const Color(0xFF2563EB); // Blue 600
        statusBgColor = const Color(0xFFDBEAFE); // Blue 100
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.careerPath?.title ?? 'Unknown Path',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A), // Slate 900
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              app.user?.name ?? 'Unknown User',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              app.user?.email ?? 'Unknown Email',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    app.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                  'Applied on ${DateFormat.yMMMd().add_jm().format(app.appliedAt)}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.end,
                children: [
                  if (app.status != 'REJECTED')
                    TextButton.icon(
                      onPressed: () => _updateStatus(app.id, 'REJECTED'),
                      icon: const Icon(Icons.cancel_rounded, size: 18),
                      label: const Text('Reject'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626), // Red 600
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: const Color(0xFFFEF2F2),
                      ),
                    ),
                  if (app.status != 'IN_PROGRESS')
                    TextButton.icon(
                      onPressed: () => _updateStatus(app.id, 'IN_PROGRESS'),
                      icon: const Icon(Icons.hourglass_empty_rounded, size: 18),
                      label: const Text('In Progress'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706), // Amber 600
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: const Color(0xFFFFFBEB),
                      ),
                    ),
                  if (app.status != 'APPROVED')
                    TextButton.icon(
                      onPressed: () => _updateStatus(app.id, 'APPROVED'),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Approve'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF059669), // Emerald 600
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: const Color(0xFFECFDF5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
