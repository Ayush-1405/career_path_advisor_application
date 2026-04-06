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
  String _analysisStep = '';

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
      _analysisStep = 'Fetching previous analysis...';
      _selectedFile = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
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
      _analysisStep = 'Uploading resume...';
    });

    try {
      if (_selectedFile!.path == null) {
        throw Exception('File path not available');
      }

      // Simulation steps for UX
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _analysisStep = 'Extracting skills and experience...');
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _analysisStep = 'Calculating domain match score...');
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _analysisStep = 'Finalizing feedback...');

      final result = await ref
          .read(apiServiceProvider)
          .uploadResume(_selectedFile!.path!, _selectedFile!.name);

      if (!mounted) return;
      setState(() {
        _analysisResult = result is Map<String, dynamic>
            ? result
            : {'message': 'Analysis complete'};
      });
      _fetchExistingResumes();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.gray900),
            onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
          ),
          title: Text(
            'Resume Deep Scan',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.gray900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Gradient Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.psychology, color: Colors.white, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'AI Intelligent Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your resume to receive AI-powered career growth insights and skill matching results.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (_isLoading) _buildLoadingState(isDark)
              else if (_analysisResult != null) _buildResultState(isDark)
              else _buildUploadState(isDark),
              
              const SizedBox(height: 32),
              
              if (_existingResumes.isNotEmpty && !_isLoading && _analysisResult == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Previous Scans',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/my-resumes'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingResumes.length,
                    itemBuilder: (context, index) {
                      final resume = _existingResumes[index];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => _analyzeExistingResume(resume),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.history, color: Color(0xFF6366F1), size: 24),
                                const SizedBox(height: 8),
                                Text(
                                  resume['fileName'] ?? 'Resume',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : AppTheme.gray900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadState(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _selectedFile != null ? const Color(0xFF6366F1) : (isDark ? Colors.white10 : Colors.grey.shade200),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.upload_file,
                      size: 150,
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                          size: 48,
                          color: _selectedFile != null ? Colors.green : const Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFile?.name ?? 'Tap to select resume',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                        if (_selectedFile == null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'PDF, DOCX up to 5MB',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : AppTheme.gray500),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _analyzeResume,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text('Start Deep Scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 80,
            width: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Processing...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _analysisStep,
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white38 : AppTheme.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState(bool isDark) {
    final score = _analysisResult!['overallScore'] ?? 0;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 20,
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
                          'Scan Complete',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                        Text(
                          'Overall matching score',
                          style: TextStyle(color: isDark ? Colors.white38 : AppTheme.gray500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildModernResultItem('Strengths', _analysisResult!['strengths']?.toString() ?? 'Checking...', isDark, Colors.green),
              const SizedBox(height: 16),
              _buildModernResultItem('Improvements', _analysisResult!['improvements']?.toString() ?? 'N/A', isDark, Colors.orange),
              if (_analysisResult!['careerPath'] != null) ...[
                const SizedBox(height: 16),
                _buildModernResultItem('Career Roadmap', _analysisResult!['careerPath']?.toString() ?? 'Analyzing...', isDark, const Color(0xFF6366F1)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // CALL TO ACTION
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => context.go('/home'), // Home shows recommendations usually
            child: Row(
              children: [
                const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Boost Your Career',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Explore paths matching your skills',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _analysisResult = null;
            _selectedFile = null;
          }),
          child: const Text('Scan Another Resume'),
        ),
      ],
    );
  }

  Widget _buildModernResultItem(String label, String value, bool isDark, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppTheme.gray700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : AppTheme.gray600, height: 1.5),
        ),
      ],
    );
  }
}
