import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_roles.dart';
import '../../services/api_service.dart';
import '../../widgets/animated_screen.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _reports;
  String _selectedPeriod = '30d';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await ref
          .read(apiServiceProvider)
          .fetchAdminReportsOverview(period: _selectedPeriod);
      setState(() {
        _reports = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleExport(String format) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final bytes = await ref
          .read(apiServiceProvider)
          .exportAdminReport(format);

      if (!mounted) return;

      if (bytes.isEmpty) {
        throw Exception('Received empty file from server');
      }

      final fileName =
          'admin-report-${DateTime.now().toIso8601String().split('T')[0]}.$format';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [format],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report saved to $outputFile'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    isDense: true,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                    items: ['7d', '30d', '90d', '1y']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text('Last $e'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedPeriod = v);
                        _loadReports();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.download_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                    tooltip: 'Export Report',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: _handleExport,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Export PDF',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'csv',
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_chart,
                              size: 20,
                              color: Colors.green,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Export CSV',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKeyMetrics(),
                    const SizedBox(height: 24),
                    _buildChartsSection(),
                    const SizedBox(height: 24),
                    _buildDetailedReports(),
                    const SizedBox(height: 24),
                    _buildDataTables(),
                    const SizedBox(height: 24),
                    _buildSystemPerformance(),
                  ],
                ),
              ),
            ),
    ),
    );
  }

  Widget _buildKeyMetrics() {
    if (_reports == null) return const SizedBox();

    // Calculate percentages and safe defaults
    final totalUsers = _reports!['totalUsers'] as int? ?? 0;
    final activeUsers = _reports!['activeUsers'] as int? ?? 0;
    final activePercent = totalUsers > 0
        ? ((activeUsers / totalUsers) * 100).toStringAsFixed(1)
        : '0.0';
    final newUsers = _reports!['newUsersThisMonth'] as int? ?? 0;
    final totalResumes = _reports!['totalResumes'] as int? ?? 0;
    final totalAnalyses = _reports!['totalAnalyses'] as int? ?? 0;
    final avgScore =
        (_reports!['averageResumeScore'] as num?)?.toDouble() ?? 0.0;

    final metrics = [
      _buildMetricCard(
        'Total Users',
        totalUsers.toString(),
        '+$newUsers new this month',
        Icons.people,
        Colors.blue,
      ),
      _buildMetricCard(
        'Active Users',
        activeUsers.toString(),
        '$activePercent% of total',
        Icons.person_pin_circle,
        Colors.green,
      ),
      _buildMetricCard(
        'Resumes Processed',
        totalResumes.toString(),
        '$totalAnalyses analyses completed',
        Icons.description,
        Colors.purple,
      ),
      _buildMetricCard(
        'Avg Resume Score',
        avgScore.toStringAsFixed(1),
        'Out of 100 points',
        Icons.star,
        Colors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: metrics
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: m,
                  ),
                )
                .toList(),
          );
        } else if (constraints.maxWidth < 1200) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: metrics[0]),
                  const SizedBox(width: 16),
                  Expanded(child: metrics[1]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: metrics[2]),
                  const SizedBox(width: 16),
                  Expanded(child: metrics[3]),
                ],
              ),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: metrics[0]),
              const SizedBox(width: 16),
              Expanded(child: metrics[1]),
              const SizedBox(width: 16),
              Expanded(child: metrics[2]),
              const SizedBox(width: 16),
              Expanded(child: metrics[3]),
            ],
          );
        }
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: isWide ? 1 : 0, child: _buildUserGrowthChart()),
            if (isWide)
              const SizedBox(width: 24)
            else
              const SizedBox(height: 24),
            Expanded(
              flex: isWide ? 1 : 0,
              child: _buildRoleDistributionChart(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserGrowthChart() {
    final registrations =
        _reports!['userRegistrationsByMonth'] as Map<String, dynamic>? ?? {};

    // Sort keys to ensure chronological order if possible (assuming YYYY-MM format or similar sortable keys)
    // If keys are Month names, we might need custom logic, but for now let's use keys as is.
    final keys = registrations.keys.toList();
    // Simple logic: if empty, show placeholder
    if (keys.isEmpty) {
      return _buildChartPlaceholder(
        'User Registration Trends',
        'No data available',
      );
    }

    // Convert map to spots
    List<FlSpot> spots = [];
    for (int i = 0; i < keys.length; i++) {
      final val = (registrations[keys[i]] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Registration Trends',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < keys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                keys[value.toInt()].substring(
                                  0,
                                  3,
                                ), // Show first 3 chars
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withValues(alpha: 0.1),
                      ),
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

  Widget _buildRoleDistributionChart() {
    final roles = _reports!['roleDistribution'] as Map<String, dynamic>? ?? {};
    if (roles.isEmpty) {
      return _buildChartPlaceholder(
        'User Role Distribution',
        'No data available',
      );
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
    ];
    int colorIndex = 0;

    final sections = roles.entries.map((e) {
      final val = (e.value as num).toDouble();
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        color: color,
        value: val,
        title: '${val.toInt()}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Role Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 400;
                return Flex(
                  direction: isSmall ? Axis.vertical : Axis.horizontal,
                  children: [
                    SizedBox(
                      height: 250,
                      width: isSmall ? double.infinity : 250,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmall ? 0 : 16, height: isSmall ? 16 : 0),
                    isSmall
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: roles.keys.map((key) {
                              final index = roles.keys.toList().indexOf(key);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: colors[index % colors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        key,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        : Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: roles.keys.map((key) {
                                final index = roles.keys.toList().indexOf(key);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: colors[index % colors.length],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          key,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
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

  Widget _buildChartPlaceholder(String title, String message) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(message, style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReports() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: isWide ? 1 : 0, child: _buildActivityList()),
            if (isWide)
              const SizedBox(width: 24)
            else
              const SizedBox(height: 24),
            Expanded(flex: isWide ? 1 : 0, child: _buildResumeAnalysisList()),
          ],
        );
      },
    );
  }

  Widget _buildActivityList() {
    final activities = _reports!['userActivities'] as List<dynamic>? ?? [];
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent User Activities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (activities.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No recent activities'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.take(5).length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 24, thickness: 0.5),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.red[400],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activity['userName'] ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['activityType'] ?? '',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            activity['timestamp'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeAnalysisList() {
    final analyses = _reports!['resumeAnalyses'] as List<dynamic>? ?? [];
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resume Analysis Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (analyses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No resume analyses yet'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: analyses.take(5).length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 24, thickness: 0.5),
                itemBuilder: (context, index) {
                  final analysis = analyses[index];
                  final score = analysis['overallScore'] as num? ?? 0;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description,
                        color: Colors.purple[400],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      analysis['userName'] ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Score: ${score.toStringAsFixed(1)}/100',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    trailing: Text(
                      analysis['analyzedAt'] != null
                          ? (analysis['analyzedAt'] as String).split('T')[0]
                          : '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTables() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: isWide ? 1 : 0, child: _buildRegistrationTable()),
            if (isWide)
              const SizedBox(width: 24)
            else
              const SizedBox(height: 24),
            Expanded(flex: isWide ? 1 : 0, child: _buildRoleTable()),
          ],
        );
      },
    );
  }

  Widget _buildRegistrationTable() {
    final registrations =
        _reports!['userRegistrationsByMonth'] as Map<String, dynamic>? ?? {};
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Registration by Month',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (registrations.isEmpty)
              const Text('No data available')
            else
              Table(
                border: TableBorder.all(color: Colors.grey[200]!, width: 1),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[50]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Text(
                          'Month',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Text(
                          'New Users',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...registrations.entries.map(
                    (e) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Text(
                            e.key,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Text(
                            e.value.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTable() {
    final roles = _reports!['roleDistribution'] as Map<String, dynamic>? ?? {};
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (roles.isEmpty)
              const Text('No data available')
            else
              Column(
                children: roles.entries.map((e) {
                  final isLast = e.key == roles.keys.last;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(color: Colors.grey[100]!),
                            ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppRoles.isAdmin(e.key) ? Colors.red : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              e.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          e.value.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemPerformance() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Performance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final items = [
                  _buildPerformanceItem(
                    Icons.cloud_done_rounded,
                    Colors.green,
                    '98.5%',
                    'System Uptime',
                  ),
                  _buildPerformanceItem(
                    Icons.speed_rounded,
                    Colors.blue,
                    '120ms',
                    'Avg Latency',
                  ),
                  _buildPerformanceItem(
                    Icons.storage_rounded,
                    Colors.purple,
                    '45%',
                    'Storage Used',
                  ),
                  _buildPerformanceItem(
                    Icons.memory_rounded,
                    Colors.orange,
                    '12%',
                    'CPU Load',
                  ),
                ];

                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [items[0], items[1]],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [items[2], items[3]],
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: items,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
