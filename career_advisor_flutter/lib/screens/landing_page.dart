import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../widgets/animated_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool isMobileMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    return AnimatedScreen(
      child: Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24), // Added upper padding
                  Container(
                    color: AppTheme.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppTheme.userPrimaryBlue,
                                          AppTheme.userPrimaryPurple,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.psychology,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ShaderMask(
                                    shaderCallback: (rect) =>
                                        const LinearGradient(
                                          colors: [
                                            AppTheme.userPrimaryBlue,
                                            AppTheme.userPrimaryPurple,
                                          ],
                                        ).createShader(rect),
                                    child: const Text(
                                      'CareerPath AI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isDesktop)
                                Row(
                                  children: [
                                    _NavLink('Home', () {}),
                                    _NavLink('Resume Analyzer', () {
                                      context.push('/login');
                                    }),
                                    _NavLink('Career Paths', () {
                                      context.push('/login');
                                    }),
                                    _NavLink('Skills Assessment', () {
                                      context.push('/login');
                                    }),
                                    _NavLink('Dashboard', () {
                                      context.push('/dashboard');
                                    }),
                                  ],
                                ),
                              if (isDesktop)
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        context.push('/login');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppTheme.userPrimaryBlue,
                                        side: const BorderSide(
                                          color: AppTheme.userPrimaryBlue,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text('Sign In'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.push('/register');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.userPrimaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        elevation: 2,
                                      ),
                                      child: const Text('Sign Up'),
                                    ),
                                  ],
                                ),
                              if (!isDesktop)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isMobileMenuOpen = !isMobileMenuOpen;
                                    });
                                  },
                                  icon: Icon(
                                    isMobileMenuOpen ? Icons.close : Icons.menu,
                                    color: AppTheme.gray700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isDesktop && isMobileMenuOpen)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                _MobileLink('Home', () {}),
                                _MobileLink('Resume Analyzer', () {
                                  context.push('/login');
                                }),
                                _MobileLink('Career Paths', () {
                                  context.push('/login');
                                }),
                                _MobileLink('Skills Assessment', () {
                                  context.push('/login');
                                }),
                                _MobileLink('Dashboard', () {
                                  context.push('/dashboard');
                                }),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            context.push('/login');
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.userPrimaryBlue,
                                            side: const BorderSide(
                                              color: AppTheme.userPrimaryBlue,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text('Sign In'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            context.push('/register');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.userPrimaryBlue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text('Sign Up'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 40 : 28,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const NetworkImage(
                          'https://readdy.ai/api/search-image?query=Professional%20business%20people%20working%20with%20AI%20technology%2C%20modern%20office%20environment%20with%20digital%20interfaces%2C%20career%20development%20and%20growth%2C%20bright%20and%20clean%20background%20with%20soft%20lighting%2C%20professional%20atmosphere%20with%20technology%20elements%2C%20minimalist%20design&width=1920&height=800&seq=hero-career-ai&orientation=landscape',
                        ),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.white.withValues(alpha: 0.6),
                          BlendMode.srcOver,
                        ),
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Discover Your Perfect ',
                                    style: TextStyle(
                                      color: AppTheme.gray700,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Career Path',
                                    style:
                                        const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ).copyWith(
                                          foreground: Paint()
                                            ..shader =
                                                const LinearGradient(
                                                  colors: [
                                                    AppTheme.userPrimaryBlue,
                                                    AppTheme.userPrimaryPurple,
                                                  ],
                                                ).createShader(
                                                  const Rect.fromLTWH(
                                                    0,
                                                    0,
                                                    200,
                                                    50,
                                                  ),
                                                ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Leverage AI-powered resume analysis and skill assessment to find your ideal career trajectory. Get personalized recommendations based on your unique profile.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.gray600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    context.push('/login');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.userPrimaryBlue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text('Analyze My Resume'),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    context.push('/login');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppTheme.userPrimaryBlue,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    'Take Skills Test',
                                    style: TextStyle(
                                      color: AppTheme.userPrimaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                Text(
                                  'Powerful AI-Driven Features',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Our advanced AI analyzes your skills, experience, and career goals to provide personalized guidance',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.gray600),
                                ),
                              ],
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth >= 1024
                                  ? 3
                                  : (constraints.maxWidth >= 640 ? 2 : 1);
                              return GridView.count(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: const [
                                  _FeatureCard(
                                    bgStart: Color(0xFFEFF6FF),
                                    bgEnd: Color(0xFFDBEAFE),
                                    icon: Icons.file_present,
                                    title: 'Resume Analysis',
                                    text:
                                        'Upload your resume and get detailed insights about your skills, experience level, and career positioning',
                                  ),
                                  _FeatureCard(
                                    bgStart: Color(0xFFF5F3FF),
                                    bgEnd: Color(0xFFE9D5FF),
                                    icon: Icons.explore,
                                    title: 'Career Pathways',
                                    text:
                                        'Discover multiple career paths based on your skills and interests with detailed roadmaps and requirements',
                                  ),
                                  _FeatureCard(
                                    bgStart: Color(0xFFECFDF5),
                                    bgEnd: Color(0xFFD1FAE5),
                                    icon: Icons.bar_chart,
                                    title: 'Skills Assessment',
                                    text:
                                        'Take comprehensive skills tests to identify your strengths and areas for improvement',
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: const Color(0xFFF3F4F6),
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                Text(
                                  'How It Works',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Simple steps to discover your ideal career path',
                                  style: TextStyle(color: AppTheme.gray600),
                                ),
                              ],
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth >= 1024
                                  ? 4
                                  : (constraints.maxWidth >= 640 ? 2 : 2);
                              return GridView.count(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: const [
                                  _StepCard(
                                    number: '1',
                                    title: 'Upload Resume',
                                    text: 'Upload your resume for AI analysis',
                                    color: AppTheme.userPrimaryBlue,
                                  ),
                                  _StepCard(
                                    number: '2',
                                    title: 'Skills Assessment',
                                    text: 'Take our comprehensive skills test',
                                    color: AppTheme.userPrimaryPurple,
                                  ),
                                  _StepCard(
                                    number: '3',
                                    title: 'AI Analysis',
                                    text:
                                        'Get personalized career recommendations',
                                    color: Color(0xFF16A34A),
                                  ),
                                  _StepCard(
                                    number: '4',
                                    title: 'Career Roadmap',
                                    text:
                                        'Follow your personalized career path',
                                    color: Color(0xFFEA580C),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 1024
                              ? 4
                              : 2;
                          return GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: const [
                              _StatCard(
                                value: '50K+',
                                label: 'Resumes Analyzed',
                                color: AppTheme.userPrimaryBlue,
                              ),
                              _StatCard(
                                value: '95%',
                                label: 'Success Rate',
                                color: AppTheme.userPrimaryPurple,
                              ),
                              _StatCard(
                                value: '200+',
                                label: 'Career Paths',
                                color: Color(0xFF16A34A),
                              ),
                              _StatCard(
                                value: '24/7',
                                label: 'AI Support',
                                color: Color(0xFFEA580C),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.userPrimaryBlue,
                          AppTheme.userPrimaryPurple,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          const Text(
                            'Ready to Transform Your Career?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Join thousands of professionals who have discovered their ideal career path with our AI-powered platform',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFDBEAFE)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.push('/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Start Your Journey Today',
                              style: TextStyle(color: AppTheme.userPrimaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: AppTheme.gray900,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth >= 1024 ? 4 : 2;
                              return GridView.count(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  AppTheme.userPrimaryBlue,
                                                  AppTheme.userPrimaryPurple,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.psychology,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'CareerPath AI',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Empowering careers through AI-driven insights and personalized guidance',
                                        style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const _FooterSection(
                                    title: 'Features',
                                    items: {
                                      'Resume Analysis': '/analyze',
                                      'Skills Assessment': '/skills',
                                      'Career Paths': '/career-paths',
                                      'Dashboard': '/dashboard',
                                    },
                                  ),
                                  const _FooterSection(
                                    title: 'Support',
                                    items: {
                                      'Help Center': '/help-center',
                                      'Contact Us': '/contact',
                                      'Privacy Policy': '/privacy-policy',
                                      'Terms of Service': '/terms-of-service',
                                    },
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Connect',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: const [
                                          _SocialButton(
                                            icon: Icons.alternate_email,
                                          ),
                                          SizedBox(width: 8),
                                          _SocialButton(icon: Icons.work),
                                          SizedBox(width: 8),
                                          _SocialButton(icon: Icons.facebook),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const Divider(color: Color(0xFF1F2937)),
                          const SizedBox(height: 8),
                          const Text(
                            '© 2026 CareerPath AI. All rights reserved.',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: const TextStyle(color: AppTheme.gray700)),
      ),
    );
  }
}

class _MobileLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MobileLink(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppTheme.gray700)),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final Color bgStart;
  final Color bgEnd;
  final IconData icon;
  final String title;
  final String text;
  const _FeatureCard({
    required this.bgStart,
    required this.bgEnd,
    required this.icon,
    required this.title,
    required this.text,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgStart, bgEnd],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, color: AppTheme.userPrimaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.gray900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: AppTheme.gray600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String text;
  final Color color;
  const _StepCard({
    required this.number,
    required this.title,
    required this.text,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(color: AppTheme.gray600, fontSize: 12),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppTheme.gray600)),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final String route;
  const _FooterLink({required this.text, required this.route});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (route.isNotEmpty) {
          context.push(route);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  const _SocialButton({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF9CA3AF)),
    );
  }
}

class _FooterSection extends StatelessWidget {
  final String title;
  final Map<String, String> items;
  const _FooterSection({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in items.entries)
          _FooterLink(text: entry.key, route: entry.value),
      ],
    );
  }
}
