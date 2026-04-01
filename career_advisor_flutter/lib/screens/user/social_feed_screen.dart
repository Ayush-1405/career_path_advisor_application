import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Career Feed'),
          centerTitle: false,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              color: isDark ? Colors.white70 : null,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              color: isDark ? Colors.white70 : null,
              onPressed: () {},
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: 10,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            return _buildPostCard(context, index, isDark);
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppTheme.userPrimaryBlue,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, int index, bool isDark) {
    final bool isAchievement = index % 3 == 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isDark
                  ? AppTheme.userPrimaryBlue.withOpacity(0.2)
                  : AppTheme.userPrimaryBlue.withOpacity(0.1),
              child: Text(
                'U${index + 1}',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.userPrimaryBlue,
                ),
              ),
            ),
            title: Text(
              'User ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Career Enthusiast • 2h',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black54),
            ),
            trailing: Icon(
              Icons.more_horiz,
              color: isDark ? Colors.white38 : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              isAchievement
                  ? 'Thrilled to share that I have completed my Python Certification! 🎓'
                  : 'Just discovered an amazing resource for interview prep. Check out CareerPath AI!',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          if (isAchievement)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.userPrimaryPurple.withOpacity(0.1)
                    : AppTheme.userPrimaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppTheme.userPrimaryPurple.withOpacity(0.2)
                      : AppTheme.userPrimaryPurple.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 60,
                      color: isDark
                          ? AppTheme.userPrimaryPurple.withOpacity(0.8)
                          : AppTheme.userPrimaryPurple,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Achievement Unlocked!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Divider(height: 1, color: isDark ? Colors.white10 : null),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.thumb_up_outlined,
                  size: 20,
                  color: isDark ? Colors.white60 : null,
                ),
                label: Text(
                  'Like',
                  style: TextStyle(color: isDark ? Colors.white60 : null),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.comment_outlined,
                  size: 20,
                  color: isDark ? Colors.white60 : null,
                ),
                label: Text(
                  'Comment',
                  style: TextStyle(color: isDark ? Colors.white60 : null),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: isDark ? Colors.white60 : null,
                ),
                label: Text(
                  'Share',
                  style: TextStyle(color: isDark ? Colors.white60 : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
