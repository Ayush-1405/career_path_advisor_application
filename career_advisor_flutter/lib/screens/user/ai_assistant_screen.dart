import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import '../../services/api_service.dart';
import '../../services/token_service.dart';
import '../../services/wit_ai_service.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'id': 1,
      'type': 'ai',
      'content':
          "Hello! I'm your AI Career Assistant. I can help you with career advice, skill development, job search strategies, and more. What would you like to know?",
      'timestamp': DateTime.now(),
    },
  ];
  bool _isTyping = false;
  Map<String, dynamic>? _user;

  final List<String> _quickQuestions = [
    "How can I improve my resume?",
    "What should I ask in an interview?",
    "How do I negotiate salary?",
    "What skills should I learn?",
    "How do I change careers?",
    "Tips for networking?",
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await ref.read(tokenServiceProvider.notifier).getUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? message]) async {
    final text = message ?? _inputController.text.trim();
    if (text.isEmpty) return;

    if (message == null) {
      _inputController.clear();
    }

    final userMessage = {
      'id': _messages.length + 1,
      'type': 'user',
      'content': text,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Get Wit.ai analysis concurrently for NLP enhancement
      final witAnalysis = await ref
          .read(witAiServiceProvider)
          .getMessageAnalysis(text);
      debugPrint('Wit.ai analysis: $witAnalysis');

      final response = await ref
          .read(apiServiceProvider)
          .chatWithAssistant(text);
      final replyText = response['reply'] ?? response['message'] ?? '...';

      final aiMessage = {
        'id': _messages.length + 2,
        'type': 'ai',
        'content': replyText,
        'timestamp': DateTime.now(),
      };

      if (mounted) {
        setState(() {
          _messages.add(aiMessage);
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      final errorMessage = {
        'id': _messages.length + 2,
        'type': 'ai',
        'content':
            'Sorry, I could not process that right now. Please try again later.',
        'timestamp': DateTime.now(),
      };

      if (mounted) {
        setState(() {
          _messages.add(errorMessage);
          _isTyping = false;
        });
        _scrollToBottom();
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
                context.go('/feed');
              }
            },
          ),
          title: const Text('AI Career Assistant'),
          elevation: 0,
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
        ),
        body: Column(
          children: [
            // Intro Header
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Column(
                children: [
                  Text(
                    'Get instant career advice, tips, and guidance from our AI-powered assistant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),

            // Chat Area
            Expanded(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
            ),

            // Quick Questions & Input Area
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Questions
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickQuestions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ActionChip(
                          label: Text(_quickQuestions[index]),
                          onPressed: () => _sendMessage(_quickQuestions[index]),
                          backgroundColor: isDark
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.blue.shade50,
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.blueAccent
                                : AppTheme.primaryColor,
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                            ),
                            fillColor: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.grey.shade50,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Remix.send_plane_fill,
                            color: Colors.white,
                          ),
                          onPressed: () => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['type'] == 'user';
    final isAi = message['type'] == 'ai';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Remix.robot_line,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryColor
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: isUser
                    ? []
                    : [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAi) ...[
                    Text(
                      'AI Assistant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.blueAccent
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message['content'] as String,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? Colors.white : AppTheme.gray900),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.blue.shade100,
              child: Text(
                (_user?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.blueAccent : AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Remix.robot_line, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.gray400.withAlpha((127 + (value * 127)).round()),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {},
    );
  }
}
