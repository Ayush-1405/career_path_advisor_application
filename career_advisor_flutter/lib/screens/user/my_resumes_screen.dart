import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/animated_screen.dart';

class MyResumesScreen extends ConsumerStatefulWidget {
  const MyResumesScreen({super.key});

  @override
  ConsumerState<MyResumesScreen> createState() => _MyResumesScreenState();
}

class _MyResumesScreenState extends ConsumerState<MyResumesScreen> {
  bool _isLoading = true;
  List<dynamic> _resumes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadResumes);
  }

  Future<void> _loadResumes() async {
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
          _resumes = [];
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
          _resumes = [];
          _isLoading = false;
          _error = 'Login required';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/login');
        });
        return;
      }

      final cacheKey = 'my_resumes_$userId';
      final prefs = await SharedPreferences.getInstance();
      final lastUser = prefs.getString('my_resumes_last_user');
      final cached = lastUser == userId ? prefs.getString(cacheKey) : null;
      if (cached != null) {
        final list = (jsonDecode(cached) as List);
        if (mounted) {
          setState(() {
            _resumes = list;
            _isLoading = false;
          });
        }
      }

      final resumes = await ref.read(apiServiceProvider).fetchMyResumes();

      if (mounted) {
        setState(() {
          _resumes = resumes;
          _isLoading = false;
        });
      }

      await prefs.setString(cacheKey, jsonEncode(_resumes));
      await prefs.setString('my_resumes_last_user', userId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load resumes';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteResume(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resume'),
        content: const Text(
          'Are you sure you want to delete this resume? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(apiServiceProvider).deleteResume(id);
      _loadResumes(); // Reload list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete resume: $e')));
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
          title: const Text('My Resumes'),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: TextStyle(color: isDark ? Colors.redAccent : Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadResumes,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _resumes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: isDark ? Colors.white12 : Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No resumes uploaded yet',
                              style: TextStyle(fontSize: 18, color: isDark ? Colors.white70 : Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => context.push('/analyze'),
                              child: const Text('Upload Resume'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadResumes,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _resumes.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final resume = _resumes[index];
                            final date = resume['uploadedAt'] != null
                                ? DateTime.tryParse(resume['uploadedAt'])
                                : null;
                            final dateStr = date != null
                                ? DateFormat.yMMMd().add_jm().format(date)
                                : 'Unknown date';

                            return Card(
                              elevation: 0,
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                title: Text(
                                  resume['fileName'] ?? 'Untitled Resume',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Uploaded: $dateStr',
                                      style: TextStyle(
                                        color: isDark ? Colors.white38 : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (resume['skills'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Skills: ${resume['skills']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: isDark ? Colors.white60 : Colors.grey[800]),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteResume(resume['id']),
                                ),
                                onTap: () => _showAnalysis(resume),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  Future<void> _showAnalysis(dynamic resume) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final analysis = await ref
          .read(apiServiceProvider)
          .getResumeAnalysis(resume['id']);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        _showAnalysisDetails(resume, analysis);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load analysis: $e')));
        // Fallback to showing basic resume info
        _showBasicDetails(resume);
      }
    }
  }

  void _showBasicDetails(dynamic resume) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          resume['fileName'] ?? 'Resume Details',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Education', resume['education'], isDark),
              const SizedBox(height: 12),
              _detailRow('Experience', resume['experience'], isDark),
              const SizedBox(height: 12),
              _detailRow('Skills', resume['skills'], isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnalysisDetails(dynamic resume, dynamic analysis) {
    if (analysis == null) {
      _showBasicDetails(resume);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Safely extract score
    final int score = (analysis['overallScore'] is num)
        ? (analysis['overallScore'] as num).toInt()
        : int.tryParse(analysis['overallScore']?.toString() ?? '0') ?? 0;

    final bool isGoodScore = score >= 70;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      resume['fileName'] ?? 'Analysis Result',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isGoodScore
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Score: $score/100',
                      style: TextStyle(
                        color: isGoodScore ? (isDark ? Colors.green.shade400 : Colors.green) : (isDark ? Colors.orange.shade400 : Colors.orange),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow('Overall Feedback', analysis['feedback']?.toString(), isDark),
              const SizedBox(height: 16),
              if (analysis['strengths'] != null) ...[
                Text(
                  'Strengths',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.green.shade400 : Colors.green,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  analysis['strengths'].toString(),
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
              ],
              if (analysis['improvements'] != null) ...[
                Text(
                  'Areas for Improvement',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.orange.shade400 : Colors.orange,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  analysis['improvements'].toString(),
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
              ],
              Divider(color: isDark ? Colors.white10 : null),
              const SizedBox(height: 16),
              Text(
                'Extracted Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Education', resume['education'], isDark),
              const SizedBox(height: 12),
              _detailRow('Experience', resume['experience'], isDark),
              const SizedBox(height: 12),
              _detailRow('Skills', resume['skills'], isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.userPrimaryBlue.withOpacity(0.8) : AppTheme.primaryColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? 'N/A',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
      ],
    );
  }
}
