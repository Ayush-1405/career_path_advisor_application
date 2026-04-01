import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Messages'),
          centerTitle: false,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note),
              color: isDark ? Colors.white70 : null,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz),
              color: isDark ? Colors.white70 : null,
              onPressed: () {},
            ),
          ],
        ),
        body: ListView.separated(
          itemCount: 12,
          separatorBuilder: (context, index) =>
              Divider(height: 1, indent: 70, color: isDark ? Colors.white10 : null),
          itemBuilder: (context, index) {
            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: isDark ? AppTheme.userPrimaryBlue.withOpacity(0.2) : AppTheme.userPrimaryBlue.withOpacity(0.1),
                    child: Text(
                      'C${index + 1}',
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.userPrimaryBlue),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: index % 3 == 0 ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                'Chat User ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.gray900,
                ),
              ),
              subtitle: Text(
                'Hey! Have you seen the new Python vacancy?',
                style: TextStyle(color: isDark ? Colors.white60 : AppTheme.gray600),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '2:30 PM',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : AppTheme.gray500),
                  ),
                  const SizedBox(height: 4),
                  if (index < 2)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.userPrimaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              onTap: () {},
            );
          },
        ),
      ),
    );
  }
}
