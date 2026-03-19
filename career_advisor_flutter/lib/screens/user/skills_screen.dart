import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/animated_screen.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  bool _testStarted = false;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _error;
  int _currentQuestion = 0;
  Map<String, int> _answers = {};
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await ref.read(apiServiceProvider).getSkillsQuestions();
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load assessment questions';
          _isLoading = false;
        });
      }
    }
  }

  void _startTest() {
    setState(() {
      _testStarted = true;
      _currentQuestion = 0;
      _answers = {};
    });
  }

  void _answerQuestion(int answerIndex) {
    setState(() {
      _answers[_currentQuestion.toString()] = answerIndex;
      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      } else {
        _submitResults();
      }
    });
  }

  Future<void> _submitResults() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate a simple score or just send raw answers
      // Sending raw answers allows backend to process
      await ref
          .read(apiServiceProvider)
          .trackUserActivity(
            'skills_assessment',
            activityData: {
              'answers': _answers,
              'timestamp': DateTime.now().toIso8601String(),
              'completed': true,
            },
          );

      if (!mounted) return;
      _showResults();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit results: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Assessment Complete'),
        content: const Text(
          'Your skills assessment has been saved. We will use this to recommend better career paths for you.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/dashboard'); // Go to dashboard
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AnimatedScreen(
        child: Scaffold(
        backgroundColor: AppTheme.gray50,
        appBar: AppBar(
          title: const Text('Skills Assessment'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      );
    }

    if (_error != null) {
      return AnimatedScreen(
        child: Scaffold(
          backgroundColor: AppTheme.gray50,
          appBar: AppBar(
            title: const Text('Skills Assessment'),
            automaticallyImplyLeading: false,
          ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loadQuestions,
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
          title: const Text('Skills Assessment'),
          automaticallyImplyLeading: false,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_testStarted) ...[
              const Text(
                'Skills Assessment',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Take our comprehensive skills assessment to identify your strengths and get personalized recommendations.',
                style: TextStyle(fontSize: 16, color: AppTheme.gray600),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assessment,
                        size: 64,
                        color: AppTheme.userPrimaryBlue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'This assessment will take approximately 10-15 minutes',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: AppTheme.gray700),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _startTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.userPrimaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'Start Assessment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_isSubmitting) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Submitting results...',
                        style: TextStyle(fontSize: 16, color: AppTheme.gray700),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Question ${_currentQuestion + 1} of ${_questions.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _questions[_currentQuestion]['question'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...(_questions[_currentQuestion]['options']
                              as List<String>)
                          .asMap()
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ElevatedButton(
                                onPressed: () => _answerQuestion(entry.key),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.gray100,
                                  foregroundColor: AppTheme.gray900,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: Text(entry.value),
                              ),
                            ),
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
