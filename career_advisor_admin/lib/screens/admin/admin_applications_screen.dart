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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Career Path Applications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadApplications,
            ),
            IconButton(
              icon: Icon(
                _autoRefresh ? Icons.sync : Icons.sync_disabled,
                color: _autoRefresh ? Colors.blue : Colors.black54,
              ),
              tooltip: _autoRefresh ? 'Auto-refresh: ON' : 'Auto-refresh: OFF',
              onPressed: () {
                setState(() {
                  _autoRefresh = !_autoRefresh;
                });
                _setupAutoRefresh();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text('Error: $_error'))
            : _applications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No applications found'),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final api = ref.read(apiServiceProvider);
                          await api.adminSeedApplications();
                          await _loadApplications();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Seed failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.bolt),
                      label: const Text('Seed Demo Applications'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadApplications,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
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
    switch (app.status) {
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.careerPath?.title ?? 'Unknown Path',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applicant: ${app.user?.name ?? 'Unknown User'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Email: ${app.user?.email ?? 'Unknown Email'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    app.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  shape: StadiumBorder(
                    side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Applied: ${DateFormat.yMMMd().add_jm().format(app.appliedAt)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (app.status != 'APPROVED')
                    TextButton.icon(
                      onPressed: () => _updateStatus(app.id, 'APPROVED'),
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      label: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.green),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (app.status != 'REJECTED')
                    TextButton.icon(
                      onPressed: () => _updateStatus(app.id, 'REJECTED'),
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (app.status != 'IN_PROGRESS')
                    TextButton.icon(
                      onPressed: () => _updateStatus(app.id, 'IN_PROGRESS'),
                      icon: const Icon(
                        Icons.hourglass_empty,
                        color: Colors.orange,
                      ),
                      label: const Text(
                        'In Progress',
                        style: TextStyle(color: Colors.orange),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
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
