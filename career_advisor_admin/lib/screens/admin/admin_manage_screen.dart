import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_roles.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../services/token_service.dart';
import '../../widgets/animated_screen.dart';

class AdminManageScreen extends ConsumerStatefulWidget {
  const AdminManageScreen({super.key});

  @override
  ConsumerState<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends ConsumerState<AdminManageScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 10;
  int _totalPages = 0;

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final adminToken = await ref
          .read(tokenServiceProvider.notifier)
          .getAdminToken();
      if (adminToken == null) {
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

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.fetchAdminUsers(
        page: _currentPage,
        size: _pageSize,
        query: _searchQuery,
      );

      // Response is likely a Page<UserProfileDto> JSON
      // { "content": [...], "totalPages": X, "totalElements": Y, "number": Z, ... }

      if (mounted) {
        if (response is Map<String, dynamic> &&
            response.containsKey('content')) {
          setState(() {
            _users = response['content'] ?? [];
            _totalPages = response['totalPages'] ?? 0;
            _isLoading = false;
          });
        } else if (response is List) {
          // Fallback if backend returns list directly (not paginated)
          setState(() {
            _users = response;
            _totalPages = 1;
            _isLoading = false;
          });
        } else {
          // It might be empty or error
          setState(() {
            _users = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 0; // Reset to first page
    });
    _loadUsers();
  }

  void _onPageChanged(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
      _loadUsers();
    }
  }

  Future<void> _deleteUser(String userId) async {
    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid user. Cannot delete'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
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
      final previous = List<dynamic>.from(_users);
      final idx = _users.indexWhere(
        (u) => (u['id']?.toString() ?? '') == userId,
      );
      if (idx != -1) {
        setState(() {
          _users.removeAt(idx);
        });
      }
      try {
        await ref.read(apiServiceProvider).deleteUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        final is404 = e is DioException && e.response?.statusCode == 404;
        if (is404) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Already deleted'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        if (mounted) {
          setState(() {
            _users = previous;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AdminEditUserDialog(user: user, onSave: _loadUsers),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: AppTheme.gray50,
        appBar: AppBar(
          title: const Text('Manage Users'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
                onSubmitted: _onSearchChanged,
              ),
              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _users.isEmpty
                    ? const Center(child: Text('No users found'))
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final name = user['name'] ?? 'Unknown';
                            final initial = name.isNotEmpty
                                ? name[0].toString().toUpperCase()
                                : 'U';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                title: Text(name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['email'] ?? ''),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (AppRoles.isAdmin(
                                                      user['role']?.toString(),
                                                    )
                                                    ? Colors.red
                                                    : Colors.blue)
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user['role'] ?? AppRoles.user,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              AppRoles.isAdmin(
                                                user['role']?.toString(),
                                              )
                                              ? Colors.red
                                              : Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (user['emailVerified'] == true
                                                    ? Colors.green
                                                    : Colors.grey)
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user['emailVerified'] == true
                                            ? 'Verified'
                                            : 'Unverified',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: user['emailVerified'] == true
                                              ? Colors.green
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editUser(user);
                                    } else if (value == 'delete') {
                                      _deleteUser(user['id']?.toString() ?? '');
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),

              // Pagination Controls
              if (_totalPages > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () => _onPageChanged(_currentPage - 1)
                            : null,
                      ),
                      Text('Page ${_currentPage + 1} of $_totalPages'),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages - 1
                            ? () => _onPageChanged(_currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminEditUserDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSave;

  const AdminEditUserDialog({
    super.key,
    required this.user,
    required this.onSave,
  });

  @override
  ConsumerState<AdminEditUserDialog> createState() =>
      _AdminEditUserDialogState();
}

class _AdminEditUserDialogState extends ConsumerState<AdminEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _websiteController;

  late String _role;
  late bool _isActive;
  late bool _emailVerified;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _phoneController = TextEditingController(
      text: widget.user['phoneNumber'] ?? '',
    );
    _bioController = TextEditingController(text: widget.user['bio'] ?? '');
    _locationController = TextEditingController(
      text: widget.user['location'] ?? '',
    );
    _linkedinController = TextEditingController(
      text: widget.user['linkedinUrl'] ?? '',
    );
    _githubController = TextEditingController(
      text: widget.user['githubUrl'] ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.user['websiteUrl'] ?? '',
    );

    _role = widget.user['role'] ?? AppRoles.user;
    _isActive = widget.user['active'] ?? true;
    _emailVerified = widget.user['emailVerified'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final userId = widget.user['id'].toString();

      // Update Profile
      await apiService.updateUser(userId, {
        'name': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
        'bio': _bioController.text,
        'location': _locationController.text,
        'linkedinUrl': _linkedinController.text,
        'githubUrl': _githubController.text,
        'websiteUrl': _websiteController.text,
      });

      // Update Role & Status
      await apiService.updateUserRoleAndStatus(userId, {
        'role': _role,
        'isActive': _isActive,
        'emailVerified': _emailVerified,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Social Links',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _linkedinController,
                  decoration: const InputDecoration(
                    labelText: 'LinkedIn URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _githubController,
                  decoration: const InputDecoration(
                    labelText: 'GitHub URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: [AppRoles.user, AppRoles.admin]
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Active Account'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                SwitchListTile(
                  title: const Text('Email Verified'),
                  value: _emailVerified,
                  onChanged: (v) => setState(() => _emailVerified = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
