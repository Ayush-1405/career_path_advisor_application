import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:printing/printing.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class DownloadScreen extends ConsumerStatefulWidget {
  final String? role;

  const DownloadScreen({super.key, this.role});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  Map<String, dynamic>? _reportData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await ref.read(tokenServiceProvider.notifier).getUser();
      if (user == null) {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
        return;
      }

      final role = widget.role ?? 'Career Report';
      final data = await ref
          .read(apiServiceProvider)
          .generateReport(role, name: user['name']);

      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate report. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final user = await ref.read(tokenServiceProvider.notifier).getUser();
      final role = widget.role ?? 'Career Report';

      final bytes = await ref
          .read(apiServiceProvider)
          .downloadReportPdf(role, name: user?['name']);

      if (bytes is List<int>) {
        await Printing.sharePdf(
          bytes: Uint8List.fromList(bytes),
          filename: '${user?['name'] ?? 'User'}_Career_Report.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to download PDF')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AnimatedScreen(
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_error != null) {
      return AnimatedScreen(
        child: Scaffold(
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
            title: const Text('Download Report'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Remix.error_warning_line,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadReport,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userInfo = _reportData?['userInfo'] as Map<String, dynamic>?;
    final summary = _reportData?['summary'] as Map<String, dynamic>?;
    final strengths = (summary?['strengths'] as List?)?.cast<String>() ?? [];
    final improvements =
        (summary?['improvements'] as List?)?.cast<String>() ?? [];

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
          title: const Text('Download Career Report'),
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Generate and download your personalized career development report',
                style: TextStyle(color: isDark ? Colors.white70 : AppTheme.gray600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_reportData != null) ...[
                // Report Preview
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Preview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: isDark ? Colors.white10 : null),
                      const SizedBox(height: 16),

                      // Report Details
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Report Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      'Name',
                                      userInfo?['name'] ?? '',
                                      isDark,
                                    ),
                                    _buildDetailRow(
                                      'Target Role',
                                      userInfo?['role'] ?? '',
                                      isDark,
                                    ),
                                    _buildDetailRow(
                                      'Generated',
                                      userInfo?['date'] ?? '',
                                      isDark,
                                    ),
                                    _buildDetailRow(
                                      'Overall Score',
                                      '${summary?['overallScore'] ?? 0}%',
                                      isDark,
                                      isScore: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Report Contents',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCheckItem('Executive Summary', isDark),
                                    _buildCheckItem('Skills Assessment', isDark),
                                    _buildCheckItem(
                                      'Career Path Recommendations',
                                      isDark,
                                    ),
                                    _buildCheckItem('Learning Roadmap', isDark),
                                    _buildCheckItem('Action Items', isDark),
                                  ],
                                ),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Report Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      'Name',
                                      userInfo?['name'] ?? '',
                                      isDark,
                                    ),
                                    _buildDetailRow(
                                      'Target Role',
                                      userInfo?['role'] ?? '',
                                      isDark,
                                    ),
                                    _buildDetailRow(
                                      'Generated',
                                      userInfo?['date'] ?? '',
                                      isDark,
                                    ),
                                    _buildDetailRow(
                                      'Overall Score',
                                      '${summary?['overallScore'] ?? 0}%',
                                      isDark,
                                      isScore: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Report Contents',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCheckItem('Executive Summary', isDark),
                                    _buildCheckItem('Skills Assessment', isDark),
                                    _buildCheckItem(
                                      'Career Path Recommendations',
                                      isDark,
                                    ),
                                    _buildCheckItem('Learning Roadmap', isDark),
                                    _buildCheckItem('Action Items', isDark),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Key Highlights
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Remix.thumb_up_line,
                                      color: isDark ? Colors.green.shade400 : Colors.green.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Top Strengths',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppTheme.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...strengths
                                    .take(3)
                                    .map(
                                      (s) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Remix.check_line,
                                              color: isDark ? Colors.green.shade400 : Colors.green.shade600,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                s,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white70 : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Remix.arrow_up_line,
                                      color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Development Areas',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppTheme.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...improvements
                                    .take(3)
                                    .map(
                                      (s) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Remix.arrow_right_line,
                                              color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                s,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white70 : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Remix.thumb_up_line,
                                      color: isDark ? Colors.green.shade400 : Colors.green.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Top Strengths',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppTheme.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...strengths
                                    .take(3)
                                    .map(
                                      (s) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Remix.check_line,
                                              color: isDark ? Colors.green.shade400 : Colors.green.shade600,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                s,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white70 : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Remix.arrow_up_line,
                                      color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Development Areas',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppTheme.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...improvements
                                    .take(3)
                                    .map(
                                      (s) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Remix.arrow_right_line,
                                              color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                s,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white70 : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _downloadPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Remix.download_line),
                    label: Text(
                      _isGenerating
                          ? 'Generating PDF...'
                          : 'Download PDF Report',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: isDark ? const BorderSide(color: Colors.white24) : null,
                      foregroundColor: isDark ? Colors.white : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isScore = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: isDark ? Colors.white60 : AppTheme.gray600, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: isScore ? (isDark ? Colors.green.shade400 : Colors.green.shade600) : (isDark ? Colors.white : AppTheme.gray900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Remix.check_line, color: isDark ? Colors.green.shade400 : Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : null))),
        ],
      ),
    );
  }
}
