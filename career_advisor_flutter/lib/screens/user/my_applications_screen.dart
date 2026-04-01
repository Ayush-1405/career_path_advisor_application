import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_career_path.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import '../../widgets/animated_screen.dart';

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  List<UserCareerPath> _applications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadApplications());
  }

  Future<void> _loadApplications() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await ref
          .read(tokenServiceProvider.notifier)
          .getUserToken();
      if (token == null) {
        setState(() {
          _applications = [];
          _isLoading = false;
          _error = 'Login required';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/login');
        });
        return;
      }
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
      if (userId.isEmpty) {
        setState(() {
          _applications = [];
          _isLoading = false;
          _error = 'Login required';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/login');
        });
        return;
      }
      final cacheKey = 'my_applications_$userId';

      final prefs = await SharedPreferences.getInstance();
      final lastUser = prefs.getString('my_applications_last_user');
      final cached = lastUser == userId ? prefs.getString(cacheKey) : null;
      if (cached != null) {
        final list = (jsonDecode(cached) as List)
            .map((e) => UserCareerPath.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (mounted) {
          setState(() {
            _applications = list;
            _isLoading = false;
          });
        }
      }

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.fetchMyApplications();

      final apps = (response is List ? response : [])
          .map(
            (e) => UserCareerPath.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList()
          .where((a) {
            final uid = a.user?.id.toString() ?? a.userId ?? '';
            return uid == userId;
          })
          .toList();

      if (mounted) {
        setState(() {
          _applications = apps;
          _isLoading = false;
        });
      }

      await prefs.setString(
        cacheKey,
        jsonEncode(
          _applications.map((e) {
            return {
              'id': e.id,
              'user': e.user?.toJson(),
              'careerPath': e.careerPath?.toJson(),
              'status': e.status,
              'appliedAt': e.appliedAt.toIso8601String(),
              'updatedAt': e.updatedAt?.toIso8601String(),
            };
          }).toList(),
        ),
      );
      await prefs.setString('my_applications_last_user', userId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          title: Text(
            'My Applications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text('Error: $_error', style: TextStyle(color: isDark ? Colors.redAccent : Colors.red)))
            : _applications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: isDark ? Colors.white12 : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No applications yet',
                      style: TextStyle(fontSize: 18, color: isDark ? Colors.white70 : Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Apply to career paths to see them here',
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey[500]),
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
                    return _buildApplicationCard(app, isDark);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildApplicationCard(UserCareerPath app, bool isDark) {
    final normalized = app.status.toUpperCase();
    final statusLabel = (() {
      final s = normalized.replaceAll('_', ' ').toLowerCase();
      return s.isEmpty ? 'Applied' : s[0].toUpperCase() + s.substring(1);
    })();
    Color statusColor;
    IconData statusIcon;
    switch (normalized) {
      case 'APPROVED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.send;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.careerPath?.title ?? 'Unknown Path',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.careerPath?.category ?? 'General',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    avatar: Icon(statusIcon, size: 14, color: isDark ? statusColor.withOpacity(0.8) : statusColor),
                    label: Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? statusColor.withOpacity(0.9) : statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (app.status != 'APPLIED')
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      size: 14,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reviewed by Admin',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white10 : null),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Applied: ${DateFormat.yMMMd().format(app.appliedAt)}',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  if (app.updatedAt != null)
                    Text(
                      'Updated: ${DateFormat.yMMMd().format(app.updatedAt!)}',
                      style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400], fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
