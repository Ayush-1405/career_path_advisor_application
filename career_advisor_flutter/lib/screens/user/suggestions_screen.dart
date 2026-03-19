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
  List<dynamic> _filteredSuggestions = [];
  String _sortBy = 'match';
  String _filterBy = 'all';

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    try {
      final api = ref.read(apiServiceProvider);
      List<dynamic> base = await api.fetchCareerSuggestions();
      if (base.isEmpty) {
        final allPaths = await api.fetchCareerPaths();
        base = allPaths is List ? allPaths : [];
      }
      Set<String> appliedIds = {};
      try {
        final apps = await api.fetchMyApplications();
        for (final a in (apps as List)) {
          final m = a as Map<String, dynamic>;
          final cp = m['careerPath'] as Map<String, dynamic>?;
          final id = cp?['id']?.toString() ?? '';
          if (id.isNotEmpty) appliedIds.add(id);
        }
      } catch (_) {}
      final filtered = base.where((e) {
        final id = (e is Map && e['id'] != null) ? e['id'].toString() : '';
        return id.isEmpty || !appliedIds.contains(id);
      }).toList();

      if (mounted) {
        setState(() {
          _suggestions = filtered;
          _filterAndSortSuggestions();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _filteredSuggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _filterAndSortSuggestions() {
    var result = List<dynamic>.from(_suggestions);

    // Filter
    if (_filterBy != 'all') {
      result = result.where((item) {
        final category = (item['category'] as String?)?.toLowerCase() ?? '';
        return category.contains(_filterBy.toLowerCase());
      }).toList();
    }

    // Sort
    result.sort((a, b) {
      switch (_sortBy) {
        case 'salary':
          final salaryA = _parseSalary((a['averageSalary'] as String?) ?? '');
          final salaryB = _parseSalary((b['averageSalary'] as String?) ?? '');
          return salaryB.compareTo(salaryA);
        case 'role':
          final titleA = (a['title'] as String?) ?? '';
          final titleB = (b['title'] as String?) ?? '';
          return titleA.compareTo(titleB);
        case 'match':
        default:
          final matchA = _computeMatchPercentage(a);
          final matchB = _computeMatchPercentage(b);
          return matchB.compareTo(matchA);
      }
    });

    setState(() {
      _filteredSuggestions = result;
    });
  }

  double _parseSalary(String salary) {
    final regex = RegExp(r'(\d+(?:[,\s]\d{3})*(?:\.\d+)?)');
    final matches = regex
        .allMatches(salary.replaceAll(RegExp(r'[^\d.,\s]'), ''))
        .map((m) => m.group(1))
        .whereType<String>()
        .map((s) => double.tryParse(s.replaceAll(RegExp(r'[,\\s]'), '')))
        .whereType<double>()
        .toList();
    if (matches.isEmpty) return 0;
    if (matches.length == 1) return matches.first;
    return (matches.reduce((a, b) => a + b)) / matches.length;
  }

  double _computeMatchPercentage(Map<String, dynamic> item) {
    final pop = (item['popularity'] as num?)?.toDouble() ?? 0.0;
    final growthStr = (item['growth'] as String?) ?? '0%';
    final growth = double.tryParse(growthStr.replaceAll('%', '')) ?? 0.0;
    final match = (pop + growth) / 2.0;
    if (match < 0) return 0;
    if (match > 100) return 100;
    return match;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Career Suggestions'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.gray900,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore personalized career recommendations based on your skills, experience, and preferences',
                    style: TextStyle(color: AppTheme.gray600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _buildFilters(),
                  const SizedBox(height: 24),
                  if (_filteredSuggestions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No suggestions found matching your criteria',
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredSuggestions.length,
                      itemBuilder: (context, index) {
                        return _buildSuggestionCard(
                          _filteredSuggestions[index],
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 700;
              final sortContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sort by',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'match',
                            child: Text('Match Score'),
                          ),
                          DropdownMenuItem(
                            value: 'salary',
                            child: Text('Salary'),
                          ),
                          DropdownMenuItem(
                            value: 'role',
                            child: Text('Role Name'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                              _filterAndSortSuggestions();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
              final filterContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Industry',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterBy,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Industries'),
                          ),
                          DropdownMenuItem(
                            value: 'technology',
                            child: Text('Technology'),
                          ),
                          DropdownMenuItem(
                            value: 'analytics',
                            child: Text('Analytics'),
                          ),
                          DropdownMenuItem(
                            value: 'design',
                            child: Text('Design'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filterBy = value;
                              _filterAndSortSuggestions();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
              if (narrow) {
                return Column(
                  children: [
                    sortContent,
                    const SizedBox(height: 16),
                    filterContent,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: sortContent),
                  const SizedBox(width: 16),
                  Expanded(child: filterContent),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Remix.information_line,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_filteredSuggestions.length} suggestions found',
                style: const TextStyle(color: AppTheme.gray600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final match = _computeMatchPercentage(suggestion);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 700;
                final left = Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              suggestion['title'] ?? 'Role',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gray900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              suggestion['category'] ?? 'General',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Remix.bar_chart_line,
                            size: 16,
                            color: AppTheme.gray600,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              suggestion['level'] ?? 'Entry Level',
                              style: const TextStyle(color: AppTheme.gray600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(color: AppTheme.gray600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Remix.money_dollar_circle_line,
                            size: 16,
                            color: AppTheme.gray600,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              suggestion['averageSalary'] ?? 'N/A',
                              style: const TextStyle(color: AppTheme.gray600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        suggestion['description'] ?? '',
                        style: const TextStyle(color: AppTheme.gray700),
                      ),
                    ],
                  ),
                );
                final right = Column(
                  children: [
                    Text(
                      '${match.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      'Match',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                    ),
                  ],
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [left]),
                      const SizedBox(height: 12),
                      right,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [left, const SizedBox(width: 16), right],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key Skills',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (suggestion['requiredSkills'] as List? ?? [])
                            .map<Widget>((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  skill.toString(),
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttonNarrow = constraints.maxWidth < 600;

                final matchScoreSection = Row(
                  children: [
                    const Text(
                      'Match Score',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: match / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ],
                );

                final hasRoadmap =
                    (suggestion['careerProgression'] as List?)?.isNotEmpty ??
                    false;
                final suggestionId = suggestion['id']?.toString();

                // Styles
                final outlineStyle = OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: AppTheme.gray900,
                );

                final primaryStyle = ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );

                // Buttons
                final downloadBtn = OutlinedButton.icon(
                  onPressed: () => _downloadReport(suggestion),
                  style: outlineStyle,
                  icon: const Icon(Remix.download_line, size: 18),
                  label: const Text('Download Report'),
                );

                final List<Widget>? roadmapList = hasRoadmap
                    ? [
                        ElevatedButton.icon(
                          onPressed: () => _viewRoadmap(suggestion),
                          style: primaryStyle,
                          icon: const Icon(Remix.road_map_line, size: 18),
                          label: const Text('View Roadmap'),
                        ),
                      ]
                    : null;
                final List<Widget>? roadmapNarrowList = hasRoadmap
                    ? [
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _viewRoadmap(suggestion),
                          style: primaryStyle,
                          icon: const Icon(Remix.road_map_line, size: 18),
                          label: const Text('View Roadmap'),
                        ),
                      ]
                    : null;

                final exploreBtn = OutlinedButton.icon(
                  onPressed: () {
                    if (suggestionId != null && suggestionId.isNotEmpty) {
                      context.push(
                        Uri(
                          path: '/career-paths',
                          queryParameters: {'id': suggestionId},
                        ).toString(),
                      );
                    } else {
                      context.push('/career-paths');
                    }
                  },
                  style: outlineStyle,
                  icon: const Icon(Remix.compass_3_line, size: 18),
                  label: const Text('Explore Path'),
                );

                if (buttonNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      matchScoreSection,
                      const SizedBox(height: 24),
                      downloadBtn,
                      ...?roadmapNarrowList,
                      const SizedBox(height: 12),
                      exploreBtn,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: matchScoreSection),
                    const SizedBox(width: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [downloadBtn, ...?roadmapList, exploreBtn],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReport(Map<String, dynamic> suggestion) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating and downloading report...')),
      );

      final user = await ref.read(tokenServiceProvider.notifier).getUser();
      final name = user?['name'] ?? 'User';

      final result = await ref
          .read(apiServiceProvider)
          .downloadReportPdf(
            suggestion['title'] ?? 'Career Report',
            name: name,
          );

      await Printing.sharePdf(
        bytes: result,
        filename:
            '${suggestion['title']?.replaceAll(' ', '_') ?? 'Career'}_Report.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download report: $e')),
        );
      }
    }
  }

  void _viewRoadmap(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${suggestion['title']} Roadmap'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: (suggestion['careerProgression'] as List? ?? []).length,
            itemBuilder: (context, index) {
              final step = (suggestion['careerProgression'] as List)[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(step['level'] ?? ''),
                subtitle: Text(step['salary'] ?? ''),
              );
            },
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/analyze');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Upload New Resume'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/skills');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Retake Skills Assessment'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/ai-assistant');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Ask AI Assistant'),
          ),
        ),
      ],
    );
  }
}
