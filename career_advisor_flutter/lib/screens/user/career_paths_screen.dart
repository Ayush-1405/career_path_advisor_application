import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import 'suggestions_screen.dart'; // Import for fallback or shared widgets if needed

class CareerPathsScreen extends ConsumerStatefulWidget {
  final String? initialId;

  const CareerPathsScreen({super.key, this.initialId});

  @override
  ConsumerState<CareerPathsScreen> createState() => _CareerPathsScreenState();
}

class _CareerPathsScreenState extends ConsumerState<CareerPathsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _pathDetails;
  String? _errorMessage;
  bool _isBookmarked = false;
  static const String _bookmarksKey = 'bookmarked_career_paths';

  @override
  void initState() {
    super.initState();
    _loadPathDetails();
  }

  Future<void> _loadPathDetails() async {
    if (widget.initialId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final details = await ref
          .read(apiServiceProvider)
          .fetchCareerPathById(widget.initialId!);

      await _checkBookmarkStatus();

      if (mounted) {
        setState(() {
          _pathDetails = details is Map<String, dynamic> ? details : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching career path details: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load career path details';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkBookmarkStatus() async {
    if (widget.initialId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];
      setState(() {
        _isBookmarked = bookmarks.contains(widget.initialId);
      });
    } catch (e) {
      debugPrint('Error checking bookmark status: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    if (widget.initialId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

      if (_isBookmarked) {
        bookmarks.remove(widget.initialId);
      } else {
        bookmarks.add(widget.initialId!);
      }

      await prefs.setStringList(_bookmarksKey, bookmarks);

      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update bookmark')),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    if (_pathDetails == null) return;

    final title = _pathDetails!['title'] ?? 'Career Path';
    final description = _pathDetails!['description'] ?? '';

    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        'Check out this career path: $title\n\n$description',
        subject: 'Career Path: $title',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  Future<void> _handleApply() async {
    // Check if user has resumes
    setState(() => _isLoading = true);
    try {
      final resumes = await ref.read(apiServiceProvider).fetchMyResumes();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (resumes.isEmpty) {
        _showNoResumesDialog();
      } else {
        _showResumeSelectionDialog(resumes);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error checking resumes: $e')));
      }
    }
  }

  void _showNoResumesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Resume Found'),
        content: const Text(
          'You need to upload a resume before applying. Would you like to upload one now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/my-resumes');
            },
            child: const Text('Go to My Resumes'),
          ),
        ],
      ),
    );
  }

  void _showResumeSelectionDialog(List<dynamic> resumes) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Resume to Apply'),
        children: resumes.map((resume) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _submitApplication(resume);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.description, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      resume['fileName'] ?? 'Untitled Resume',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _submitApplication(dynamic resume) async {
    if (widget.initialId != null) {
      try {
        // Call backend API to apply
        await ref
            .read(apiServiceProvider)
            .applyForCareerPath(widget.initialId!);

        // Also save to local prefs for offline/quick access if needed, but rely on API
        final prefs = await SharedPreferences.getInstance();
        final applied = prefs.getStringList('applied_career_paths') ?? [];
        if (!applied.contains(widget.initialId)) {
          applied.add(widget.initialId!);
          await prefs.setStringList('applied_career_paths', applied);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Application submitted successfully for ${resume['fileName']}!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error submitting application: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit application: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialId == null) {
      return const SuggestionsScreen();
    }

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
                context.go('/feed');
              }
            },
          ),
          title: const Text('Career Path Details'),
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          actions: [
            IconButton(
              icon: Icon(
                Remix.share_line,
                color: isDark ? Colors.white70 : AppTheme.gray900,
              ),
              onPressed: _handleShare,
            ),
            IconButton(
              icon: Icon(
                _isBookmarked ? Remix.bookmark_fill : Remix.bookmark_line,
                color: _isBookmarked ? AppTheme.primaryColor : (isDark ? Colors.white70 : AppTheme.gray900),
              ),
              onPressed: _toggleBookmark,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: isDark ? Colors.white70 : AppTheme.gray600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _loadPathDetails();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _pathDetails == null
            ? const Center(child: Text('Career path not found'))
            : _buildContent(),
        bottomNavigationBar: _pathDetails != null ? _buildBottomBar() : null,
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final details = _pathDetails!;
    final title = details['title'] ?? 'Unknown Role';
    final category = details['category'] ?? 'General';
    final description = details['description'] ?? 'No description available.';
    final salary = details['averageSalary'] ?? 'N/A';
    final level = details['level'] ?? 'Entry Level';
    final growth = details['growth'] ?? 'Stable';
    final skills = details['requiredSkills'] as List? ?? [];
    final roadmap = details['careerProgression'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.blueAccent : AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : AppTheme.gray900,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Key Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                Remix.money_dollar_circle_line,
                'Avg. Salary',
                salary,
                Colors.green,
              ),
              _buildStatCard(
                Remix.bar_chart_line,
                'Level',
                level,
                Colors.blue,
              ),
              _buildStatCard(
                Remix.line_chart_line,
                'Growth',
                growth,
                Colors.orange,
              ),
              _buildStatCard(
                Remix.group_line,
                'Demand',
                'High',
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Required Skills
          Text(
            'Required Skills',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Text(
                  skill.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppTheme.gray700,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Career Roadmap
          Text(
            'Career Roadmap',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 16),
          if (roadmap.isEmpty)
            Text(
              'No roadmap data available.',
              style: TextStyle(color: isDark ? Colors.white38 : AppTheme.gray500),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roadmap.length,
              itemBuilder: (context, index) {
                final step = roadmap[index];
                final isLast = index == roadmap.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppTheme.gray900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Step ${index + 1} in your career progression',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white38 : AppTheme.gray600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, 
                  color: isDark ? Colors.white38 : AppTheme.gray600
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push('/ai-assistant'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ask AI Assistant'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Now'),
            ),
          ),
        ],
      ),
    );
  }
}
