import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_screen.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _faqData = [
    {
      'id': 1,
      'question': 'How does the resume analysis work?',
      'answer':
          'Our AI analyzes your resume to extract key information including skills, experience level, education, and career progression. It then matches this data against our database of career paths and provides personalized recommendations.',
      'category': 'resume',
    },
    {
      'id': 2,
      'question': 'What file formats are supported for resume upload?',
      'answer':
          'We support PDF, DOC, and DOCX file formats. Files should be under 10MB in size for optimal processing.',
      'category': 'resume',
    },
    {
      'id': 3,
      'question': 'How accurate are the career path recommendations?',
      'answer':
          'Our AI has a 95% accuracy rate based on user feedback and successful career transitions. Recommendations are based on comprehensive analysis of your skills, experience, and market trends.',
      'category': 'career',
    },
    {
      'id': 4,
      'question': 'Can I take the skills assessment multiple times?',
      'answer':
          'Yes, you can retake the skills assessment as many times as you want. We recommend taking it every 6 months to track your progress and get updated recommendations.',
      'category': 'skills',
    },
    {
      'id': 5,
      'question': 'How do I access my dashboard?',
      'answer':
          'After creating an account and completing your first analysis, you can access your dashboard from the main navigation menu. Your dashboard contains all your results, recommendations, and progress tracking.',
      'category': 'account',
    },
    {
      'id': 6,
      'question': 'Is my data secure and private?',
      'answer':
          'Yes, we take data security very seriously. All uploaded documents are encrypted and stored securely. We never share your personal information with third parties without your explicit consent.',
      'category': 'privacy',
    },
    {
      'id': 7,
      'question': 'What if I disagree with the AI recommendations?',
      'answer':
          'You can provide feedback on any recommendation through your dashboard. Our AI learns from user feedback to improve future recommendations. You can also speak with our AI assistant for personalized guidance.',
      'category': 'career',
    },
    {
      'id': 8,
      'question': 'How do I delete my account?',
      'answer':
          'You can delete your account by going to Settings in your dashboard and selecting "Delete Account". Please note that this action is irreversible and will permanently remove all your data.',
      'category': 'account',
    },
  ];

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All Categories'},
    {'id': 'resume', 'name': 'Resume Analysis'},
    {'id': 'career', 'name': 'Career Paths'},
    {'id': 'skills', 'name': 'Skills Assessment'},
    {'id': 'account', 'name': 'Account'},
    {'id': 'privacy', 'name': 'Privacy & Security'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFAQs {
    final searchTerm = _searchController.text.toLowerCase();
    return _faqData.where((faq) {
      final matchesSearch =
          faq['question'].toLowerCase().contains(searchTerm) ||
          faq['answer'].toLowerCase().contains(searchTerm);
      final matchesCategory =
          _selectedCategory == 'all' || faq['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
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
          title: const Text('Help & Support'),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [Colors.blue.shade600, Colors.purple.shade600],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Find answers to common questions and get the support you need',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : Colors.blue.shade100,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for help...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        filled: true,
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Quick Links
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        int crossAxisCount;
                        double childAspectRatio;

                        if (width > 900) {
                          crossAxisCount = 3;
                          childAspectRatio = 1.6;
                        } else if (width > 600) {
                          crossAxisCount = 2;
                          childAspectRatio = 1.5;
                        } else {
                          crossAxisCount = 1;
                          childAspectRatio = 1.3;
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildQuickLink(
                              icon: Icons.support_agent,
                              color: Colors.blue,
                              title: 'Contact Support',
                              subtitle: 'Get in touch with our support team',
                              onTap: () => context.push('/contact'),
                              isDark: isDark,
                            ),
                            _buildQuickLink(
                              icon: Icons.smart_toy,
                              color: Colors.green,
                              title: 'AI Assistant',
                              subtitle: 'Chat with our AI for instant help',
                              onTap: () => context.push('/ai-assistant'),
                              isDark: isDark,
                            ),
                            _buildQuickLink(
                              icon: Icons.play_circle_outline,
                              color: Colors.purple,
                              title: 'Getting Started',
                              subtitle: 'Begin your career analysis journey',
                              onTap: () => context.push('/analyze'),
                              isDark: isDark,
                            ),
                            _buildQuickLink(
                              icon: Icons.bar_chart,
                              color: Colors.orange,
                              title: 'Skills Assessment',
                              subtitle:
                                  'Starting and understanding assessments',
                              onTap: () => context.push('/skills'),
                              isDark: isDark,
                            ),
                            _buildQuickLink(
                              icon: Icons.explore,
                              color: Colors.teal,
                              title: 'Career Paths',
                              subtitle: 'Viewing and following suggested paths',
                              onTap: () => context.push('/career-paths'),
                              isDark: isDark,
                            ),
                            _buildQuickLink(
                              icon: Icons.person,
                              color: Colors.indigo,
                              title: 'Account & Profile',
                              subtitle:
                                  'Managing sign-in, registration, and profile',
                              onTap: () => context.push('/profile'),
                              isDark: isDark,
                            ),
                            _buildQuickLink(
                              icon: Icons.lock,
                              color: Colors.red,
                              title: 'Privacy & Security',
                              subtitle: 'Data usage and permissions',
                              onTap: () => context.push('/privacy-policy'),
                              isDark: isDark,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 48),

                    // FAQ Section
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Frequently Asked Questions',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Categories
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _categories.map((category) {
                                final isSelected =
                                    _selectedCategory == category['id'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(category['name']!),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedCategory = category['id']!;
                                        });
                                      }
                                    },
                                    selectedColor: Colors.blue.shade600,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.grey.shade700),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    backgroundColor: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // FAQ List
                          if (_filteredFAQs.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No results found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your search terms or category filter',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _selectedCategory = 'all';
                                        });
                                      },
                                      child: const Text('Clear Filters'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredFAQs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final faq = _filteredFAQs[index];
                                return Card(
                                  elevation: 0,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: ExpansionTile(
                                    title: Text(
                                      faq['question'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    iconColor: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    collapsedIconColor: isDark
                                        ? Colors.white38
                                        : Colors.black54,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          16,
                                        ),
                                        child: Text(
                                          faq['answer'],
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.grey.shade700,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Additional Resources
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Still need help?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 600;

                              final emailSupport = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email Support',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Get detailed help via email',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => context.push('/contact'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Send us a message →'),
                                  ),
                                ],
                              );

                              final liveChat = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Live Chat',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Chat with our AI assistant',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/ai-assistant'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Start chatting →'),
                                  ),
                                ],
                              );

                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: emailSupport),
                                    const SizedBox(width: 24),
                                    Expanded(child: liveChat),
                                  ],
                                );
                              } else {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    emailSupport,
                                    const SizedBox(height: 24),
                                    liveChat,
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLink({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDark ? color.withOpacity(0.8) : color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

extension ListFilter<E> on List<E> {
  List<E> filter(bool Function(E) test) {
    return where(test).toList();
  }
}
