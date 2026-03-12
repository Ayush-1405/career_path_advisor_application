import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_screen.dart';

class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedScreen(
      child: Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
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
                    'Terms of Service',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please read these terms carefully before using our services',
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
                        _buildSectionTitle('1. Acceptance of Terms'),
                        _buildParagraph(
                          'By accessing and using CareerPath AI ("the Service"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('2. Service Description'),
                        _buildParagraph(
                          'CareerPath AI provides AI-powered career analysis and recommendations through:',
                        ),
                        _buildBulletList([
                          'Resume analysis and skill extraction',
                          'Career path recommendations',
                          'Skills assessment tools',
                          'Personalized career guidance',
                          'AI-powered career assistant',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('3. User Accounts'),
                        _buildSubTitle('Account Creation'),
                        _buildParagraph(
                          'To use our services, you must create an account and provide accurate information. You are responsible for:',
                        ),
                        _buildBulletList([
                          'Maintaining the confidentiality of your account credentials',
                          'All activities that occur under your account',
                          'Notifying us immediately of any unauthorized use',
                          'Providing accurate and up-to-date information',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('4. Acceptable Use'),
                        _buildParagraph(
                          'You agree to use the Service only for lawful purposes and in accordance with these Terms. You agree not to:',
                        ),
                        _buildBulletList([
                          'Upload false, misleading, or fraudulent information',
                          'Attempt to gain unauthorized access to our systems',
                          'Use the Service for any illegal or unauthorized purpose',
                          'Interfere with or disrupt the Service or servers',
                          'Reverse engineer or attempt to extract source code',
                          'Upload malicious software or harmful content',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('5. AI and Recommendations'),
                        _buildSubTitle('AI Analysis'),
                        _buildParagraph(
                          'Our AI provides career recommendations based on your resume and assessment data. Please note:',
                        ),
                        _buildBulletList([
                          'Recommendations are suggestions, not guarantees',
                          'Results may vary based on individual circumstances',
                          'We continuously improve our AI but cannot guarantee 100% accuracy',
                          'Final career decisions remain your responsibility',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('6. Data and Privacy'),
                        _buildParagraph(
                          'Your privacy is important to us. By using our Service, you agree to:',
                        ),
                        _buildBulletList([
                          'Our collection and use of your data as described in our Privacy Policy',
                          'Provide accurate information in your resume and assessments',
                          'Our use of anonymized data to improve our AI services',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('7. Intellectual Property'),
                        _buildSubTitle('Our Content'),
                        _buildParagraph(
                          'The Service and its original content, features, and functionality are and will remain the exclusive property of CareerPath AI and its licensors.',
                        ),
                        _buildSubTitle('Your Content'),
                        _buildParagraph(
                          'You retain ownership of your uploaded content (resumes, assessments) but grant us a license to use, process, and analyze this content to provide our services.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('8. Subscription and Payments'),
                        _buildParagraph(
                          'Our Service may offer both free and paid features:',
                        ),
                        _buildBulletList([
                          'Free tier includes basic resume analysis and career recommendations',
                          'Premium features may require subscription',
                          'Payments are processed securely through third-party providers',
                          'Subscription terms and pricing are clearly displayed',
                          'Cancellation policies apply as described in your subscription',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('9. Limitation of Liability'),
                        _buildParagraph(
                          'In no event shall CareerPath AI be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your use of the Service.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('10. Disclaimers'),
                        _buildParagraph(
                          'The Service is provided on an "AS IS" and "AS AVAILABLE" basis. We make no warranties, expressed or implied, including:',
                        ),
                        _buildBulletList([
                          'Accuracy of AI recommendations',
                          'Uninterrupted service availability',
                          'Compatibility with all devices or software',
                          'Achievement of specific career outcomes',
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionTitle('11. Termination'),
                        _buildParagraph(
                          'We may terminate or suspend your account and access to the Service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('12. Changes to Terms'),
                        _buildParagraph(
                          'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days notice prior to any new terms taking effect.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('13. Governing Law'),
                        _buildParagraph(
                          'These Terms shall be interpreted and governed by the laws of the jurisdiction in which our company is incorporated, without regard to its conflict of law provisions.',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('14. Contact Information'),
                        _buildParagraph(
                          'If you have any questions about these Terms of Service, please contact us:',
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
                                'legal@careerpathai.com',
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
                          'Ready to get started?',
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
                              onPressed: () => context.push('/register'),
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
                              child: const Text('Create Account'),
                            ),
                            ElevatedButton(
                              onPressed: () => context.push('/privacy-policy'),
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
                              child: const Text('Privacy Policy'),
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
                              child: const Text('Contact Us'),
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
