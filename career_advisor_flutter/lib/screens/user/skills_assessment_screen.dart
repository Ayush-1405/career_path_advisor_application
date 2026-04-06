import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remixicon/remixicon.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import '../../services/api_service.dart';

class SkillsAssessmentScreen extends ConsumerStatefulWidget {
  const SkillsAssessmentScreen({super.key});

  @override
  ConsumerState<SkillsAssessmentScreen> createState() =>
      _SkillsAssessmentScreenState();
}

class _SkillsAssessmentScreenState
    extends ConsumerState<SkillsAssessmentScreen> {
  bool _isTestStarted = false;
  Map<String, dynamic>? _testResults;

  // Test State
  int _currentQuestion = 0;
  final Map<int, dynamic> _answers = {};
  int _timeLeft = 1200; // 20 minutes
  Timer? _timer;

  final List<Map<String, dynamic>> _questions = [
    {
      'id': 1,
      'category': 'Technical',
      'question': 'How would you rate your proficiency in JavaScript?',
      'type': 'scale',
      'scale': 'Beginner to Expert (1-5)',
    },
    {
      'id': 2,
      'category': 'Technical',
      'question': 'Which programming languages are you most comfortable with?',
      'type': 'multiple',
      'options': [
        'JavaScript',
        'Python',
        'Java',
        'C++',
        'React',
        'Angular',
        'Vue.js',
        'Node.js',
      ],
    },
    {
      'id': 3,
      'category': 'Technical',
      'question': 'How experienced are you with cloud platforms?',
      'type': 'scale',
      'scale': 'No experience to Expert (1-5)',
    },
    {
      'id': 4,
      'category': 'Technical',
      'question': 'Which database technologies have you worked with?',
      'type': 'multiple',
      'options': [
        'MySQL',
        'PostgreSQL',
        'MongoDB',
        'Redis',
        'Oracle',
        'SQLite',
        'Cassandra',
        'DynamoDB',
      ],
    },
    {
      'id': 5,
      'category': 'Technical',
      'question': 'Rate your experience with version control systems (Git)',
      'type': 'scale',
      'scale': 'Beginner to Expert (1-5)',
    },
    {
      'id': 6,
      'category': 'Leadership',
      'question': 'How comfortable are you leading a team?',
      'type': 'scale',
      'scale': 'Not comfortable to Very comfortable (1-5)',
    },
    {
      'id': 7,
      'category': 'Leadership',
      'question': 'Have you mentored junior developers or colleagues?',
      'type': 'choice',
      'options': [
        'Never',
        'Occasionally',
        'Regularly',
        'It\'s a major part of my role',
      ],
    },
    {
      'id': 8,
      'category': 'Communication',
      'question': 'How would you rate your presentation skills?',
      'type': 'scale',
      'scale': 'Poor to Excellent (1-5)',
    },
    {
      'id': 9,
      'category': 'Communication',
      'question': 'How comfortable are you with technical writing?',
      'type': 'scale',
      'scale': 'Not comfortable to Very comfortable (1-5)',
    },
    {
      'id': 10,
      'category': 'Problem Solving',
      'question': 'When faced with a complex problem, what\'s your approach?',
      'type': 'choice',
      'options': [
        'Break it down into smaller parts',
        'Research similar solutions online',
        'Ask for help from colleagues',
        'Try different approaches until one works',
      ],
    },
    {
      'id': 11,
      'category': 'Problem Solving',
      'question': 'How do you handle debugging complex issues?',
      'type': 'choice',
      'options': [
        'Systematic step-by-step approach',
        'Use debugging tools and logs',
        'Discuss with team members',
        'Take breaks and come back with fresh perspective',
      ],
    },
    {
      'id': 12,
      'category': 'Technical',
      'question': 'Rate your knowledge of software architecture patterns',
      'type': 'scale',
      'scale': 'Beginner to Expert (1-5)',
    },
    {
      'id': 13,
      'category': 'Technical',
      'question': 'Which development methodologies have you used?',
      'type': 'multiple',
      'options': [
        'Agile',
        'Scrum',
        'Waterfall',
        'Kanban',
        'DevOps',
        'CI/CD',
        'TDD',
        'BDD',
      ],
    },
    {
      'id': 14,
      'category': 'Adaptability',
      'question': 'How quickly do you adapt to new technologies?',
      'type': 'scale',
      'scale': 'Very slowly to Very quickly (1-5)',
    },
    {
      'id': 15,
      'category': 'Adaptability',
      'question': 'How do you stay updated with industry trends?',
      'type': 'choice',
      'options': [
        'Regular reading of tech blogs and articles',
        'Attending conferences and meetups',
        'Online courses and certifications',
        'Networking with other professionals',
      ],
    },
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _isTestStarted = true;
      _timeLeft = 1200;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _completeTest();
          }
        });
      }
    });
  }

  void _handleAnswer(dynamic answer) {
    setState(() {
      _answers[_questions[_currentQuestion]['id'] as int] = answer;
    });
  }

  void _handleNext() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
      });
    } else {
      _completeTest();
    }
  }

  void _handlePrevious() {
    if (_currentQuestion > 0) {
      setState(() {
        _currentQuestion--;
      });
    }
  }

  void _completeTest() {
    _timer?.cancel();
    // For now we keep client-side summary but also notify backend
    final summary = {
      'answers': _answers,
      'completedAt': DateTime.now().toIso8601String(),
    };
    setState(() {
      _testResults = {
        'overall': 82,
        'categories': {
          'technical': 85,
          'leadership': 75,
          'communication': 80,
          'problemSolving': 90,
          'adaptability': 88,
        },
        'strengths': [
          'Strong problem-solving abilities',
          'High adaptability to new technologies',
          'Solid technical foundation',
          'Good communication skills',
        ],
        'improvements': [
          'Leadership and mentoring skills',
          'Advanced architecture knowledge',
          'Public speaking and presentation',
          'Team management experience',
        ],
        'recommendations': [
          {
            'title': 'Senior Software Engineer',
            'match': 92,
            'description':
                'Your technical skills and problem-solving abilities make you an excellent candidate',
          },
          {
            'title': 'Technical Lead',
            'match': 78,
            'description':
                'With some leadership development, you could excel in this role',
          },
          {
            'title': 'Solutions Architect',
            'match': 75,
            'description':
                'Your adaptability and technical knowledge are strong foundations',
          },
        ],
        'learningPath': [
          {
            'skill': 'Leadership',
            'courses': [
              'Leadership Fundamentals',
              'Team Management',
              'Mentoring Skills',
            ],
            'priority': 'High',
          },
          {
            'skill': 'System Design',
            'courses': [
              'Scalable Systems',
              'Architecture Patterns',
              'Microservices',
            ],
            'priority': 'Medium',
          },
          {
            'skill': 'Public Speaking',
            'courses': [
              'Presentation Skills',
              'Technical Communication',
              'Conference Speaking',
            ],
            'priority': 'Medium',
          },
        ],
      };
    });
    // Fire-and-forget: track on backend + save locally so dashboard shows status even if backend sync fails
    Future.microtask(() async {
      try {
        await ref
            .read(apiServiceProvider)
            .trackUserActivity(
              'skills_assessment_completed',
              activityData: summary,
            );
      } catch (_) {}
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('skills_assessment_completed', true);
      } catch (_) {}
    });
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
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
                context.go('/feed');
              }
            },
          ),
          title: const Text('Skills Assessment'),
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!_isTestStarted && _testResults == null) _buildIntro(isDark),
              if (_isTestStarted && _testResults == null) _buildTest(isDark),
              if (_testResults != null) _buildResults(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          'Skills Assessment',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Take our comprehensive skills assessment to identify your strengths, discover areas for improvement, and get personalized career recommendations.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : AppTheme.gray600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildIntroItem(
                    icon: Remix.time_line,
                    color: Colors.blue,
                    title: '15-20 Minutes',
                    subtitle: 'Complete assessment duration',
                    isDark: isDark,
                  ),
                  _buildIntroItem(
                    icon: Remix.question_line,
                    color: Colors.purple,
                    title: '15 Questions',
                    subtitle: 'Comprehensive skill evaluation',
                    isDark: isDark,
                  ),
                  _buildIntroItem(
                    icon: Remix.award_line,
                    color: Colors.green,
                    title: 'Detailed Report',
                    subtitle: 'Personalized insights',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What You'll Get:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.gray900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      'Comprehensive skills profile across technical and soft skills',
                      isDark,
                    ),
                    _buildFeatureItem(
                      'Personalized career path recommendations',
                      isDark,
                    ),
                    _buildFeatureItem(
                      'Learning recommendations to fill skill gaps',
                      isDark,
                    ),
                    _buildFeatureItem(
                      'Salary insights and growth projections',
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Start Assessment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntroItem({
    required IconData icon,
    required MaterialColor color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.1) : color.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? color.shade400 : color.shade600,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white60 : AppTheme.gray600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Remix.check_line,
            color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.gray700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTest(bool isDark) {
    final currentQ = _questions[_currentQuestion];
    final progress = ((_currentQuestion + 1) / _questions.length);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Question ${_currentQuestion + 1} of ${_questions.length}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    height: 8,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Time: ${_formatTime(_timeLeft)}',
                style: TextStyle(
                  color: isDark ? Colors.white60 : AppTheme.gray600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Question
          Text(
            currentQ['category'] as String,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentQ['question'] as String,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          _buildQuestionInput(currentQ, isDark),
          const SizedBox(height: 32),

          // Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _currentQuestion == 0 ? null : _handlePrevious,
                child: Text(
                  'Previous',
                  style: TextStyle(
                    color: isDark
                        ? (_currentQuestion == 0
                              ? Colors.white24
                              : Colors.white70)
                        : null,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _answers.containsKey(currentQ['id'])
                    ? _handleNext
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _currentQuestion == _questions.length - 1
                      ? 'Complete'
                      : 'Next',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(Map<String, dynamic> question, bool isDark) {
    final type = question['type'] as String;
    final currentAnswer = _answers[question['id']];

    if (type == 'scale') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['scale'] as String,
            style: TextStyle(
              color: isDark ? Colors.white60 : AppTheme.gray600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final value = index + 1;
              final isSelected = currentAnswer == value;
              return InkWell(
                onTap: () => _handleAnswer(value),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? const Color(0xFF0F172A) : Colors.white),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? Colors.white10 : Colors.grey.shade300),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppTheme.gray900),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    } else if (type == 'choice') {
      final options = question['options'] as List;
      return Column(
        children: options.map((option) {
          final isSelected = currentAnswer == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _handleAnswer(option),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.1)
                      : (isDark ? const Color(0xFF0F172A) : Colors.white),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  option.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.blue.shade400 : Colors.blue.shade900)
                        : (isDark ? Colors.white70 : AppTheme.gray900),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else if (type == 'multiple') {
      final options = question['options'] as List;
      final currentAnswers = (currentAnswer as List?) ?? [];

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: options.map((option) {
          final isSelected = currentAnswers.contains(option);
          return InkWell(
            onTap: () {
              final newAnswers = List.from(currentAnswers);
              if (isSelected) {
                newAnswers.remove(option);
              } else {
                newAnswers.add(option);
              }
              _handleAnswer(newAnswers);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withOpacity(0.1)
                    : (isDark ? const Color(0xFF0F172A) : Colors.white),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                option.toString(),
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.blue.shade400 : Colors.blue.shade900)
                      : (isDark ? Colors.white70 : AppTheme.gray900),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildResults(bool isDark) {
    final results = _testResults!;
    final categories = results['categories'] as Map<String, dynamic>;
    final strengths = (results['strengths'] as List).cast<String>();
    final improvements = (results['improvements'] as List).cast<String>();
    final recommendations = (results['recommendations'] as List)
        .cast<Map<String, dynamic>>();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.blue.shade50, Colors.purple.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                results['overall'].toString(),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              Text(
                'Overall Skills Score',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : AppTheme.gray600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You scored higher than 78% of professionals in your field',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : AppTheme.gray500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Categories
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: categories.entries.map((entry) {
            final score = entry.value as int;
            final color = score >= 80
                ? Colors.green
                : (score >= 60 ? Colors.orange : Colors.red);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.toString(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? color.shade400 : color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key
                        .replaceAllMapped(
                          RegExp(r'([A-Z])'),
                          (match) => ' ${match.group(1)}',
                        )
                        .replaceFirstMapped(
                          RegExp(r'^[a-z]'),
                          (match) => match.group(0)!.toUpperCase(),
                        ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? color.shade400 : color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Strengths & Improvements
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildListCard(
                'Your Strengths',
                strengths,
                Colors.green,
                Remix.star_line,
                Remix.check_line,
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildListCard(
                'Areas for Growth',
                improvements,
                Colors.orange,
                Remix.arrow_up_line,
                Remix.arrow_right_line,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recommendations
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended Career Paths',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 16),
              ...recommendations.map(
                (rec) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rec['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${rec['match']}% Match',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.green.shade400
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rec['description'],
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isTestStarted = false;
                _testResults = null;
                _currentQuestion = 0;
                _answers.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retake Assessment'),
          ),
        ),
      ],
    );
  }

  Widget _buildListCard(
    String title,
    List<String> items,
    MaterialColor color,
    IconData titleIcon,
    IconData itemIcon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : color.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                titleIcon,
                color: isDark ? color.shade400 : color.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    itemIcon,
                    color: isDark ? color.shade400 : color.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
