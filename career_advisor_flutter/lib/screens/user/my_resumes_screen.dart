import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
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

      final resumes = await ref.read(apiServiceProvider).fetchMyResumes();

      if (mounted) {
        setState(() {
          _resumes = resumes;
          _isLoading = false;
        });
      }
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
      _loadResumes(); 
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
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'My Resumes',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.gray900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  children: [
                    if (isDark)
                      Positioned(
                        right: -30,
                        top: -30,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                        ),
                      ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.gray900),
                onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.add, color: isDark ? Colors.white : AppTheme.gray900),
                  onPressed: () => context.push('/analyze'),
                ),
              ],
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadResumes, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else if (_resumes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 24),
                      const Text(
                        'No resumes yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Upload your first resume to get started.'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.push('/analyze'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Upload Now'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final resume = _resumes[index];
                      return _buildResumeCard(resume, isDark);
                    },
                    childCount: _resumes.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeCard(dynamic resume, bool isDark) {
    final date = resume['uploadedAt'] != null
        ? DateTime.tryParse(resume['uploadedAt'])
        : null;
    final dateStr = date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewResumeDetails(resume),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.article_rounded, color: Color(0xFF6366F1), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resume['fileName'] ?? 'Untitled Resume',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: isDark ? Colors.white38 : AppTheme.gray500),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : AppTheme.gray500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: isDark ? Colors.white38 : AppTheme.gray400),
                    onPressed: () => _showResumeOptions(resume),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResumeOptions(dynamic resume) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.analytics, color: Color(0xFF6366F1)),
              title: const Text('View AI Analysis'),
              onTap: () {
                Navigator.pop(context);
                _viewResumeDetails(resume);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Resume'),
              onTap: () {
                Navigator.pop(context);
                _deleteResume(resume['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewResumeDetails(dynamic resume) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final analysis = await ref.read(apiServiceProvider).getResumeAnalysis(resume['id']);
      if (!mounted) return;
      Navigator.pop(context);
      
      _showAnalysisModal(resume, analysis);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showAnalysisModal(resume, null); // Fallback to basic details
    }
  }

  void _showAnalysisModal(dynamic resume, dynamic analysis) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resume['fileName'] ?? 'Resume Analysis',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    if (analysis != null) ...[
                      _buildScoreSection(analysis['overallScore'] ?? 0),
                      const SizedBox(height: 32),
                      _buildInfoSection('Strengths', analysis['strengths']?.toString() ?? 'Checking...', Colors.green),
                      const SizedBox(height: 20),
                      _buildInfoSection('Pathways', analysis['improvements']?.toString() ?? 'Analyzing...', Colors.orange),
                    ] else ...[
                      const Center(child: Text('No detailed analysis available for this resume.')),
                    ],
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('View Career Paths'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection(int score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  strokeWidth: 6,
                ),
              ),
              Text('$score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Career Readiness', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Based on your current skill set and extraction', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Text(content, style: const TextStyle(color: Colors.grey, height: 1.5)),
      ],
    );
  }
}
