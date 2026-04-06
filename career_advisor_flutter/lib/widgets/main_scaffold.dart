import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/chat_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  Timer? _globalChatPollingTimer;

  @override
  void initState() {
    super.initState();
    // Poll chats every 15 seconds globally to keep the badge and notification alive
    _globalChatPollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.read(myChatsProvider.notifier).fetchChats(background: true);
    });
  }

  @override
  void dispose() {
    _globalChatPollingTimer?.cancel();
    super.dispose();
  }

  int _totalUnread(AsyncValue? state) {
    if (state == null || state.value == null) return 0;
    final list = state.value! as List;
    int total = 0;
    for (var room in list) {
      if (room.unreadCount != null) {
        total += (room.unreadCount as int);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // Listen for new unread messages to notify the user unconditionally
    ref.listen(myChatsProvider, (previous, next) {
      final prevUnread = _totalUnread(previous);
      final nextUnread = _totalUnread(next);
      if (nextUnread > prevUnread && location != '/chat') { // don't push toast if they're presumably chatting
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mark_email_unread, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(child: Text('You have a new message!')),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    context.go('/chat');
                  },
                  child: const Text('VIEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.userPrimaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    // Only show bottom nav for user routes, excluding auth/splash/landing
    final bool showBottomNav = location == '/home' ||
        location == '/dashboard' ||
        location == '/feed' ||
        location == '/connections' ||
        location == '/profile' ||
        location == '/chat';

    if (!showBottomNav) return widget.child;
    
    return PopScope(
      canPop: location == '/feed',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (location != '/feed') {
          context.go('/feed');
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _getSelectedIndex(location),
          onTap: (index) => _onItemTapped(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: AppTheme.userPrimaryBlue,
          unselectedItemColor: AppTheme.gray500,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.dynamic_feed_outlined),
              activeIcon: Icon(Icons.dynamic_feed),
              label: 'Feed',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Network',
            ),
            BottomNavigationBarItem(
              icon: Consumer(
                builder: (context, ref, child) {
                  final chatsState = ref.watch(myChatsProvider);
                  final unreadCount = _totalUnread(chatsState);
                  if (unreadCount > 0) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.chat_outlined),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const Icon(Icons.chat_outlined);
                },
              ),
              activeIcon: const Icon(Icons.chat),
              label: 'Chat',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );
}

  int _getSelectedIndex(String location) {
    if (location == '/home') return 0;
    if (location == '/feed') return 1;
    if (location == '/connections') return 2;
    if (location == '/chat') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/feed');
        break;
      case 2:
        context.go('/connections');
        break;
      case 3:
        context.go('/chat');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
