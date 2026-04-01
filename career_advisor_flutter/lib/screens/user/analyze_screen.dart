import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/animated_screen.dart';

class AnalyzeScreen extends ConsumerStatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  ConsumerState<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends ConsumerState<AnalyzeScreen> {
  bool _isLoading = false;
  PlatformFile? _selectedFile;
  Map<String, dynamic>? _analysisResult;
  List<dynamic> _existingResumes = [];
  bool _isLoadingResumes = false;

  @override
  void initState() {
    super.initState();
    _fetchExistingResumes();
  }

  Future<void> _fetchExistingResumes() async {
    setState(() => _isLoadingResumes = true);
    try {
      final resumes = await ref.read(apiServiceProvider).fetchMyResumes();
      setState(() => _existingResumes = resumes);
    } catch (e) {
      debugPrint('Error fetching resumes: $e');
    } finally {
      setState(() => _isLoadingResumes = false);
    }
  }

  Future<void> _analyzeExistingResume(dynamic resume) async {
    setState(() {
      _isLoading = true;
      _selectedFile = null; // Clear selected file if analyzing existing
    });

    try {
      final result = await ref
          .read(apiServiceProvider)
          .getResumeAnalysis(resume['id']);

      if (!mounted) return;
      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error analyzing resume: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: false,
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.single;

        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size must be less than 5MB')),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _analysisResult = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _analyzeResume() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedFile!.path == null) {
        throw Exception('File path not available');
      }

      final result = await ref
          .read(apiServiceProvider)
          .uploadResume(_selectedFile!.path!, _selectedFile!.name);

      if (!mounted) return;
      setState(() {
        _analysisResult = result is Map<String, dynamic>
            ? result
            : {'message': 'Analysis complete'};
      });
      _fetchExistingResumes(); // Refresh list after new upload
    } catch (e) {
      if (!mounted) return;
      // Fallback to simulation if API fails (for demo purposes if backend isn't ready)
      // OR just show error. User asked for "dynamic perfect", so I should show error if it fails.
      // But to be safe and not break the UX if backend is missing endpoints:
      debugPrint('Resume upload failed: $e');

      // I will keep the simulation as a fallback ONLY if the error is 404 or connection refused,
      // but strictly speaking "dynamicaly perfect" means I should trust the API.
      // However, if I break the app because the backend is missing, that's bad.
      // I'll show the error.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error analyzing resume: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedScreen(
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Resume Analyzer'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: isDark ? Colors.white : AppTheme.gray900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upload Your Resume',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get detailed insights about your skills and experience. Supported formats: PDF, DOC, DOCX. Max size: 5MB.',
              style: TextStyle(
                fontSize: 16, 
                color: isDark ? Colors.white70 : AppTheme.gray600
              ),
            ),
            const SizedBox(height: 32),
            // File picker
            Card(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: isDark ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 64,
                      color: _selectedFile != null
                          ? Colors.green
                          : AppTheme.userPrimaryBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFile?.name ?? 'No file selected',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : AppTheme.gray700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          fontSize: 14, 
                          color: isDark ? Colors.white38 : AppTheme.gray500
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: Text(
                            _selectedFile != null
                                ? 'Change File'
                                : 'Select File',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.userPrimaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _analysisResult = null;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Existing resumes section
            if (_existingResumes.isNotEmpty) ...[
              Text(
                'Or Select from Previous Uploads',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingResumes.length,
                  itemBuilder: (context, index) {
                    final resume = _existingResumes[index];
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => _analyzeExistingResume(resume),
                        child: Card(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          elevation: isDark ? 0 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white10 : Colors.transparent,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.description, color: AppTheme.userPrimaryBlue),
                                const SizedBox(height: 8),
                                Text(
                                  resume['fileName'] ?? 'Resume',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : AppTheme.gray900,
                                  ),
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
              const SizedBox(height: 24),
            ],
            // Analyze button
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.userPrimaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Analyze Resume',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            // Analysis results
            if (_analysisResult != null) ...[
              const SizedBox(height: 32),
              Card(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                elevation: isDark ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.white10 : Colors.transparent,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analysis Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ResultItem(
                        label: 'Overall Score',
                        value: '${_analysisResult!['overallScore'] ?? 0}/100',
                      ),
                      const SizedBox(height: 16),
                      _ResultItem(
                        label: 'Strengths',
                        value:
                            _analysisResult!['strengths']
                                ?.toString()
                                .split(',')
                                .join(', ') ??
                            'None detected',
                      ),
                      const SizedBox(height: 16),
                      _ResultItem(
                        label: 'Areas for Improvement',
                        value:
                            _analysisResult!['improvements']
                                ?.toString()
                                .split(',')
                                .join(', ') ??
                            'None detected',
                      ),
                      const SizedBox(height: 16),
                      _ResultItem(
                        label: 'Experience Level',
                        value: _analysisResult!['experienceLevel'] ?? 'Not specified',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;

  const _ResultItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white38 : AppTheme.gray600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16, 
            color: isDark ? Colors.white70 : AppTheme.gray900
          ),
        ),
      ],
    );
  }
}
