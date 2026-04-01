import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../models/career_path.dart';
import '../../services/token_service.dart';
import '../../widgets/animated_screen.dart';

class AdminCareerPathsScreen extends ConsumerStatefulWidget {
  const AdminCareerPathsScreen({super.key});

  @override
  ConsumerState<AdminCareerPathsScreen> createState() =>
      _AdminCareerPathsScreenState();
}

class _AdminCareerPathsScreenState
    extends ConsumerState<AdminCareerPathsScreen> {
  List<CareerPath> _careerPaths = [];
  bool _isLoading = true;
  String? _error;
  bool _hasLoadedOnce = false;
  bool _softLoading = false;

  // Filtering & Sorting State
  List<CareerPath> _filteredPaths = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedLevel;
  String _sortKey = 'title';
  bool _sortAsc = true;
  bool _autoRefresh = false;
  final Duration _refreshInterval = const Duration(seconds: 12);
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final token = await ref
          .read(tokenServiceProvider.notifier)
          .getAdminToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Admin login required';
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/login');
        });
        return;
      }
      _loadCareerPaths();
    });
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    super.dispose();
    _refreshTimer?.cancel();
  }

  Future<void> _loadCareerPaths() async {
    try {
      if (!_hasLoadedOnce && (_isLoading || _softLoading)) {
        // First load, continue
      } else if (_isLoading || _softLoading) {
        return;
      }
      if (!_hasLoadedOnce) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      } else {
        setState(() {
          _softLoading = true;
          _error = null;
        });
      }
      final adminToken = await ref
          .read(tokenServiceProvider.notifier)
          .getAdminToken();
      if (adminToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _softLoading = false;
            _error = 'Admin session required';
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/admin/login');
        });
        return;
      }
      final data = await ref.read(apiServiceProvider).fetchCareerPathsAdmin();
      final list = data is List ? data : [];
      final List<CareerPath> paths = list
          .map((item) => CareerPath.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final filtered = _filterList(paths);
      setState(() {
        _careerPaths = paths;
        _filteredPaths = filtered;
        _isLoading = false;
        _softLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _softLoading = false;
      });
    }
  }

  void _setupAutoRefresh() {
    _refreshTimer?.cancel();
    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(_refreshInterval, (_) {
        if (!mounted) return;
        if (_isLoading) return;
        _loadCareerPaths();
      });
    }
  }

  List<CareerPath> _filterList(List<CareerPath> input) {
    var list = List<CareerPath>.from(input);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    }
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    if (_selectedLevel != null && _selectedLevel!.isNotEmpty) {
      list = list.where((p) => p.level == _selectedLevel).toList();
    }
    int cmp(CareerPath a, CareerPath b) {
      int r;
      switch (_sortKey) {
        case 'popularity':
          r = a.popularity.compareTo(b.popularity);
          break;
        case 'title':
        default:
          r = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return _sortAsc ? r : -r;
    }

    list.sort(cmp);
    return list;
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    final filtered = _filterList(_careerPaths);
    setState(() {
      _filteredPaths = filtered;
    });
  }

  void _onCategoryChanged(String? value) {
    _selectedCategory = value;
    final filtered = _filterList(_careerPaths);
    setState(() {
      _filteredPaths = filtered;
    });
  }

  void _onLevelChanged(String? value) {
    _selectedLevel = value;
    final filtered = _filterList(_careerPaths);
    setState(() {
      _filteredPaths = filtered;
    });
  }

  void _onSortChanged(String key) {
    if (_sortKey == key) {
      _sortAsc = !_sortAsc;
    } else {
      _sortKey = key;
      _sortAsc = true;
    }
    final filtered = _filterList(_careerPaths);
    setState(() {
      _filteredPaths = filtered;
    });
  }

  // Methods moved to _AdminCareerPathDialog

  Future<void> _handleDelete(String id) async {
    if (id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid item. Cannot delete'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Career Path'),
        content: const Text(
          'Are you sure you want to delete this career path?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final adminToken = await ref
          .read(tokenServiceProvider.notifier)
          .getAdminToken();
      if (adminToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin login required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/admin/login');
        });
        return;
      }

      // Optimistic UI update
      final previous = List<CareerPath>.from(_careerPaths);
      final idx = _careerPaths.indexWhere((p) => p.id == id);
      if (idx != -1) {
        setState(() {
          _careerPaths.removeAt(idx);
        });
      }
      try {
        await ref.read(apiServiceProvider).deleteCareerPath(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Career path deleted'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCareerPaths();
        }
      } catch (e) {
        final isDio = e is DioException;
        final status = isDio ? e.response?.statusCode : null;
        final notFound = status == 404;
        final unauthorized = status == 401;
        final serverError = status == 500;
        if (notFound) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Already deleted'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        } else if (unauthorized) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin session expired. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.push('/admin/login');
          });
          return;
        } else if (serverError) {
          String msg = 'Server error while deleting career path';
          if (isDio) {
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              msg = data['message']?.toString() ?? msg;
            } else if (data is String && data.isNotEmpty) {
              msg = data;
            }
          }
          if (mounted) {
            // revert optimistic update
            setState(() {
              _careerPaths = previous;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          }
          return;
        }
        debugPrint('Error deleting career path: $e');
        if (mounted) {
          // revert optimistic update
          setState(() {
            _careerPaths = previous;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _navigateToAdd() async {
    final result = await context.push<bool>('/career-paths/add');
    if (result == true) {
      _loadCareerPaths();
    }
  }

  Future<void> _navigateToEdit(CareerPath path) async {
    final result = await context.push<bool>('/career-paths/edit', extra: path);
    if (result == true) {
      _loadCareerPaths();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Slate 50
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
            'Career Paths',
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
          actions: [
            if (_softLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _autoRefresh
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFFE2E8F0),
                ),
                color: _autoRefresh
                    ? const Color(0xFFEFF6FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  _autoRefresh
                      ? Icons.sync_rounded
                      : Icons.sync_disabled_rounded,
                  color: _autoRefresh
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
                tooltip: _autoRefresh
                    ? 'Auto-refresh: ON'
                    : 'Auto-refresh: OFF',
                onPressed: () {
                  setState(() {
                    _autoRefresh = !_autoRefresh;
                  });
                  _setupAutoRefresh();
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB), // Blue 600
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _navigateToAdd,
                tooltip: 'Add New Path',
              ),
            ),
          ],
        ),
        body: (_isLoading && !_hasLoadedOnce)
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text('Error: $_error'),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadCareerPaths,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _careerPaths.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_outline, size: 56, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No career paths found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _navigateToAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('Create New'),
                        ),
                        OutlinedButton(
                          onPressed: _loadCareerPaths,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadCareerPaths,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _filteredPaths.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final categories = {
                        for (final p in _careerPaths) p.category,
                      }.toList();
                      final levels = {
                        for (final p in _careerPaths) p.level,
                      }.toList();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Search title or description',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF64748B),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: DropdownButtonFormField<String?>(
                                      isExpanded: true,
                                      initialValue: _selectedCategory,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        labelStyle: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.expand_more_rounded,
                                        color: Color(0xFF64748B),
                                      ),
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text('All'),
                                        ),
                                        ...categories.map(
                                          (c) => DropdownMenuItem<String?>(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        ),
                                      ],
                                      onChanged: _onCategoryChanged,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: DropdownButtonFormField<String?>(
                                      isExpanded: true,
                                      initialValue: _selectedLevel,
                                      decoration: const InputDecoration(
                                        labelText: 'Level',
                                        labelStyle: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.expand_more_rounded,
                                        color: Color(0xFF64748B),
                                      ),
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text('All'),
                                        ),
                                        ...levels.map(
                                          (l) => DropdownMenuItem<String?>(
                                            value: l,
                                            child: Text(l),
                                          ),
                                        ),
                                      ],
                                      onChanged: _onLevelChanged,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _onSortChanged('title'),
                                    icon: Icon(
                                      _sortKey == 'title'
                                          ? (_sortAsc
                                                ? Icons.arrow_upward_rounded
                                                : Icons.arrow_downward_rounded)
                                          : Icons.sort_by_alpha_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Sort by Title'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _sortKey == 'title'
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF64748B),
                                      side: BorderSide(
                                        color: _sortKey == 'title'
                                            ? const Color(0xFF93C5FD)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                      backgroundColor: _sortKey == 'title'
                                          ? const Color(0xFFEFF6FF)
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _onSortChanged('popularity'),
                                    icon: Icon(
                                      _sortKey == 'popularity'
                                          ? (_sortAsc
                                                ? Icons.arrow_upward_rounded
                                                : Icons.arrow_downward_rounded)
                                          : Icons.star_border_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Sort by Popularity'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _sortKey == 'popularity'
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF64748B),
                                      side: BorderSide(
                                        color: _sortKey == 'popularity'
                                            ? const Color(0xFF93C5FD)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                      backgroundColor: _sortKey == 'popularity'
                                          ? const Color(0xFFEFF6FF)
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    final path = _filteredPaths[index - 1];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9), // Slate 100
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    image: path.image.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(path.image),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: path.image.isEmpty
                                      ? Center(
                                          child: Text(
                                            (path.title.isNotEmpty
                                                ? path.title[0]
                                                : '?'),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(
                                                0xFF94A3B8,
                                              ), // Slate 400
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        path.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A), // Slate 900
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFDBEAFE,
                                              ), // Blue 100
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFBFDBFE),
                                              ), // Blue 200
                                            ),
                                            child: Text(
                                              path.category,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(
                                                  0xFF1D4ED8,
                                                ), // Blue 700
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFF3E8FF,
                                              ), // Purple 100
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFE9D5FF),
                                              ), // Purple 200
                                            ),
                                            child: Text(
                                              path.level,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(
                                                  0xFF7E22CE,
                                                ), // Purple 700
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF64748B),
                                      ),
                                      onPressed: () => _navigateToEdit(path),
                                      tooltip: 'Edit',
                                      splashRadius: 24,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFEF4444),
                                      ),
                                      onPressed: () => _handleDelete(path.id),
                                      tooltip: 'Delete',
                                      splashRadius: 24,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                height: 1,
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            Wrap(
                              spacing: 24,
                              runSpacing: 16,
                              children: [
                                _buildInfoItem(
                                  Icons.attach_money_rounded,
                                  path.averageSalary,
                                  'Salary',
                                ),
                                _buildInfoItem(
                                  Icons.trending_up_rounded,
                                  path.growth,
                                  'Growth',
                                ),
                                _buildInfoItem(
                                  Icons.star_outline_rounded,
                                  '${path.popularity}/100',
                                  'Popularity',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
