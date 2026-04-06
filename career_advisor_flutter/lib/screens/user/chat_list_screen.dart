import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import '../../providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatsState = ref.watch(myChatsProvider);

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F2EF),
        appBar: AppBar(
          title: const Text(
            'Messaging',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              color: isDark ? Colors.white70 : AppTheme.gray600,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Manage conversations'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showManageChatsSheet(context, isDark);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.mark_chat_read_outlined),
                        title: const Text('Mark all as read'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await ref.read(myChatsProvider.notifier).markAllAsRead();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All messages marked as read')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to update messages')),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_square),
              color: isDark ? Colors.white70 : AppTheme.gray600,
              onPressed: () => context.push('/network'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF3F8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search messages',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : const Color(0xFF666666),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: isDark ? Colors.white38 : const Color(0xFF666666),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 0.5),
            Expanded(
              child: chatsState.when(
                data: (allChats) {
                  final chats = allChats.where((chat) {
                    return chat.otherUserName.toLowerCase().contains(_searchQuery) ||
                        (chat.lastMessage?.toLowerCase().contains(_searchQuery) ?? false);
                  }).toList();

                  if (chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.gray400),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty ? 'No messages found.' : 'No messages yet.',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : AppTheme.gray500,
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => context.push('/network'),
                              icon: const Icon(Icons.people_outline),
                              label: const Text('Find connections to message'),
                            ),
                          ]
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.read(myChatsProvider.notifier).fetchChats(),
                    child: ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final hasUnread = chat.unreadCount > 0;

                        return Dismissible(
                          key: Key(chat.chatRoomId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Colors.red,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, color: Colors.white, size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete conversation?'),
                                content: Text(
                                  'This will permanently delete your conversation with ${chat.otherUserName}.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            try {
                              await ref.read(myChatsProvider.notifier).deleteChat(chat.chatRoomId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Conversation with ${chat.otherUserName} deleted'),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to delete conversation')),
                                );
                                // Refresh to restore the item
                                ref.read(myChatsProvider.notifier).fetchChats(background: true);
                              }
                            }
                          },
                          child: InkWell(
                            onTap: () {
                              context.push(
                                '/chat/${chat.chatRoomId}',
                                extra: {
                                  'userId': chat.otherUserId,
                                  'userName': chat.otherUserName,
                                  'userAvatar': chat.otherUserAvatar,
                                },
                              );
                            },
                            child: Container(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: isDark
                                            ? AppTheme.userPrimaryBlue.withAlpha(51)
                                            : AppTheme.userPrimaryBlue.withAlpha(26),
                                        backgroundImage: chat.otherUserAvatar != null &&
                                                chat.otherUserAvatar!.isNotEmpty
                                            ? CachedNetworkImageProvider(chat.otherUserAvatar!)
                                            : null,
                                        child: chat.otherUserAvatar == null ||
                                                chat.otherUserAvatar!.isEmpty
                                            ? Text(
                                                chat.otherUserName.isNotEmpty
                                                    ? chat.otherUserName[0].toUpperCase()
                                                    : 'U',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : AppTheme.userPrimaryBlue,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: index % 3 == 0 ? Colors.green : Colors.transparent,
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chat.otherUserName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                                                  fontSize: 16,
                                                  color: isDark ? Colors.white : AppTheme.gray900,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              chat.lastUpdate != null ? _formatTime(chat.lastUpdate!) : '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: hasUnread
                                                    ? AppTheme.userPrimaryBlue
                                                    : (isDark ? Colors.white54 : const Color(0xFF666666)),
                                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chat.lastMessage ?? 'New conversation',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: hasUnread
                                                      ? (isDark ? Colors.white : AppTheme.gray900)
                                                      : (isDark ? Colors.white54 : const Color(0xFF666666)),
                                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (hasUnread)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.userPrimaryBlue,
                                                  shape: BoxShape.circle,
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
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load messages'),
                      TextButton(
                        onPressed: () => ref.read(myChatsProvider.notifier).fetchChats(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageChatsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage conversations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: You can also swipe left on any chat to delete it.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              title: const Text('Clear all conversations', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently deletes all chats and messages'),
              onTap: () async {
                Navigator.pop(ctx);
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Clear all conversations?'),
                    content: const Text(
                      'This will permanently delete ALL conversations and messages. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  try {
                    await ref.read(myChatsProvider.notifier).clearAllChats();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All conversations cleared')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to clear conversations')),
                      );
                    }
                  }
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Messaging privacy settings'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/profile');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
