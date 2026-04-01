import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate form submission
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();
      });

      // Hide success message after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showSuccess = false;
          });
        }
      });
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
          title: const Text('Contact Us'),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Have questions about our AI-powered career guidance? We\'d love to hear from you. Send us a message and we\'ll respond as soon as possible.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contact Form
                        Expanded(
                          flex: isWide ? 3 : 0,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.3 : 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send us a message',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                if (_showSuccess)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 24),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.green.shade50,
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.green.shade200,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: isDark
                                              ? Colors.green.shade400
                                              : Colors.green.shade600,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Thank you for your message! We\'ll get back to you soon.',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.green.shade400
                                                  : Colors.green.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : null,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Full Name *',
                                          hintText: 'Enter your full name',
                                          fillColor: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white,
                                          labelStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : null,
                                          ),
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white38
                                                : null,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Name is required';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _emailController,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : null,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Email Address *',
                                          hintText: 'Enter your email address',
                                          fillColor: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white,
                                          labelStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : null,
                                          ),
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white38
                                                : null,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Email is required';
                                          }
                                          if (!RegExp(
                                            r'\S+@\S+\.\S+',
                                          ).hasMatch(value)) {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _subjectController,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : null,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Subject *',
                                          hintText: 'What\'s this about?',
                                          fillColor: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white,
                                          labelStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : null,
                                          ),
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white38
                                                : null,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Subject is required';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _messageController,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : null,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Message *',
                                          hintText:
                                              'Tell us more about your inquiry...',
                                          alignLabelWithHint: true,
                                          fillColor: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white,
                                          labelStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : null,
                                          ),
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white38
                                                : null,
                                          ),
                                        ),
                                        maxLines: 6,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Message is required';
                                          }
                                          if (value.length < 10) {
                                            return 'Message must be at least 10 characters long';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _handleSubmit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.userPrimaryBlue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: _isSubmitting
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Text(
                                                  'Send Message',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (isWide)
                          const SizedBox(width: 32)
                        else
                          const SizedBox(height: 32),

                        // Contact Info & FAQs
                        Expanded(
                          flex: isWide ? 2 : 0,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        isDark ? 0.3 : 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Get in touch',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildContactInfo(
                                      icon: Icons.email_outlined,
                                      color: Colors.blue,
                                      title: 'Email',
                                      content: 'support@careerpathai.com',
                                      subtitle:
                                          'We typically respond within 24 hours',
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildContactInfo(
                                      icon: Icons.phone_outlined,
                                      color: Colors.green,
                                      title: 'Phone',
                                      content: '+1 (555) 123-4567',
                                      subtitle: 'Mon-Fri 9AM-6PM EST',
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildContactInfo(
                                      icon: Icons.location_on_outlined,
                                      color: Colors.purple,
                                      title: 'Address',
                                      content:
                                          '123 Tech Street\nSan Francisco, CA 94105',
                                      subtitle: 'Visit us by appointment',
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        isDark ? 0.3 : 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Frequently Asked Questions',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSmallFaq(
                                      'How accurate is the AI analysis?',
                                      'Our AI uses advanced machine learning algorithms trained on thousands of career profiles to provide highly accurate insights.',
                                      isDark,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSmallFaq(
                                      'Is my data secure?',
                                      'Yes, we use enterprise-grade security measures to protect your personal information and career data.',
                                      isDark,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSmallFaq(
                                      'Can I get personalized coaching?',
                                      'We offer both AI-powered guidance and optional human coaching services for personalized career development.',
                                      isDark,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallFaq(String question, String answer, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
