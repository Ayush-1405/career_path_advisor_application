import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_screen.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedScreen(
      child: Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.purple.shade600],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
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
                    style: TextStyle(fontSize: 18, color: Colors.blue.shade100),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: January 1, 2024',
                    style: TextStyle(color: Colors.blue.shade100),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('1. Information We Collect'),
                        _buildSubTitle('Personal Information'),
                        _buildParagraph(
                          'When you create an account or use our services, we may collect:',
                        ),
                        _buildBulletList([
                          'Name and email address',
                          'Professional information from your resume',
                          'Skills assessment results',
                          'Career preferences and goals',
                          'Usage data and analytics',
                        ]),
                        _buildSubTitle('Resume Data'),
                        _buildParagraph(
                          'When you upload your resume, we extract and analyze information including work experience, education, skills, and achievements. This data is used solely to provide you with personalized career recommendations.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('2. How We Use Your Information'),
                        _buildParagraph('We use your information to:'),
                        _buildBulletList([
                          'Provide AI-powered career analysis and recommendations',
                          'Personalize your experience on our platform',
                          'Improve our AI algorithms and services',
                          'Send you relevant updates and career insights',
                          'Provide customer support',
                          'Ensure platform security and prevent fraud',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('3. Data Security'),
                        _buildParagraph(
                          'We implement industry-standard security measures to protect your data:',
                        ),
                        _buildBulletList([
                          'All data is encrypted in transit and at rest',
                          'Secure servers with regular security updates',
                          'Access controls and authentication protocols',
                          'Regular security audits and monitoring',
                          'Compliance with data protection regulations',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('4. Data Sharing'),
                        _buildParagraph(
                          'We do not sell, trade, or otherwise transfer your personal information to third parties except:',
                        ),
                        _buildBulletList([
                          'With your explicit consent',
                          'To comply with legal obligations',
                          'To protect our rights and safety',
                          'With trusted service providers who help us operate our platform',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('5. Your Rights'),
                        _buildParagraph('You have the right to:'),
                        _buildBulletList([
                          'Access your personal data',
                          'Correct inaccurate information',
                          'Request deletion of your data',
                          'Opt out of marketing communications',
                          'Data portability',
                          'Withdraw consent at any time',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('6. Cookies and Tracking'),
                        _buildParagraph(
                          'We use cookies and similar technologies to:',
                        ),
                        _buildBulletList([
                          'Remember your preferences',
                          'Analyze site usage and performance',
                          'Provide personalized content',
                          'Improve user experience',
                        ]),
                        _buildParagraph(
                          'You can control cookie settings through your browser preferences.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('7. Data Retention'),
                        _buildParagraph(
                          'We retain your data only as long as necessary to provide our services and comply with legal obligations. You can request deletion of your account and associated data at any time through your account settings.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('8. Children\'s Privacy'),
                        _buildParagraph(
                          'Our services are not intended for users under 16 years of age. We do not knowingly collect personal information from children under 16.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('9. International Data Transfers'),
                        _buildParagraph(
                          'Your data may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your data during such transfers.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('10. Changes to This Policy'),
                        _buildParagraph(
                          'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('11. Contact Us'),
                        _buildParagraph(
                          'If you have any questions about this Privacy Policy, please contact us:',
                        ),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildContactItem(
                                'Email',
                                'privacy@careerpathai.com',
                              ),
                              const SizedBox(height: 8),
                              _buildContactItem(
                                'Address',
                                '123 AI Street, Tech City, TC 12345',
                              ),
                              const SizedBox(height: 8),
                              _buildContactItem('Phone', '+1 (555) 123-4567'),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                      children: [
                        const Text(
                          'Need to manage your data?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                                backgroundColor: Colors.blue.shade600,
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
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.grey.shade800,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
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
                      color: Colors.grey.shade700,
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
                      color: Colors.grey.shade700,
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

  Widget _buildContactItem(String label, String value) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.grey.shade700,
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
