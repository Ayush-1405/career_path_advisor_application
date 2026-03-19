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

    return AnimatedScreen(
      child: Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Career Path Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.gray900,
        actions: [
          IconButton(
            icon: const Icon(Remix.share_line),
            onPressed: _handleShare,
          ),
          IconButton(
            icon: Icon(
              _isBookmarked ? Remix.bookmark_fill : Remix.bookmark_line,
              color: _isBookmarked ? AppTheme.primaryColor : AppTheme.gray900,
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
                    style: const TextStyle(color: AppTheme.gray600),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInfoChip(Remix.bar_chart_line, level),
                    _buildInfoChip(Remix.money_dollar_circle_line, salary),
                    _buildInfoChip(Remix.line_chart_line, growth),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description
          const Text(
            'About this Role',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppTheme.gray700,
            ),
          ),
          const SizedBox(height: 24),

          // Required Skills
          if (skills.isNotEmpty) ...[
            const Text(
              'Required Skills',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map<Widget>((skill) {
                return Chip(
                  label: Text(skill.toString()),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  labelStyle: const TextStyle(color: AppTheme.gray700),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Career Roadmap
          if (roadmap.isNotEmpty) ...[
            const Text(
              'Career Roadmap',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roadmap.length,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(left: 24),
                height: 24,
                width: 2,
                color: Colors.grey.shade300,
              ),
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? AppTheme.primaryColor
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: index == 0
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: index == 0 ? Colors.white : AppTheme.gray600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          roadmap[index].toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray900,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.gray600),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.gray700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _handleApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Apply Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
