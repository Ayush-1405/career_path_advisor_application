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
            'Manage Users',
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
            child: Container(color: const Color(0xFFE2E8F0), height: 1), // Slate 200 border
          ),
          actions: const [],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0), // Generous padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                  onSubmitted: _onSearchChanged,
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                            const SizedBox(height: 16),
                            Text(
                              'Error: $_error',
                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 16),
                            const Text(
                              'No users found',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: AppTheme.adminPrimaryRed,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics()),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final name = user['name'] ?? 'Unknown';
                            final initial = name.isNotEmpty
                                ? name[0].toString().toUpperCase()
                                : 'U';
                            final isAdmin = AppRoles.isAdmin(user['role']?.toString());
                            final isVerified = user['emailVerified'] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _editUser(user),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: isAdmin
                                                ? const Color(0xFFFEF2F2)
                                                : const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              initial,
                                              style: TextStyle(
                                                color: isAdmin
                                                    ? const Color(0xFFEF4444)
                                                    : const Color(0xFF3B82F6),
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0F172A),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                user['email'] ?? '',
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isAdmin
                                                          ? const Color(0xFFFEF2F2)
                                                          : const Color(0xFFEFF6FF),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      user['role'] ?? AppRoles.user,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isAdmin
                                                            ? const Color(0xFFB91C1C)
                                                            : const Color(0xFF1D4ED8),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isVerified
                                                          ? const Color(0xFFECFDF5)
                                                          : const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          isVerified
                                                            ? Icons.check_circle_rounded
                                                            : Icons.pending_rounded,
                                                          size: 14,
                                                          color: isVerified
                                                            ? const Color(0xFF10B981)
                                                            : const Color(0xFF64748B),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          isVerified ? 'Verified' : 'Unverified',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isVerified
                                                                ? const Color(0xFF047857)
                                                                : const Color(0xFF475569),
                                                            fontWeight: FontWeight.w600,
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
                                        PopupMenuButton(
                                          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_rounded, size: 20, color: Color(0xFF64748B)),
                                                  SizedBox(width: 12),
                                                  Text('Edit User'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_rounded, size: 20, color: Color(0xFFEF4444)),
                                                  SizedBox(width: 12),
                                                  Text('Delete User', style: TextStyle(color: Color(0xFFEF4444))),
                                                ],
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
                                      ],
                                    ),
                                  ),
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
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: const Color(0xFF64748B),
                          onPressed: _currentPage > 0
                              ? () => _onPageChanged(_currentPage - 1)
                              : null,
                        ),
                        Text(
                          'Page ${_currentPage + 1} of $_totalPages',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: const Color(0xFF64748B),
                          onPressed: _currentPage < _totalPages - 1
                              ? () => _onPageChanged(_currentPage + 1)
                              : null,
                        ),
                      ],
                    ),
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
          const SnackBar(content: Text('User updated successfully'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating user: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool multiLine = false, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: multiLine ? 3 : 1,
        style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.adminPrimaryRed, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: required ? (v) => v == null || v.isEmpty ? 'This field is required' : null : null,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), // Slate 100
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF475569)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit User Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Update profile and permissions',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Profile Information'),
                      _buildTextField('Full Name', _nameController, required: true),
                      _buildTextField('Email Address', _emailController, required: true),
                      _buildTextField('Phone Number', _phoneController),
                      _buildTextField('Location', _locationController),
                      _buildTextField('Biography', _bioController, multiLine: true),
                      
                      const SizedBox(height: 16),
                      _buildSectionTitle('Social Links'),
                      _buildTextField('LinkedIn URL', _linkedinController),
                      _buildTextField('GitHub URL', _githubController),
                      _buildTextField('Website URL', _websiteController),
                      
                      const SizedBox(height: 16),
                      _buildSectionTitle('Account Settings'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _role,
                              decoration: InputDecoration(
                                labelText: 'Account Role',
                                labelStyle: const TextStyle(color: Color(0xFF64748B)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              items: [AppRoles.user, AppRoles.admin]
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                  .toList(),
                              onChanged: (v) => setState(() => _role = v!),
                              icon: const Icon(Icons.expand_more_rounded),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile.adaptive(
                              title: const Text('Active Account', style: TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: const Text('Account can log in', style: TextStyle(fontSize: 12)),
                              value: _isActive,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF10B981),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                            SwitchListTile.adaptive(
                              title: const Text('Email Verified', style: TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: const Text('Bypass email verification', style: TextStyle(fontSize: 12)),
                              value: _emailVerified,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF10B981),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _emailVerified = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.adminPrimaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
