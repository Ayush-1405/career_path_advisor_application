import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import '../../models/resume_profile.dart';
import '../../widgets/animated_screen.dart';

class ResumeBuilderScreen extends ConsumerStatefulWidget {
  const ResumeBuilderScreen({super.key});
  @override
  ConsumerState<ResumeBuilderScreen> createState() =>
      _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends ConsumerState<ResumeBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillsController = TextEditingController();
  final _educationController = TextEditingController();
  final _experienceController = TextEditingController();
  int _templateIndex = 0;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isGenerating = false;
  String? _error;
  ResumeProfile? _resume;
  String? _userId;
  Uint8List? _generatedPdfBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLoad();
    });
  }

  Future<void> _initLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userMap = await ref.read(tokenServiceProvider.notifier).getUser();
      final userId =
          userMap?['id']?.toString() ?? userMap?['userId']?.toString() ?? '';
      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Login required';
        });
        return;
      }
      _userId = userId;

      // Fetch resume profile from backend (real stored data)
      try {
        final data = await ref
            .read(apiServiceProvider)
            .fetchResumeProfile(userId);
        final profile = ResumeProfile.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        _resume = profile;
        _fillControllers(profile);
      } catch (_) {
        // If not found, keep empty form but allow upload
      }
    } catch (e) {
      _error = 'Failed to load resume data';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _fillControllers(ResumeProfile profile) {
    _nameController.text = profile.name ?? '';
    _emailController.text = profile.email ?? '';
    _phoneController.text = profile.phone ?? '';
    _summaryController.text = profile.summary ?? '';
    _skillsController.text = profile.skills.join(', ');

    // Use details-only view for editable textareas
    _educationController.text = profile.education
        .map((e) => e.details ?? '')
        .where((e) => e.isNotEmpty)
        .join('\n');
    _experienceController.text = profile.experience
        .map((e) => e.title ?? '')
        .where((e) => e.isNotEmpty)
        .join('\n');
  }

  Future<void> _pickAndUploadResume() async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final path = file.path;
      if (path == null || path.isEmpty) {
        throw Exception('Could not read file path');
      }
      final resp = await ref
          .read(apiServiceProvider)
          .uploadResumeFile(filePath: path, fileName: file.name);
      final map = resp is Map
          ? Map<String, dynamic>.from(resp)
          : <String, dynamic>{};
      final resumeMap = map['resume'];
      if (resumeMap is Map) {
        final profile = ResumeProfile.fromJson(
          Map<String, dynamic>.from(resumeMap),
        );
        _resume = profile;
        _fillControllers(profile);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume uploaded and parsed')),
      );
    } catch (e) {
      setState(() {
        _error = 'Upload failed: $e';
      });
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveResumeData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final skills = _skillsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final educationLines = _educationController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final expLines = _experienceController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final payload = {
        'userId': userId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'summary': _summaryController.text.trim(),
        'skills': skills,
        'education': educationLines.map((l) => {'details': l}).toList(),
        'experience': expLines
            .map((l) => {'title': l, 'highlights': []})
            .toList(),
        'projects': [],
      };

      final updated = await ref
          .read(apiServiceProvider)
          .updateResumeProfile(payload);
      if (updated is Map) {
        _resume = ResumeProfile.fromJson(Map<String, dynamic>.from(updated));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resume data saved')));
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generatePdf() async {
    if (_isGenerating) return;
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      // Ensure latest edits are persisted before PDF generation
      await _saveResumeData();
      final bytes = await ref
          .read(apiServiceProvider)
          .generateResumePdf(userId);
      if (!mounted) return;
      setState(() {
        _generatedPdfBytes = bytes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated from your real data')),
      );
    } catch (e) {
      setState(() => _error = 'Generate PDF failed: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _uploadGeneratedPdf() async {
    if (_generatedPdfBytes == null) {
      setState(() => _error = 'Generate PDF first');
      return;
    }
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _error = null;
    });
    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) throw Exception('Login required');

      final fileName =
          'resume_generated_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final resp = await ref
          .read(apiServiceProvider)
          .uploadResumeBytes(bytes: _generatedPdfBytes!, fileName: fileName);
      final map = resp is Map
          ? Map<String, dynamic>.from(resp)
          : <String, dynamic>{};
      final resumeMap = map['resume'];
      if (resumeMap is Map) {
        final profile = ResumeProfile.fromJson(
          Map<String, dynamic>.from(resumeMap),
        );
        _resume = profile;
        _fillControllers(profile);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generated PDF uploaded successfully')),
      );
    } catch (e) {
      setState(() => _error = 'Upload generated PDF failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resume Builder'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Upload Resume (PDF/DOCX)',
              onPressed: _isUploading ? null : _pickAndUploadResume,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
            ),
            PopupMenuButton<int>(
              initialValue: _templateIndex,
              onSelected: (i) => setState(() => _templateIndex = i),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 0, child: Text('Modern Compact')),
                PopupMenuItem(value: 1, child: Text('Classic Header')),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading
                                ? null
                                : _pickAndUploadResume,
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              _isUploading ? 'Uploading...' : 'Upload PDF/DOCX',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _initLoad,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reload'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              helperText: 'Use the name you want shown to employers',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Full name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email address',
                              helperText: 'Example: yourname@example.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              hintText: 'Enter your phone number',
                              helperText: 'Include country code if applying abroad',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              if (v.trim().length < 10) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _summaryController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Professional Summary',
                              hintText: 'Briefly describe your background',
                              helperText: '2–3 sentences about your experience and goals',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _skillsController,
                            decoration: InputDecoration(
                              labelText: 'Skills (comma separated)',
                              hintText: 'e.g. Flutter, Java, Python',
                              helperText: 'Example: Flutter, Dart, REST APIs, Firebase',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.extension_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _educationController,
                            decoration: InputDecoration(
                              labelText: 'Education',
                              hintText: 'Enter your educational background',
                              helperText: 'Example: BCA, XYZ University, 2022 (8.5 CGPA)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.school_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _experienceController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: 'Experience',
                              hintText: 'Describe your work experience',
                              helperText: 'List your roles, companies, dates, and key achievements',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 420,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gray200),
                      ),
                      child: _generatedPdfBytes == null
                          ? Center(
                              child: Text(
                                'Generate a PDF to preview it here.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : PdfPreview(
                              build: (format) async => _generatedPdfBytes!,
                              canChangeOrientation: false,
                              canChangePageFormat: false,
                              allowSharing: true,
                              allowPrinting: true,
                              pdfFileName: 'resume.pdf',
                            ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 420;
                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveResumeData,
                                icon: const Icon(Icons.save),
                                label: Text(_isSaving ? 'Saving...' : 'Save'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _isGenerating ? null : _generatePdf,
                                icon: const Icon(Icons.picture_as_pdf),
                                label: Text(
                                  _isGenerating
                                      ? 'Generating...'
                                      : 'Generate PDF',
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed:
                                    (_generatedPdfBytes == null || _isUploading)
                                    ? null
                                    : _uploadGeneratedPdf,
                                icon: const Icon(Icons.cloud_upload_outlined),
                                label: Text(
                                  _isUploading
                                      ? 'Uploading...'
                                      : 'Upload Generated PDF',
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _generatedPdfBytes == null
                                    ? null
                                    : () async {
                                        await Printing.sharePdf(
                                          bytes: _generatedPdfBytes!,
                                          filename: 'resume.pdf',
                                        );
                                      },
                                icon: const Icon(Icons.share),
                                label: const Text('Share PDF'),
                              ),
                            ],
                          );
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: (constraints.maxWidth - 24) / 2,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveResumeData,
                                icon: const Icon(Icons.save),
                                label: Text(_isSaving ? 'Saving...' : 'Save'),
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 24) / 2,
                              child: OutlinedButton.icon(
                                onPressed: _isGenerating ? null : _generatePdf,
                                icon: const Icon(Icons.picture_as_pdf),
                                label: Text(
                                  _isGenerating
                                      ? 'Generating...'
                                      : 'Generate PDF',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: OutlinedButton.icon(
                                onPressed:
                                    (_generatedPdfBytes == null || _isUploading)
                                    ? null
                                    : _uploadGeneratedPdf,
                                icon: const Icon(Icons.cloud_upload_outlined),
                                label: Text(
                                  _isUploading
                                      ? 'Uploading...'
                                      : 'Upload Generated PDF',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: OutlinedButton.icon(
                                onPressed: _generatedPdfBytes == null
                                    ? null
                                    : () async {
                                        await Printing.sharePdf(
                                          bytes: _generatedPdfBytes!,
                                          filename: 'resume.pdf',
                                        );
                                      },
                                icon: const Icon(Icons.share),
                                label: const Text('Share PDF'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
