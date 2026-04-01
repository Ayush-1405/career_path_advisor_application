import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          title: const Text('Privacy Policy'),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
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
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your privacy is important to us',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : Colors.blue.shade100,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: January 1, 2024',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.blue.shade100),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 800),
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
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('1. Information We Collect', isDark),
                          _buildSubTitle('Personal Information', isDark),
                          _buildParagraph(
                            'When you create an account or use our services, we may collect:',
                            isDark,
                          ),
                          _buildBulletList([
                            'Name and email address',
                            'Professional information from your resume',
                            'Skills assessment results',
                            'Career preferences and goals',
                            'Usage data and analytics',
                          ], isDark),
                          _buildSubTitle('Resume Data', isDark),
                          _buildParagraph(
                            'When you upload your resume, we extract and analyze information including work experience, education, skills, and achievements. This data is used solely to provide you with personalized career recommendations.',
                            isDark,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('2. How We Use Your Information', isDark),
                          _buildParagraph('We use your information to:', isDark),
                          _buildBulletList([
                            'Provide AI-powered career analysis and recommendations',
                            'Personalize your experience on our platform',
                            'Improve our AI algorithms and services',
                            'Send you relevant updates and career insights',
                            'Provide customer support',
                            'Ensure platform security and prevent fraud',
                          ], isDark),

                          const SizedBox(height: 24),
                          _buildSectionTitle('3. Data Security', isDark),
                          _buildParagraph(
                            'We implement industry-standard security measures to protect your data:',
                            isDark,
                          ),
                          _buildBulletList([
                            'All data is encrypted in transit and at rest',
                            'Secure servers with regular security updates',
                            'Access controls and authentication protocols',
                            'Regular security audits and monitoring',
                            'Compliance with data protection regulations',
                          ], isDark),

                          const SizedBox(height: 24),
                          _buildSectionTitle('4. Data Sharing', isDark),
                          _buildParagraph(
                            'We do not sell, trade, or otherwise transfer your personal information to third parties except:',
                            isDark,
                          ),
                          _buildBulletList([
                            'With your explicit consent',
                            'To comply with legal obligations',
                            'To protect our rights and safety',
                            'With trusted service providers who help us operate our platform',
                          ], isDark),

                          const SizedBox(height: 24),
                          _buildSectionTitle('5. Your Rights', isDark),
                          _buildParagraph('You have the right to:', isDark),
                          _buildBulletList([
                            'Access your personal data',
                            'Correct inaccurate information',
                            'Request deletion of your data',
                            'Opt out of marketing communications',
                            'Data portability',
                            'Withdraw consent at any time',
                          ], isDark),

                          const SizedBox(height: 24),
                          _buildSectionTitle('6. Cookies and Tracking', isDark),
                          _buildParagraph(
                            'We use cookies and similar technologies to:',
                            isDark,
                          ),
                          _buildBulletList([
                            'Remember your preferences',
                            'Analyze site usage and performance',
                            'Provide personalized content',
                            'Improve user experience',
                          ], isDark),
                          _buildParagraph(
                            'You can control cookie settings through your browser preferences.',
                            isDark,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('7. Data Retention', isDark),
                          _buildParagraph(
                            'We retain your data only as long as necessary to provide our services and comply with legal obligations. You can request deletion of your account and associated data at any time through your account settings.',
                            isDark,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('8. Children\'s Privacy', isDark),
                          _buildParagraph(
                            'Our services are not intended for users under 16 years of age. We do not knowingly collect personal information from children under 16.',
                            isDark,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('9. International Data Transfers', isDark),
                          _buildParagraph(
                            'Your data may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your data during such transfers.',
                            isDark,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('10. Changes to This Policy', isDark),
                          _buildParagraph(
                            'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date.',
                            isDark,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle('11. Contact Us', isDark),
                          _buildParagraph(
                            'If you have any questions about this Privacy Policy, please contact us:',
                            isDark,
                          ),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildContactItem(
                                  'Email',
                                  'privacy@careerpathai.com',
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildContactItem(
                                  'Address',
                                  '123 AI Street, Tech City, TC 12345',
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildContactItem('Phone', '+1 (555) 123-4567', isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Quick Actions
                    Container(
                      constraints: const BoxConstraints(maxWidth: 800),
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
                          Text(
                            'Need to manage your data?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              ElevatedButton(
                                onPressed: () => context.go('/dashboard'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.userPrimaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Access Your Data'),
                              ),
                              ElevatedButton(
                                onPressed: () => context.push('/contact'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                                  foregroundColor: isDark ? Colors.white : Colors.grey.shade800,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Contact Support'),
                              ),
                            ],
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

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSubTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: isDark ? Colors.white60 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 12.0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white38 : Colors.grey.shade700,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDark ? Colors.white60 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactItem(String label, String value, bool isDark) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: isDark ? Colors.white60 : Colors.grey.shade700,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
