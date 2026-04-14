import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import '../../providers/connections_provider.dart';
import '../../models/connection.dart';
import '../../services/api_service.dart';
import '../../providers/app_auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification.dart';
import '../../utils/image_helper.dart';
import '../../providers/navigation_provider.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const ConnectionsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _pollingTimer;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(connectionsTabIndexProvider.notifier).state = _tabController.index;
      }
    });
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(connectionsProvider.notifier).fetchData(background: true);
      ref.read(notificationsProvider.notifier).fetchNotifications(background: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final connectionsState = ref.watch(connectionsProvider);
    final notificationsState = ref.watch(notificationsProvider);

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE9E5DF), // LinkedIn typical background
        appBar: AppBar(
          title: const Text('My Network', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: false,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              color: isDark ? Colors.white70 : AppTheme.gray600,
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // LinkedIn Style Search Bar
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
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search connections',
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
              child: connectionsState.when(
                data: (state) {
                  return Column(
                    children: [
                      Container(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          labelColor: AppTheme.userPrimaryBlue,
                            unselectedLabelColor: isDark ? Colors.white54 : const Color(0xFF666666),
                            indicatorColor: AppTheme.userPrimaryBlue,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                            tabs: const [
                              Tab(text: 'Connections'),
                              Tab(text: 'Invitations'),
                              Tab(text: 'Grow'),
                              Tab(text: 'Notifications'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildNetworkList(
                                context,
                                ref,
                                state.network,
                                isDark,
                              ),
                              _buildInvitationsList(
                                context,
                                ref,
                                state.invitations,
                                isDark,
                              ),
                              _buildFindFriendsList(
                                context,
                                ref,
                                state.suggested,
                                isDark,
                              ),
                              _buildNotificationsTab(
                                context,
                                ref,
                                notificationsState,
                                isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load connections'),
                      TextButton(
                        onPressed: () => ref.read(connectionsProvider.notifier).fetchData(),
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

  Widget _buildNetworkList(
    BuildContext context,
    WidgetRef ref,
    List<ConnectionUser> allNetwork,
    bool isDark,
  ) {
    final network = allNetwork.where((user) {
      return user.name.toLowerCase().contains(_searchQuery) ||
          (user.role?.toLowerCase().contains(_searchQuery) ?? false) ||
          (user.bio?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (network.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return const Center(child: Text('No connections found.'));
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.gray400),
            const SizedBox(height: 16),
            Text(
              'No connections yet.',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.gray500,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.read(connectionsProvider.notifier).fetchData(),
      child: ListView.builder(
        itemCount: network.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final user = network[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 1),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: ListTile(
              onTap: () => context.push('/profile/member/${user.id}'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: isDark
                    ? AppTheme.userPrimaryBlue.withAlpha(51)
                    : AppTheme.userPrimaryBlue.withAlpha(26),
                backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(user.profilePictureUrl!)
                    : null,
                child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.userPrimaryBlue,
                        ),
                      )
                    : null,
              ),
              title: Text(
                user.name,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.gray900,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                user.bio ?? user.role ?? 'Career Enthusiast',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF666666),
                  fontSize: 14,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.message_outlined),
                    tooltip: 'Message',
                    onPressed: () async {
                      final apiService = ref.read(apiServiceProvider);
                      final roomId = await apiService.getOrCreateChatRoom(user.id);
                      if (context.mounted && roomId != null) {
                        context.push(
                          '/chat/$roomId',
                          extra: {
                            'userId': user.id,
                            'userName': user.name,
                            'userAvatar': user.profilePictureUrl,
                          },
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open chat. Please try again.')),
                        );
                      }
                    },
                    color: AppTheme.userPrimaryBlue,
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: isDark ? Colors.white38 : Colors.grey),
                    onSelected: (value) {
                      if (value == 'unfollow') {
                        _showUnfollowConfirmation(context, ref, user);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'unfollow',
                        child: Text('Disconnect', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvitationsList(
    BuildContext context,
    WidgetRef ref,
    List<ConnectionUser> invitations,
    bool isDark,
  ) {
    if (invitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: AppTheme.gray400),
            const SizedBox(height: 16),
            Text(
              'No pending invitations.',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: invitations.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final user = invitations[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 1),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: ListTile(
            onTap: () => context.push('/profile/member/${user.id}'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(user.profilePictureUrl!)
                  : null,
              child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                  ? Text(user.name[0].toUpperCase())
                  : null,
            ),
            title: Text(
              user.name,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.gray900,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              user.bio ?? user.role ?? 'Wants to connect',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => ref.read(connectionsProvider.notifier).rejectInvitation(user.id),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => ref.read(connectionsProvider.notifier).acceptInvitation(user.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFindFriendsList(
    BuildContext context,
    WidgetRef ref,
    List<ConnectionUser> suggested,
    bool isDark,
  ) {
    if (suggested.isEmpty) {
      return Center(
        child: Text(
          'No suggestions right now.',
          style: TextStyle(color: isDark ? Colors.white70 : AppTheme.gray500),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.read(connectionsProvider.notifier).fetchData(),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          mainAxisExtent: 310, // Increased to accommodate bio info
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: suggested.length,
        itemBuilder: (context, index) {
          final user = suggested[index];
          return InkWell(
            onTap: () => context.push('/profile/member/${user.id}'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                ),
              ),
            child: Column(
              children: [
                // Banner area mock
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(Icons.auto_awesome, size: 40, color: isDark ? Colors.white : Colors.blue),
                    ),
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const SizedBox(height: 40),
                    Positioned(
                      top: -30,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: isDark
                              ? AppTheme.userPrimaryBlue.withAlpha(51)
                              : AppTheme.userPrimaryBlue.withAlpha(26),
                          backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(user.profilePictureUrl!)
                              : null,
                          child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppTheme.userPrimaryBlue,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.gray900,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.role ?? 'Career Explorer',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : const Color(0xFF666666),
                            fontSize: 11,
                          ),
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            user.bio!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final connections = ref.watch(connectionsProvider).valueOrNull;
                      final isPending = connections?.sentRequests.any((u) => u.id == user.id) ?? false;
                      
                      return OutlinedButton(
                        onPressed: isPending ? null : () {
                          ref.read(connectionsProvider.notifier).followUser(user.id);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isPending ? Colors.grey : AppTheme.userPrimaryBlue, 
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          minimumSize: const Size(double.infinity, 32),
                        ),
                        child: Text(
                          isPending ? 'Pending' : 'Connect',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isPending ? Colors.grey : AppTheme.userPrimaryBlue,
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  void _showMessageDialog(
    BuildContext context,
    WidgetRef ref,
    ConnectionUser user,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Message ${user.name}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Type your message...'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  try {
                    final apiService = ref.read(apiServiceProvider);
                    final response = await apiService.sendMessage(
                      user.id,
                      controller.text.trim(),
                    );

                    if (context.mounted) {
                      Navigator.pop(context);

                      // Try to extract chatRoomId from response
                      String? roomId;
                      if (response is Map && response.containsKey('data')) {
                        final data = response['data'];
                        if (data is Map && data.containsKey('chatRoomId')) {
                          roomId = data['chatRoomId'];
                        }
                      }

                      if (roomId != null) {
                        context.push(
                          '/chat/$roomId',
                          extra: {
                            'userId': user.id,
                            'userName': user.name,
                            'userAvatar': user.profilePictureUrl,
                          },
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message sent! Check your chats.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.userPrimaryBlue),
              child: const Text('Send', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AppNotification>> notificationsState,
    bool isDark,
  ) {
    return notificationsState.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.gray400),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet.',
                  style: TextStyle(color: isDark ? Colors.white70 : AppTheme.gray500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return InkWell(
                onTap: () {
                  ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                  // Optional: proper routing here based on notif.type (e.g. to a post page)
                },
                child: Container(
                  color: notif.isRead
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : (isDark ? AppTheme.userPrimaryBlue.withAlpha(20) : AppTheme.userPrimaryBlue.withAlpha(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: notif.senderAvatarUrl != null && notif.senderAvatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(ImageHelper.getImageUrl(notif.senderAvatarUrl)!)
                                : null,
                            child: notif.senderAvatarUrl == null || notif.senderAvatarUrl!.isEmpty
                                ? Text(notif.senderName[0].toUpperCase())
                                : null,
                          ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _getNotificationColor(notif.type),
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                              ),
                              child: Icon(
                                _getNotificationIcon(notif.type),
                                color: Colors.white,
                                size: 10,
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
                            RichText(
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppTheme.gray900,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${notif.senderName} ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: notif.message.replaceAll(notif.senderName, '').trim(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimeAgo(notif.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : AppTheme.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load: $e')),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'LIKE': return Colors.blue;
      case 'COMMENT': return Colors.green;
      case 'SHARE': return Colors.orange;
      case 'FOLLOW_REQUEST': return Colors.purple;
      case 'FOLLOW_ACCEPT': return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'LIKE': return Icons.thumb_up;
      case 'COMMENT': return Icons.comment;
      case 'SHARE': return Icons.share;
      case 'FOLLOW_REQUEST': return Icons.person_add;
      case 'FOLLOW_ACCEPT': return Icons.check_circle;
      default: return Icons.notifications;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _showUnfollowConfirmation(BuildContext context, WidgetRef ref, ConnectionUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Connection'),
        content: Text('Are you sure you want to disconnect from ${user.name}? You will no longer follow each other.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(connectionsProvider.notifier).unfollowUser(user.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Successfully disconnected from ${user.name}')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
