import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../widgets/animated_screen.dart';

class AdminResumesScreen extends ConsumerStatefulWidget {
  const AdminResumesScreen({super.key});

  @override
  ConsumerState<AdminResumesScreen> createState() => _AdminResumesScreenState();
}

class _AdminResumesScreenState extends ConsumerState<AdminResumesScreen> {
  bool _isLoading = true;
  List<dynamic> _resumes = [];
  List<dynamic> _filteredResumes = [];
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, processed, processing, error
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.fetchAdminResumes();

      // Ensure data is a list
      final List<dynamic> resumes = (data is List) ? data : [];

      setState(() {
        _resumes = resumes;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = _resumes.where((resume) {
      final user = resume['user'] ?? {};
      final userName = (user['name'] ?? '').toString().toLowerCase();
      final userEmail = (user['email'] ?? '').toString().toLowerCase();
      final fileName = (resume['fileName'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          userName.contains(query) ||
          userEmail.contains(query) ||
          fileName.contains(query);

      // Backend might not return status, so we default to 'PROCESSED' for existing records
      // or check if there's an error field if implemented.
      final status = (resume['status'] ?? 'PROCESSED').toString().toLowerCase();
      final matchesStatus = _statusFilter == 'all' || status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    setState(() {
      _filteredResumes = filtered;
      _currentPage = 1; // Reset to first page on filter change
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredResumes.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < _filteredResumes.length)
        ? startIndex + _itemsPerPage
        : _filteredResumes.length;
    final currentResumes = _filteredResumes.sublist(startIndex, endIndex);

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Resume Logs',
            style: TextStyle(
              color: Color(0xFF0F172A), // Slate 900
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF64748B)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE2E8F0), height: 1),
          ),
          actions: const [],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadResumes,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 900;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Stats
                        if (isSmallScreen)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderTitle(),
                              const SizedBox(height: 16),
                              _buildTotalCountCard(),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: _buildHeaderTitle()),
                              const SizedBox(width: 16),
                              _buildTotalCountCard(),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Filters
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSmallScreen
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSearchField(),
                                    const SizedBox(height: 16),
                                    _buildStatusFilter(),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildSearchField(),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildStatusFilter()),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Table
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  horizontalMargin: 24,
                                  columnSpacing: 40,
                                  columns: const [
                                    DataColumn(label: Text('USER')),
                                    DataColumn(label: Text('FILE')),
                                    DataColumn(label: Text('STATUS')),
                                    DataColumn(label: Text('UPLOAD DATE')),
                                    DataColumn(label: Text('ACTIONS')),
                                  ],
                                  rows: currentResumes.map((resume) {
                                    final user = resume['user'] ?? {};
                                    final userName = user['name'] ?? 'Unknown';
                                    final userEmail = user['email'] ?? '';
                                    final fileName =
                                        resume['fileName'] ?? 'Unknown';
                                    final fileSize =
                                        resume['fileSize']?.toString() ?? '';
                                    final uploadDate =
                                        resume['uploadedAt'] != null
                                        ? _formatDateStr(resume['uploadedAt'])
                                        : 'N/A';

                                    final status =
                                        (resume['status'] ?? 'PROCESSED')
                                            .toString();

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor:
                                                    Colors.red[100],
                                                child: Text(
                                                  userName.isNotEmpty
                                                      ? userName[0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    color: Colors.red[800],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    userName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    userEmail,
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                fileName,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                fileSize.isNotEmpty
                                                    ? '$fileSize bytes'
                                                    : '',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.green[800],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.green[800],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(uploadDate)),
                                        DataCell(
                                          TextButton.icon(
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                              size: 18,
                                            ),
                                            label: const Text('View Details'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red[600],
                                            ),
                                            onPressed: () =>
                                                _showResumeDetails(resume),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                              if (totalPages > 1)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: _currentPage > 1
                                            ? () =>
                                                  setState(() => _currentPage--)
                                            : null,
                                        child: const Text('Previous'),
                                      ),
                                      Text('Page $_currentPage of $totalPages'),
                                      TextButton(
                                        onPressed: _currentPage < totalPages
                                            ? () =>
                                                  setState(() => _currentPage++)
                                            : null,
                                        child: const Text('Next'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resume Logs',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'View and manage all resume uploads and processing results',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTotalCountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Resumes: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            '${_filteredResumes.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Resumes',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) {
            _searchQuery = value;
            _applyFilters();
          },
          decoration: InputDecoration(
            hintText: 'Search by user name, email, or filename...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter by Status',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12, // slightly less to fit
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more_rounded,
                color: Color(0xFF64748B),
              ),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'processed', child: Text('Processed')),
                DropdownMenuItem(
                  value: 'processing',
                  child: Text('Processing'),
                ),
                DropdownMenuItem(value: 'error', child: Text('Error')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _statusFilter = value;
                    _applyFilters();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateStr(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final m = months[date.month - 1];
      return '$m ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showResumeDetails(Map<String, dynamic> resume) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _ResumeDetailsDialog(resume: resume),
        ),
      ),
    );
  }
}

class _ResumeDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> resume;

  const _ResumeDetailsDialog({required this.resume});

  @override
  Widget build(BuildContext context) {
    final user = resume['user'] ?? {};
    final userName = user['name'] ?? 'Unknown';
    final userEmail = user['email'] ?? '';
    final fileName = resume['fileName'] ?? 'Unknown';
    final fileSize = resume['fileSize']?.toString() ?? 'Unknown';
    final education = resume['education'] ?? 'No education data';
    final skills = resume['skills'] ?? 'No skills data';
    final experience = resume['experience'] ?? 'No experience data';

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxHeight: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resume Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('User Information', [
                    _buildInfoRow(Icons.person, userName),
                    _buildInfoRow(Icons.email, userEmail),
                    _buildInfoRow(Icons.insert_drive_file, fileName),
                    _buildInfoRow(Icons.data_usage, '$fileSize bytes'),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Parsed Data', []),
                  const SizedBox(height: 16),
                  _buildContentCard('Skills', skills),
                  const SizedBox(height: 16),
                  _buildContentCard('Experience', experience),
                  const SizedBox(height: 16),
                  _buildContentCard('Education', education),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}
