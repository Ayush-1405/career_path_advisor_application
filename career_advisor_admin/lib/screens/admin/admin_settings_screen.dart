import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Form Fields
  final _siteNameController = TextEditingController();
  final _resumeMaxSizeController = TextEditingController();
  final _supportedFormatsController = TextEditingController();

  bool _allowRegistrations = true;
  bool _requireEmailVerification = false;
  bool _aiAssistantEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _resumeMaxSizeController.dispose();
    _supportedFormatsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to load from API first
      try {
        final apiService = ref.read(apiServiceProvider);
        final settings = await apiService.fetchAdminSettings();
        if (settings != null) {
          _updateStateFromSettings(settings);
          setState(() => _isLoading = false);
          return;
        }
      } catch (e) {
        debugPrint('API load failed, falling back to local storage: $e');
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      if (mounted) {
        setState(() {
          _siteNameController.text = 
              prefs.getString('admin_site_name') ?? 'Career Advisor';
          
          _resumeMaxSizeController.text = 
              (prefs.getInt('admin_resume_max_size') ?? 5).toString();

          final formats = prefs.getStringList('admin_supported_formats') ?? 
              ['pdf', 'doc', 'docx'];
          _supportedFormatsController.text = formats.join(', ');

          _allowRegistrations = 
              prefs.getBool('admin_allow_registrations') ?? true;
          _requireEmailVerification = 
              prefs.getBool('admin_require_email_verification') ?? false;
          _aiAssistantEnabled = 
              prefs.getBool('admin_ai_assistant_enabled') ?? true;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load settings. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _updateStateFromSettings(Map<String, dynamic> settings) {
    if (!mounted) return;
    setState(() {
      _siteNameController.text = settings['siteName'] ?? '';
      _resumeMaxSizeController.text = (settings['resumeMaxSizeMb'] ?? 5)
          .toString();

      // Handle supported formats (could be List or String)
      final formats = settings['supportedFormats'];
      if (formats is List) {
        _supportedFormatsController.text = formats.join(', ');
      } else {
        _supportedFormatsController.text = formats?.toString() ?? '';
      }

      _allowRegistrations = settings['allowRegistrations'] ?? true;
      _requireEmailVerification =
          settings['requireEmailVerification'] ?? false;
      _aiAssistantEnabled = settings['aiAssistantEnabled'] ?? true;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final payload = {
        'siteName': _siteNameController.text,
        'allowRegistrations': _allowRegistrations,
        'requireEmailVerification': _requireEmailVerification,
        'resumeMaxSizeMb': int.tryParse(_resumeMaxSizeController.text) ?? 5,
        'supportedFormats': _supportedFormatsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'aiAssistantEnabled': _aiAssistantEnabled,
      };

      // Always save to SharedPreferences as backup/cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_site_name', _siteNameController.text);
      await prefs.setInt('admin_resume_max_size', 
          int.tryParse(_resumeMaxSizeController.text) ?? 5);
      await prefs.setStringList('admin_supported_formats', 
          payload['supportedFormats'] as List<String>);
      await prefs.setBool('admin_allow_registrations', _allowRegistrations);
      await prefs.setBool('admin_require_email_verification', 
          _requireEmailVerification);
      await prefs.setBool('admin_ai_assistant_enabled', _aiAssistantEnabled);

      // Try to save to API
      bool apiSuccess = false;
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.updateAdminSettings(payload);
        apiSuccess = true;
      } catch (e) {
        debugPrint('API save failed: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiSuccess 
                ? 'Settings updated successfully' 
                : 'Settings saved locally (Server unreachable)'),
            backgroundColor: apiSuccess ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSettings,
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
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('General Settings'),
              _buildCard([
                _buildTextField(
                  controller: _siteNameController,
                  label: 'Site Name',
                  icon: Icons.web,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const Divider(),
                _buildSwitch(
                  title: 'Allow Registrations',
                  subtitle: 'Enable or disable new user signups',
                  value: _allowRegistrations,
                  onChanged: (v) => setState(() => _allowRegistrations = v),
                ),
                const Divider(),
                _buildSwitch(
                  title: 'Require Email Verification',
                  subtitle: 'Users must verify email before logging in',
                  value: _requireEmailVerification,
                  onChanged: (v) =>
                      setState(() => _requireEmailVerification = v),
                ),
              ]),

              const SizedBox(height: 32),
              _buildSectionHeader('Resume Configuration'),
              _buildCard([
                _buildTextField(
                  controller: _resumeMaxSizeController,
                  label: 'Max File Size (MB)',
                  icon: Icons.upload_file,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Must be a number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _supportedFormatsController,
                  label: 'Supported Formats',
                  hint: 'pdf, doc, docx',
                  icon: Icons.file_present,
                  helperText: 'Comma separated values (e.g. pdf, doc, docx)',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              ]),

              const SizedBox(height: 32),
              _buildSectionHeader('Features'),
              _buildCard([
                _buildSwitch(
                  title: 'AI Assistant',
                  subtitle: 'Enable AI chat assistant for users',
                  value: _aiAssistantEnabled,
                  onChanged: (v) => setState(() => _aiAssistantEnabled = v),
                ),
              ]),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isSaving ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
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
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: Colors.blue,
      contentPadding: EdgeInsets.zero,
    );
  }
}
