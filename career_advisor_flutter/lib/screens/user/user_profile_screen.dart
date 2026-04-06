import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import '../../providers/connections_provider.dart';
import '../../providers/social_feed_provider.dart';
import '../../providers/app_auth_provider.dart';
import '../../widgets/linkedin_post_card.dart';
import '../../utils/image_helper.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPrivate = false;
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _socialStats = {
    'connectionsCount': 0,
  };

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
    _fetchData(background: false);
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

  Future<void> _fetchData({bool background = true}) async {
    if (!background) {
      _loadProfile();
    } else {
      // Background refresh
      Future.wait([
        _loadProfile(background: true),
        ref.read(connectionsProvider.notifier).fetchData(background: true),
        ref.read(myPostsProvider.notifier).fetchMyPosts(background: true),
      ]).then((_) async {
        try {
          final stats =
              await ref.read(apiServiceProvider).fetchUserSocialStats();
          if (mounted) {
            setState(() {
            _socialStats = stats as Map<String, dynamic>? ??
                {'connectionsCount': 0};
            });
          }
        } catch (_) {}
      });
    }
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
    _isPrivate = data['isPrivate'] ?? false;
  }

  Future<void> _loadProfile({bool background = false}) async {
    if (!background && _profile == null) {
      setState(() {
        _isLoading = true;
      });
    }

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
          _isLoading = false;
        });
        if (!background) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load profile: $e')));
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
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
      final updatedProfile = await ref.read(apiServiceProvider).updateUserProfile(data);
      try {
        await ref.read(apiServiceProvider).trackUserActivity('profile_update');
      } catch (_) {}
      
      // Also update the app_auth_provider user so changes reflect globally
      ref.invalidate(currentUserProvider);
      
      if (mounted) {
        setState(() {
          _profile = updatedProfile;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.pop(context); // Close the edit sheet
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final ext = (file.extension ?? '').toLowerCase();
      const allowed = ['png', 'jpg', 'jpeg', 'webp'];

      if (!allowed.contains(ext)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PNG, JPG, JPEG, or WEBP image')));
        return;
      }

      if (file.size > 5 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image must be less than 5MB')));
        return;
      }

      final hasPath = file.path != null && file.path!.isNotEmpty;
      final hasBytes = file.bytes != null && file.bytes!.isNotEmpty;
      if (!hasPath && !hasBytes) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read file.')));
        return;
      }

      setState(() => _isLoading = true);

      final fileName = file.name.isNotEmpty ? file.name : 'image.${ext.isEmpty ? "jpg" : ext}';

      if (hasPath) {
        await ref.read(apiServiceProvider).uploadProfilePhoto(filePath: file.path!, filename: fileName);
      } else {
        await ref.read(apiServiceProvider).uploadProfilePhoto(bytes: file.bytes!, filename: fileName);
      }

      await Future.wait([
         _loadProfile(),
         ref.read(myPostsProvider.notifier).fetchMyPosts(),
      ]);
      ref.invalidate(currentUserProvider);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated successfully')));
    } catch (e) {
      if (mounted) {
        String message = 'Failed to upload photo.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['message'] is String) {
            message = data['message'] as String;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditProfileSheet(BuildContext context, bool isDark) {
    if (_profile != null) _updateControllers(_profile!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                          IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField('Full Name', _nameController, Remix.user_line, isDark),
                              const SizedBox(height: 16),
                              _buildTextField('Headline / Bio', _bioController, Remix.information_line, isDark, maxLines: 3),
                              const SizedBox(height: 16),
                              _buildTextField('Location', _locationController, Remix.map_pin_line, isDark),
                              const SizedBox(height: 16),
                              _buildTextField('Email', _emailController, Remix.mail_line, isDark, keyboardType: TextInputType.emailAddress, readOnly: true),
                              const SizedBox(height: 16),
                              _buildTextField('Phone', _phoneController, Remix.phone_line, isDark, keyboardType: TextInputType.phone),
                              const SizedBox(height: 24),
                              Text('Social Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                              const SizedBox(height: 16),
                              _buildTextField('LinkedIn URL', _linkedinController, Remix.linkedin_fill, isDark),
                              const SizedBox(height: 16),
                              _buildTextField('GitHub URL', _githubController, Remix.github_fill, isDark),
                              const SizedBox(height: 16),
                              _buildTextField('Personal Website', _websiteController, Remix.global_line, isDark),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () async {
                            setModalState(() => _isSaving = true);
                            await _saveProfile();
                            // _saveProfile handles Navigator.pop if successful
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.userPrimaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.gray900),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : AppTheme.gray500),
        prefixIcon: Icon(icon, color: isDark ? Colors.white54 : AppTheme.gray500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.white24 : AppTheme.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          if (label == 'Full Name') return 'Please enter your name';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F2EF),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F2EF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load profile.', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final connectionsState = ref.watch(connectionsProvider);
    final connectionCount = connectionsState.valueOrNull?.network.length ?? 0;
    final myPostsState = ref.watch(myPostsProvider);

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F2EF), // LinkedIn typical background
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Remix.settings_3_line),
              onPressed: () => _showSettingsSheet(context, isDark),
              tooltip: 'Settings',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchData,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          color: AppTheme.userPrimaryBlue,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildLinkedInHeader(isDark, connectionCount),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),
              SliverToBoxAdapter(
                child: _buildAboutSection(isDark),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              myPostsState.maybeWhen(
                data: (posts) {
                  if (posts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark ? Colors.white12 : AppTheme.gray200),
                        ),
                        child: Center(
                          child: Text(
                            "You haven't posted anything yet.",
                            style: TextStyle(
                                color: isDark ? Colors.white54 : AppTheme.gray500),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LinkedInPostCard(
                            post: posts[index],
                            isDark: isDark,
                            onFeedRefresh: () {
                              ref.read(myPostsProvider.notifier).fetchMyPosts(background: true);
                            },
                          ),
                        );
                      },
                      childCount: posts.length,
                    ),
                  );
                },
                orElse: () {
                  if (_isLoading || myPostsState.isLoading) {
                     return const SliverToBoxAdapter(
                      child: Center(
                          child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator())),
                    );
                  }
                  return SliverToBoxAdapter(
                    child: Center(
                        child: Text(
                            myPostsState.error?.toString() ?? 'Failed to load posts')),
                  );
                }
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 48), // Bottom padding
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedInHeader(bool isDark, int connectionCount) {
    final avatarUrl = _profile!['profilePictureUrl'] as String?;
    final name = _profile!['name'] ?? 'Unknown User';
    final bio = _profile!['bio'] ?? 'Career Professional';
    final location = _profile!['location'] ?? '';
    
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner & Avatar Stack
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.bottomLeft,
              clipBehavior: Clip.none,
              children: [
                // Banner
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFA0B4CB),
                      // Optional: Add a gradient for a more premium feel
                      gradient: isDark 
                        ? const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]) 
                        : const LinearGradient(colors: [AppTheme.userPrimaryBlue, Color(0xFF7E9EC9)]),
                    ),
                  ),
                ),
                // Custom Banner Edit button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: AppTheme.userPrimaryBlue, size: 20),
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner upload coming soon')));
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
                // Avatar
                Positioned(
                  left: 24,
                  bottom: 0,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: isDark ? Colors.black26 : Colors.grey.shade200,
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? CachedNetworkImageProvider(ImageHelper.getImageUrl(avatarUrl)!) : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppTheme.userPrimaryBlue,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.userPrimaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit Profile Icon
                // Positioned(
                //   right: 24,
                //   bottom: 12,
                //   child: IconButton(
                //     icon: Icon(Icons.edit, color: isDark ? Colors.white70 : AppTheme.gray600),
                //     onPressed: () => _showEditProfileSheet(context, isDark),
                //   ),
                // )
              ],
            ),
          ),
          
          // Profile Info Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bio.isEmpty ? 'Update your headline' : bio,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (location.isNotEmpty) ...[
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : AppTheme.gray500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.gray500)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Contact info',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.userPrimaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        context.push('/connections');
                      },
                      child: Text(
                        '${_socialStats['connectionsCount'] ?? 0} connections',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.userPrimaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showEditProfileSheet(context, isDark),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.userPrimaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Edit profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        // Optional Add section behavior
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.white38 : AppTheme.gray400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      child: Text('Add section', style: TextStyle(color: isDark ? Colors.white : AppTheme.gray700, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAboutSection(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'About',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: isDark ? Colors.white70 : AppTheme.gray600),
                onPressed: () => _showEditProfileSheet(context, isDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _profile!['bio']?.isNotEmpty == true
                ? _profile!['bio']
                : 'Write about yourself, your career aspirations, and your professional experience.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : AppTheme.gray900,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Private Account'),
                    subtitle: const Text('Control who can see your profile and activity'),
                    value: _isPrivate,
                    activeColor: AppTheme.userPrimaryBlue,
                    onChanged: (val) async {
                      setModalState(() => _isPrivate = val);
                      setState(() => _isPrivate = val);
                      try {
                        await ref.read(apiServiceProvider).updateUserProfile({'isPrivate': val});
                        ref.invalidate(currentUserProvider);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account is now ${val ? "Private" : "Public"}')));
                      } catch (e) {
                         setModalState(() => _isPrivate = !val);
                         setState(() => _isPrivate = !val);
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update privacy settings')));
                      }
                    },
                    secondary: Icon(Remix.lock_line, color: isDark ? Colors.white70 : AppTheme.gray700),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Logout'),
                    leading: Icon(Remix.logout_box_line, color: isDark ? Colors.white70 : AppTheme.gray700),
                    onTap: () async {
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.userPrimaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        if (mounted) Navigator.pop(context); // Close sheet
                        await ref.read(appAuthProvider.notifier).logout();
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently remove your account and data'),
                    leading: const Icon(Remix.delete_bin_line, color: Colors.red),
                    onTap: () => _handleDeleteAccount(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is permanent and cannot be undone. All your data will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
       Navigator.pop(context); // Close the settings sheet
      try {
        await ref.read(apiServiceProvider).deleteUserProfile();
        await ref.read(appAuthProvider.notifier).logout();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete account')));
      }
    }
  }
}
