import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_roles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  Map<String, dynamic>? _profile;
  String? _error;
  String? _success;

  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _linkedinController = TextEditingController();
    _githubController = TextEditingController();
    _websiteController = TextEditingController();
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

  void _updateControllers(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phoneNumber'] ?? '';
    _bioController.text = data['bio'] ?? '';
    _locationController.text = data['location'] ?? '';
    _linkedinController.text = data['linkedinUrl'] ?? '';
    _githubController.text = data['githubUrl'] ?? '';
    _websiteController.text = data['websiteUrl'] ?? '';
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ref.read(apiServiceProvider).getUserProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _updateControllers(profile);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
      _success = null;
    });

    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneController.text,
      'bio': _bioController.text,
      'location': _locationController.text,
      'linkedinUrl': _linkedinController.text,
      'githubUrl': _githubController.text,
      'websiteUrl': _websiteController.text,
    };

    try {
      final updatedProfile = await ref
          .read(apiServiceProvider)
          .updateUserProfile(data);
      // Track profile update so dashboard activity and analytics stay in sync
      try {
        await ref.read(apiServiceProvider).trackUserActivity('profile_update');
      } catch (_) {}
      if (mounted) {
        setState(() {
          _profile = updatedProfile;
          _isEditing = false;
          _success = 'Profile updated successfully!';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to update profile';
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    if (_profile != null) {
      _updateControllers(_profile!);
    }
    setState(() {
      _isEditing = false;
      _error = null;
      _success = null;
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // withData: true so we get bytes (required on web where path is null)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final ext = (file.extension ?? '').toLowerCase();
      const allowed = ['png', 'jpg', 'jpeg', 'webp'];

      // Validate type
      if (!allowed.contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a PNG, JPG, JPEG, or WEBP image'),
            ),
          );
        }
        return;
      }

      // Validate size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image must be less than 5MB')),
          );
        }
        return;
      }

      // Need either path (mobile/desktop) or bytes (web)
      final hasPath = file.path != null && file.path!.isNotEmpty;
      final hasBytes = file.bytes != null && file.bytes!.isNotEmpty;
      if (!hasPath && !hasBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read file. Please try again.'),
            ),
          );
        }
        return;
      }

      setState(() => _isLoading = true);

      final fileName = file.name.isNotEmpty
          ? file.name
          : 'image.${ext.isEmpty ? "jpg" : ext}';

      if (hasPath) {
        await ref
            .read(apiServiceProvider)
            .uploadProfilePhoto(filePath: file.path!, filename: fileName);
      } else {
        await ref
            .read(apiServiceProvider)
            .uploadProfilePhoto(bytes: file.bytes!, filename: fileName);
      }

      // Refresh profile to get new image URL
      await _loadProfile();

      if (mounted) {
        setState(() {
          _success = 'Profile photo updated successfully';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String message =
            'Failed to upload photo. Please ensure the image is PNG/JPG and under 5MB.';
        try {
          if (e is DioException) {
            final data = e.response?.data;
            if (data is Map && data['message'] is String) {
              message = data['message'] as String;
            }
          }
        } catch (_) {}
        setState(() {
          _error = message;
          _isLoading = false;
        });
      }
    }
  }

  double _calculateCompletion() {
    if (_profile == null) return 0.0;

    int total = 0;
    int filled = 0;

    // Define fields to check
    final fields = [
      'name',
      'email',
      'phoneNumber',
      'bio',
      'location',
      'linkedinUrl',
      'githubUrl',
      'websiteUrl',
      'profilePictureUrl',
    ];

    for (var field in fields) {
      total++;
      final value = _profile![field];
      if (value != null && value.toString().isNotEmpty) {
        filled++;
      }
    }

    return filled / total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AnimatedScreen(
        child: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
      );
    }

    if (_profile == null) {
      return AnimatedScreen(
        child: Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Profile not found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedScreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.gray900,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildProfileForm(),
              const SizedBox(height: 24),
              _buildProfileStats(),
              const SizedBox(height: 24),
              _buildDangerZone(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final role = _profile!['role'] ?? AppRoles.user;
    final isActive = _profile!['isActive'] ?? false;
    final profilePic = _profile!['profilePictureUrl'];
    final completion = _calculateCompletion();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Completion Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile Completion',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${(completion * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: completion == 1.0
                          ? Colors.green
                          : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: completion,
                backgroundColor: Colors.grey[200],
                color: completion == 1.0 ? Colors.green : AppTheme.primaryColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              if (completion < 1.0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Complete your profile to get better career suggestions.',
                    style: TextStyle(fontSize: 12, color: AppTheme.gray600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                Color(0xFFEA580C),
                              ],
                            ),
                            shape: BoxShape.circle,
                            image: profilePic != null
                                ? DecorationImage(
                                    image: NetworkImage(profilePic),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profilePic == null
                              ? const Icon(
                                  Remix.user_line,
                                  color: Colors.white,
                                  size: 48,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAndUploadImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Remix.camera_line,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Text(
                          _profile!['name'] ?? 'User',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profile!['email'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.gray600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBadge(
                              role,
                              AppRoles.isAdmin(role)
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              AppRoles.isAdmin(role)
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              isActive ? 'Active' : 'Inactive',
                              isActive
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              isActive
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!_isEditing) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isEditing = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, Color(0xFFEA580C)],
                          ),
                          shape: BoxShape.circle,
                          image: profilePic != null
                              ? DecorationImage(
                                  image: NetworkImage(profilePic),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profilePic == null
                            ? const Icon(
                                Remix.user_line,
                                color: Colors.white,
                                size: 48,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Remix.camera_line,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile!['name'] ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profile!['email'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.gray600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildBadge(
                              role,
                              AppRoles.isAdmin(role)
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              AppRoles.isAdmin(role)
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              isActive ? 'Active' : 'Inactive',
                              isActive
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              isActive
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditing)
                    ElevatedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                ],
              );
            },
          ),
          if (_profile!['bio'] != null &&
              (_profile!['bio'] as String).isNotEmpty) ...[
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _profile!['bio'],
                style: const TextStyle(color: AppTheme.gray700),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (_profile!['linkedinUrl'] != null &&
                  (_profile!['linkedinUrl'] as String).isNotEmpty)
                _buildSocialLink(
                  Remix.linkedin_fill,
                  'LinkedIn',
                  _profile!['linkedinUrl'],
                  Colors.blue,
                ),
              if (_profile!['githubUrl'] != null &&
                  (_profile!['githubUrl'] as String).isNotEmpty)
                _buildSocialLink(
                  Remix.github_fill,
                  'GitHub',
                  _profile!['githubUrl'],
                  AppTheme.gray600,
                ),
              if (_profile!['websiteUrl'] != null &&
                  (_profile!['websiteUrl'] as String).isNotEmpty)
                _buildSocialLink(
                  Remix.global_line,
                  'Website',
                  _profile!['websiteUrl'],
                  AppTheme.primaryColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSocialLink(
    IconData icon,
    String label,
    String url,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          // TODO: Implement URL launching
        },
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Remix.error_warning_line, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Remix.check_line, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _success!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            _buildTextField('Full Name', _nameController, enabled: _isEditing),
            const SizedBox(height: 16),
            _buildTextField(
              'Email',
              _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Phone Number',
              _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Location',
              _locationController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Bio',
              _bioController,
              enabled: _isEditing,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'LinkedIn URL',
              _linkedinController,
              enabled: _isEditing,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'GitHub URL',
              _githubController,
              enabled: _isEditing,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Website URL',
              _websiteController,
              enabled: _isEditing,
              keyboardType: TextInputType.url,
            ),

            if (_isEditing) ...[
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _cancelEdit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.gray700),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.gray700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled ? AppTheme.gray900 : AppTheme.gray500,
          ),
          decoration: InputDecoration(
            filled: !enabled,
            fillColor: enabled ? Colors.white : Colors.grey.shade50,
            hintText: 'Enter your $label',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (enabled) {
              if (label == 'Full Name' &&
                  (value == null || value.trim().isEmpty)) {
                return 'Please enter your name';
              }
              if (label == 'Email') {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                );
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
              }
              if (label == 'Phone Number' &&
                  value != null &&
                  value.isNotEmpty) {
                if (value.length < 10) {
                  return 'Phone number must be at least 10 digits';
                }
              }
              if (label.contains('URL') && value != null && value.isNotEmpty) {
                if (!value.startsWith('http')) {
                  return 'URL must start with http:// or https://';
                }
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _buildStatItem(
                        Remix.calendar_line,
                        'Member Since',
                        _profile!['createdAt'] != null
                            ? _formatDate(_profile!['createdAt'])
                            : 'N/A',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _buildStatItem(
                        Remix.time_line,
                        'Last Login',
                        _profile!['lastLogin'] != null
                            ? _formatDate(_profile!['lastLogin'])
                            : 'Never',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _buildStatItem(
                        Remix.shield_check_line,
                        'Email Status',
                        _profile!['emailVerified'] == true
                            ? 'Verified'
                            : 'Unverified',
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Remix.calendar_line,
                      'Member Since',
                      _profile!['createdAt'] != null
                          ? _formatDate(_profile!['createdAt'])
                          : 'N/A',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      Remix.time_line,
                      'Last Login',
                      _profile!['lastLogin'] != null
                          ? _formatDate(_profile!['lastLogin'])
                          : 'Never',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      Remix.shield_check_line,
                      'Email Status',
                      _profile!['emailVerified'] == true
                          ? 'Verified'
                          : 'Unverified',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'These actions are irreversible. Please be certain before proceeding.',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showDeleteConfirmationDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Delete My Account'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete your account?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProfile();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProfile() async {
    setState(() {
      _isSaving = true;
      _error = null;
      _success = null;
    });

    try {
      await ref.read(apiServiceProvider).deleteUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
        // Log the user out, which will trigger the router to redirect to landing/login
        await ref.read(authServiceProvider).logout();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is DioException) {
            _error =
                'Failed to delete profile: ${e.response?.statusCode} ${e.response?.statusMessage}';
          } else {
            _error = 'Failed to delete profile: $e';
          }
          _isSaving = false;
        });
      }
    }
  }
}
