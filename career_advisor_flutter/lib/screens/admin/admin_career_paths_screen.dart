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

  // Form State
  final _formKey = GlobalKey<FormState>();
  String? _editingId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _salaryController = TextEditingController();
  final _growthController = TextEditingController();
  final _popularityController = TextEditingController();
  final _skillsController = TextEditingController();
  final _levelController = TextEditingController();
  final _imageController = TextEditingController();
  final _progressionController = TextEditingController();
  List<Map<String, String>> _currentProgression = [];
  List<CareerPath> _filteredPaths = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedLevel;
  String _sortKey = 'title';
  bool _sortAsc = true;
  bool _autoRefresh = false;
  final Duration _refreshInterval = Duration(seconds: 12);
  Timer? _refreshTimer;
  bool _hasLoadedOnce = false;
  bool _softLoading = false;

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
          context.push('/admin/login');
        });
        return;
      }
      _loadCareerPaths();
    });
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _salaryController.dispose();
    _growthController.dispose();
    _popularityController.dispose();
    _skillsController.dispose();
    _levelController.dispose();
    _imageController.dispose();
    _progressionController.dispose();
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

  void _resetForm() {
    _editingId = null;
    _currentProgression = [];
    _titleController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _salaryController.clear();
    _growthController.clear();
    _popularityController.clear();
    _skillsController.clear();
    _levelController.clear();
    _imageController.clear();
    _progressionController.clear();
  }

  void _populateForm(CareerPath path) {
    _editingId = path.id;
    _currentProgression = List.from(path.careerProgression);
    _titleController.text = path.title;
    _descriptionController.text = path.description;
    _categoryController.text = path.category;
    _salaryController.text = path.averageSalary;
    _growthController.text = path.growth;
    _popularityController.text = path.popularity.toString();
    _skillsController.text = path.requiredSkills.join(', ');
    _levelController.text = path.level;
    _imageController.text = path.image;
    _progressionController.text = path.careerProgression
        .map((e) => '${e['level'] ?? ''}:${e['salary'] ?? ''}')
        .join('\n');
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    _currentProgression = _progressionController.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) {
          final parts = l.split(':');
          final level = parts.isNotEmpty ? parts[0].trim() : '';
          final salary = parts.length > 1 ? parts[1].trim() : '';
          return {'level': level, 'salary': salary};
        })
        .toList();

    final newPath = CareerPath(
      id: _editingId ?? '',
      title: _titleController.text,
      description: _descriptionController.text,
      level: _levelController.text,
      category: _categoryController.text,
      image: _imageController.text,
      averageSalary: _salaryController.text,
      growth: _growthController.text,
      popularity: int.tryParse(_popularityController.text) ?? 0,
      requiredSkills: _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .toList(),
      careerProgression: _currentProgression,
    );

    try {
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
      final apiService = ref.read(apiServiceProvider);
      if (_editingId != null) {
        final json = newPath.toJson();
        json.remove('id');
        await apiService.updateCareerPath(_editingId!, json);
      } else {
        final json = newPath.toJson();
        json.remove('id');
        await apiService.createCareerPath(json);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingId != null ? 'Career path updated' : 'Career path added',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadCareerPaths();
      }
    } catch (e) {
      String msg = 'Error saving career path: $e';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
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
        }
        if (e.response?.data is Map &&
            (e.response?.data as Map).containsKey('message')) {
          msg = (e.response?.data as Map)['message']?.toString() ?? msg;
        } else if (e.response?.data is String) {
          msg = e.response?.data as String;
        } else if (e.message != null) {
          msg = e.message!;
        }
      }
      debugPrint(msg);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

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

  Future<void> _showEditDialog({CareerPath? path}) async {
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
    if (!mounted) return;
    if (path != null) {
      _populateForm(path);
    } else {
      _resetForm();
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        path != null
                            ? 'Edit Career Path'
                            : 'Add New Career Path',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 600;
                      final titleField = Expanded(
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      );
                      final categoryField = Expanded(
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      );
                      if (narrow) {
                        return Column(
                          children: [
                            titleField,
                            const SizedBox(height: 16),
                            categoryField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          titleField,
                          const SizedBox(width: 16),
                          categoryField,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 600;
                      final salaryField = Expanded(
                        child: TextFormField(
                          controller: _salaryController,
                          decoration: const InputDecoration(
                            labelText: 'Salary Range',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      );
                      final growthField = Expanded(
                        child: TextFormField(
                          controller: _growthController,
                          decoration: const InputDecoration(
                            labelText: 'Growth Rate',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      );
                      if (narrow) {
                        return Column(
                          children: [
                            salaryField,
                            const SizedBox(height: 16),
                            growthField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          salaryField,
                          const SizedBox(width: 16),
                          growthField,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 600;
                      final popularityField = Expanded(
                        child: TextFormField(
                          controller: _popularityController,
                          decoration: const InputDecoration(
                            labelText: 'Popularity Score (1-100)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final n = int.tryParse(v);
                            if (n == null) return 'Invalid number';
                            if (n < 0 || n > 100) return 'Enter 0-100';
                            return null;
                          },
                        ),
                      );
                      final levelField = Expanded(
                        child: TextFormField(
                          controller: _levelController,
                          decoration: const InputDecoration(
                            labelText: 'Level',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      );
                      if (narrow) {
                        return Column(
                          children: [
                            popularityField,
                            const SizedBox(height: 16),
                            levelField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          popularityField,
                          const SizedBox(width: 16),
                          levelField,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                      labelText: 'Required Skills (comma separated)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _progressionController,
                    decoration: const InputDecoration(
                      labelText: 'Career Progression (level:salary per line)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _handleSave,
                        child: Text(path != null ? 'Update' : 'Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: Colors.grey[50], // AppTheme.gray50
        appBar: AppBar(
          title: const Text(
            'Career Paths',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            if (_softLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              icon: Icon(
                _autoRefresh ? Icons.sync : Icons.sync_disabled,
                color: _autoRefresh ? Colors.blue : Colors.black87,
              ),
              tooltip: _autoRefresh ? 'Auto-refresh: ON' : 'Auto-refresh: OFF',
              onPressed: () {
                setState(() {
                  _autoRefresh = !_autoRefresh;
                });
                _setupAutoRefresh();
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              tooltip: 'Refresh',
              onPressed: _loadCareerPaths,
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () => _showEditDialog(),
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
                    TextButton.icon(
                      onPressed: _loadCareerPaths,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
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
                          onPressed: () => _showEditDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create New'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _loadCareerPaths,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
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
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search title or description',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    isExpanded: true,
                                    initialValue: _selectedCategory,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                      border: OutlineInputBorder(),
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    isExpanded: true,
                                    initialValue: _selectedLevel,
                                    decoration: const InputDecoration(
                                      labelText: 'Level',
                                      border: OutlineInputBorder(),
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
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _onSortChanged('title'),
                                  icon: Icon(
                                    _sortKey == 'title'
                                        ? (_sortAsc
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward)
                                        : Icons.sort_by_alpha,
                                  ),
                                  label: const Text('Sort by Title'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _onSortChanged('popularity'),
                                  icon: Icon(
                                    _sortKey == 'popularity'
                                        ? (_sortAsc
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward)
                                        : Icons.star_border,
                                  ),
                                  label: const Text('Sort by Popularity'),
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
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
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
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
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
                                              color: Colors.grey,
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
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                path.category,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                path.level,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.purple,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            _showEditDialog(path: path),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _handleDelete(path.id),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                _buildInfoItem(
                                  Icons.attach_money,
                                  path.averageSalary,
                                  'Salary',
                                ),
                                _buildInfoItem(
                                  Icons.trending_up,
                                  path.growth,
                                  'Growth',
                                ),
                                _buildInfoItem(
                                  Icons.star_outline,
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
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
