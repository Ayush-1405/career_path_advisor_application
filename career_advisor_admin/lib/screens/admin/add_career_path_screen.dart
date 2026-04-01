import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class AddCareerPathScreen extends ConsumerStatefulWidget {
  const AddCareerPathScreen({super.key});

  @override
  ConsumerState<AddCareerPathScreen> createState() =>
      _AddCareerPathScreenState();
}

class _AddCareerPathScreenState extends ConsumerState<AddCareerPathScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _salaryController = TextEditingController();
  final _growthController = TextEditingController();
  final _popularityController = TextEditingController(text: '0');
  final _skillsController = TextEditingController();
  final _levelController = TextEditingController();
  final _imageController = TextEditingController();
  final _progressionController = TextEditingController();

  bool _isSaving = false;

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
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final progression = _progressionController.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) {
          final parts = l.split(':');
          return {
            'level': parts.isNotEmpty ? parts[0].trim() : '',
            'salary': parts.length > 1 ? parts[1].trim() : '',
          };
        })
        .toList();

    final data = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'level': _levelController.text,
      'category': _categoryController.text,
      'image': _imageController.text,
      'averageSalary': _salaryController.text,
      'growth': _growthController.text,
      'popularity': int.tryParse(_popularityController.text) ?? 0,
      'requiredSkills': _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'careerProgression': progression,
    };

    try {
      await ref.read(apiServiceProvider).createCareerPath(data);

      if (mounted) {
        context.pop(true); // Return true to indicate refresh needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Career path added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String msg = 'Error saving: $e';
      if (e is DioException) {
        msg = e.response?.data?['message'] ?? e.message ?? msg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Add New Career Path'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.adminPrimaryRed,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'Basic Information',
                      icon: Icons.info_outline_rounded,
                      children: [
                        _buildField(
                          'Job Title',
                          _titleController,
                          hint: 'e.g. Software Engineer',
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                'Category',
                                _categoryController,
                                hint: 'e.g. IT & Software',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                'Level',
                                _levelController,
                                hint: 'e.g. Entry, Mid, Senior',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Salary & Growth',
                      icon: Icons.trending_up_rounded,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                'Avg. Salary',
                                _salaryController,
                                hint: '₹5L - ₹12L',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                'Growth Rate',
                                _growthController,
                                hint: '15% YOY',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          'Popularity (0-100)',
                          _popularityController,
                          isNumber: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Media & Details',
                      icon: Icons.image_outlined,
                      children: [
                        _buildField(
                          'Image URL',
                          _imageController,
                          hint: 'https://example.com/image.png',
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          'Description',
                          _descriptionController,
                          isMultiline: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Requirements & Progression',
                      icon: Icons.list_alt_rounded,
                      children: [
                        _buildField(
                          'Skills (comma separated)',
                          _skillsController,
                          hint: 'Python, SQL, AWS',
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          'Career Progression (level:salary)',
                          _progressionController,
                          isMultiline: true,
                          hint: 'Junior:5L\nSenior:12L',
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.adminPrimaryRed),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isMultiline = false,
    bool isNumber = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: isMultiline ? 4 : 1,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
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
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }
}
