import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/theme.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_service.dart';

import '../../providers/app_auth_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  PlatformFile? _attachedFile;
  Timer? _pollingTimer;
  Timer? _pingTimer;
  bool _isSending = false;
  bool _isMuted = false;

  bool _isImage(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  Widget _buildFileBox(String fileName, String fileUrl, bool isMe, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMe ? Colors.white38 : (isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black54), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName,
              style: TextStyle(
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(String content, bool isMe, bool isDark) {
    if (content.contains('[FILE|')) {
      final RegExp fileRegExp = RegExp(r'\[FILE\|(.*?)\]\((.*?)\)');
      final fileMatch = fileRegExp.firstMatch(content);
      if (fileMatch != null) {
        final fileName = fileMatch.group(1)!;
        final fileUrl = fileMatch.group(2)!;
        final textContent = content.substring(0, fileMatch.start).trim() + (content.substring(fileMatch.end).trim().isEmpty ? '' : '\n' + content.substring(fileMatch.end).trim());
        
        final isImage = _isImage(fileName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (textContent.trim().isNotEmpty)
              Text(
                textContent.trim(),
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  fontSize: 15,
                ),
              ),
            if (textContent.trim().isNotEmpty) const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: fileUrl,
                        width: 250,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) => _buildFileBox(fileName, fileUrl, isMe, isDark),
                      ),
                    )
                  : _buildFileBox(fileName, fileUrl, isMe, isDark),
            ),
          ],
        );
      }
    }
    
    return Text(
      content,
      style: TextStyle(
        color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
        fontSize: 15,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Poll every 15 seconds for new messages
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.read(chatMessagesProvider(widget.roomId).notifier).fetchMessages(background: true);
    });
    
    // Ping online status every 30 seconds
    Future.microtask(() => ref.read(apiServiceProvider).pingUserActivity());
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(apiServiceProvider).pingUserActivity();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pingTimer?.cancel();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if ((text.isEmpty && _attachedFile == null) || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      String finalMessage = text;
      
      if (_attachedFile != null) {
          final url = await ref.read(apiServiceProvider).uploadChatFile(
              filePath: kIsWeb ? null : _attachedFile!.path,
              bytes: _attachedFile!.bytes,
              filename: _attachedFile!.name,
          );
          if (url != null) {
              finalMessage = finalMessage.isEmpty ? '[FILE|${_attachedFile!.name}]($url)' : '$finalMessage\n[FILE|${_attachedFile!.name}]($url)';
          } else {
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload attachment.')));
              }
              if (finalMessage.isEmpty) return; // if file upload failed and no text, do not send
          }
      }

      await ref
          .read(chatMessagesProvider(widget.roomId).notifier)
          .sendMessage(widget.otherUserId, finalMessage);
      _msgController.clear();
      _attachedFile = null;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messagesState = ref.watch(chatMessagesProvider(widget.roomId));
    final currentUserState = ref.watch(currentUserProvider);
    final currentUserId = currentUserState.value?.id;

    // LinkedIn branding colors
    final meBubbleColor = isDark ? const Color(0xFF0A66C2) : const Color(0xFF0A66C2);
    final themBubbleColor = isDark ? const Color(0xFF333333) : const Color(0xFFF3F2EF);
    final isOnline = ref.watch(onlineStatusProvider(widget.otherUserId)).value ?? false;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark
                      ? AppTheme.userPrimaryBlue.withAlpha(51)
                      : AppTheme.userPrimaryBlue.withAlpha(26),
                  backgroundImage: widget.otherUserAvatar != null
                      ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                      : null,
                  child: widget.otherUserAvatar == null
                      ? Text(
                          widget.otherUserName.isNotEmpty
                              ? widget.otherUserName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.userPrimaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.gray900,
                    ),
                  ),
                  Text(
                    'LinkedIn Member', // Mock role for LinkedIn feel
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white70 : AppTheme.gray600,
            ),
            onSelected: (value) async {
              // Capture necessary objects before any async gaps
              final router = GoRouter.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              switch (value) {
                case 'profile':
                  String? targetUserId = widget.otherUserId;
                  
                  // Fallback: Try to find user ID from myChatsProvider if it's missing in widget
                  if (targetUserId.isEmpty) {
                    final chats = ref.read(myChatsProvider).valueOrNull;
                    final chat = chats?.where((c) => c.chatRoomId == widget.roomId).firstOrNull;
                    if (chat != null) {
                      targetUserId = chat.otherUserId;
                    }
                  }

                  if (targetUserId.isNotEmpty) {
                    debugPrint('Navigating to profile for user: $targetUserId');
                    router.push('/profile/member/$targetUserId');
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Could not identify user profile')),
                    );
                  }
                  break;
                case 'mute':
                  setState(() {
                    _isMuted = !_isMuted;
                  });
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(_isMuted ? 'Notifications muted for this chat' : 'Notifications unmuted'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  break;
                case 'clear':
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear messages?'),
                      content: const Text('This will delete all messages in this conversation. This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref.read(chatMessagesProvider(widget.roomId).notifier).clearMessages();
                      messenger.showSnackBar(const SnackBar(content: Text('Messages cleared')));
                      // Also refresh the chat list in background to update the snippet
                      ref.read(myChatsProvider.notifier).fetchChats(background: true);
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed to clear: $e')));
                    }
                  }
                  break;
                case 'delete':
                   final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete conversation?'),
                      content: const Text('This will delete the entire conversation and remove it from your list. This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref.read(myChatsProvider.notifier).deleteChat(widget.roomId);
                      router.pop(); // Go back to chat list
                      messenger.showSnackBar(const SnackBar(content: Text('Conversation deleted')));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('View Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(
                      _isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(_isMuted ? 'Unmute notifications' : 'Mute notifications'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Clear messages', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete conversation', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        foregroundColor: isDark ? Colors.white : AppTheme.gray900,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B).withOpacity(0.95) : Colors.white.withOpacity(0.95),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                          backgroundImage: widget.otherUserAvatar != null
                              ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.otherUserName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say hi to ${widget.otherUserName}!',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true, // Show newest at the bottom naturally if we reverse the list view
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) {
                    // Because list is reversed, index 0 is at bottom.
                    final msg = messages[messages.length - 1 - index];
                    final bool isMe = msg.senderId == currentUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe)
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.transparent,
                              backgroundImage: widget.otherUserAvatar != null
                                  ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                                  : null,
                              child: widget.otherUserAvatar == null
                                  ? Icon(Icons.person, size: 16, color: Colors.grey.shade400)
                                  : null,
                            ),
                          if (!isMe) const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isMe
                                        ? const LinearGradient(
                                            colors: [Color(0xFF0A66C2), Color(0xFF0284C7)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isMe ? null : themBubbleColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isMe ? const Color(0xFF0A66C2) : Colors.black).withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 20),
                                    ),
                                  ),
                                  child: _buildMessageContent(msg.content, isMe, isDark),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : const Color(0xFF666666),
                                      ),
                                    ),
                                    if (isMe && index == 0 && msg.isRead)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          '• Seen',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white38 : const Color(0xFF666666),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) =>
                  Center(child: Text('Error loading messages: $err')),
            ),
          ),

          // Premium Chat Input Area
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 24),
                    color: isDark ? Colors.white70 : const Color(0xFF666666),
                    onPressed: _pickFile,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_attachedFile != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _isImage(_attachedFile!.name) && _attachedFile!.bytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _attachedFile!.bytes!,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.attach_file, size: 16),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(_attachedFile!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                    ),
                              Positioned(
                                right: -8,
                                top: -8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _attachedFile = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F2EF),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.transparent,
                          ),
                        ),
                        child: TextField(
                          controller: _msgController,
                          maxLines: 4,
                          minLines: 1,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 15,
                          ),
                          onChanged: (val) {
                            setState((){});
                          },
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : const Color(0xFF888888),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Container(
                          key: ValueKey(_msgController.text.trim().isNotEmpty || _attachedFile != null),
                          decoration: BoxDecoration(
                            color: (_msgController.text.trim().isNotEmpty || _attachedFile != null)
                                ? const Color(0xFF0A66C2)
                                : (isDark ? Colors.white10 : Colors.grey.shade200),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, size: 20),
                            color: (_msgController.text.trim().isNotEmpty || _attachedFile != null)
                                ? Colors.white
                                : (isDark ? Colors.white38 : Colors.grey.shade400),
                            onPressed: _sendMessage,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
