import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  bool _isLoading = true;
  List<dynamic> _suggestions = [];
  Map<String, dynamic>? _lastAnalysis;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      
      // 1. Load latest analysis to get user skills for local match visualization
      final resumes = await api.fetchMyResumes();
      if (resumes.isNotEmpty) {
        _lastAnalysis = await api.getResumeAnalysis(resumes.first['id']);
      }

      // 2. Load suggestions from our new refined backend endpoint
      final suggestions = await api.fetchCareerSuggestions();
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  double _calculateRealMatchScore(List<dynamic> requiredSkills) {
    if (_lastAnalysis == null || _lastAnalysis!['strengths'] == null) return 65.0; // Baseline
    
    final strengths = _lastAnalysis!['strengths'].toString().toLowerCase();
    final skills = requiredSkills.map((s) => s.toString().toLowerCase()).toList();
    
    int matches = 0;
    for (final s in skills) {
      if (strengths.contains(s)) matches++;
    }
    
    if (skills.isEmpty) return 70.0;
    double score = (matches / skills.length) * 100;
    return score < 40 ? 40 + (score/2) : score; // Minimum floor for suggested paths
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.gray900),
            onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
          ),
          title: Text(
            'Smart Career Matches',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.gray900,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: isDark ? Colors.white70 : AppTheme.gray600),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading 
          ? _buildLoadingState(isDark)
          : _suggestions.isEmpty ? _buildEmptyState(isDark) : _buildSuggestionsList(isDark),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Analyzing your profile match...',
            style: TextStyle(color: isDark ? Colors.white38 : AppTheme.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 24),
          const Text('No matches found for your current resume.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Try uploading a more detailed resume first.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/analyze'),
            child: const Text('Analyze Resume'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: _suggestions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildInfoBanner(isDark);
        }
        final suggestion = _suggestions[index - 1];
        return _buildCareerCard(suggestion, isDark);
      },
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personalized for you',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                ),
                Text(
                  'These paths are ranked based on the skills extracted from your resume: ${_lastAnalysis?['strengths']?.toString().split(',').take(3).join(', ') ?? 'Analyzing profile...'}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppTheme.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerCard(dynamic career, bool isDark) {
    final matchScore = _calculateRealMatchScore(career['requiredSkills'] ?? []);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${matchScore.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        career['title'] ?? 'Role',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        career['category'] ?? 'General',
                        style: TextStyle(color: isDark ? Colors.white38 : AppTheme.gray500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.bookmark_border, color: isDark ? Colors.white12 : Colors.grey.shade300),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (career['requiredSkills'] as List? ?? []).take(4).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    skill.toString(),
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : AppTheme.gray700),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AVG SALARY', style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : AppTheme.gray400, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(career['averageSalary'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => context.push('/career-paths/${career['id']}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('View Path'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
