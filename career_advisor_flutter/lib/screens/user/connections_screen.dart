import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Connections'),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              color: isDark ? Colors.white70 : null,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.search),
              color: isDark ? Colors.white70 : null,
              onPressed: () {},
            ),
          ],
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: AppTheme.userPrimaryBlue,
                unselectedLabelColor: isDark ? Colors.white38 : AppTheme.gray500,
                indicatorColor: AppTheme.userPrimaryBlue,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'My Network'),
                  Tab(text: 'Find Friends'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildNetworkList(context, isDark),
                    _buildFindFriendsList(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkList(BuildContext context, bool isDark) {
    return ListView.separated(
      itemCount: 15,
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : null),
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isDark ? AppTheme.userPrimaryBlue.withOpacity(0.2) : AppTheme.userPrimaryBlue.withOpacity(0.1),
            child: Text(
              'N${index + 1}',
              style: TextStyle(color: isDark ? Colors.white : AppTheme.userPrimaryBlue),
            ),
          ),
          title: Text(
            'Connection Name ${index + 1}',
            style: TextStyle(color: isDark ? Colors.white : AppTheme.gray900, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Software Engineer at TechCorp',
            style: TextStyle(color: isDark ? Colors.white60 : AppTheme.gray600),
          ),
          trailing: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: isDark ? const BorderSide(color: Colors.white24) : null,
              foregroundColor: isDark ? Colors.white : null,
            ),
            child: const Text('Message'),
          ),
        );
      },
    );
  }

  Widget _buildFindFriendsList(BuildContext context, bool isDark) {
    return ListView.separated(
      itemCount: 20,
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : null),
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isDark ? AppTheme.userPrimaryPurple.withOpacity(0.2) : AppTheme.userPrimaryPurple.withOpacity(0.1),
            child: Text(
              'F${index + 1}',
              style: TextStyle(color: isDark ? Colors.white : AppTheme.userPrimaryPurple),
            ),
          ),
          title: Text(
            'Potential Friend ${index + 1}',
            style: TextStyle(color: isDark ? Colors.white : AppTheme.gray900, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'University Student • AI Researcher',
            style: TextStyle(color: isDark ? Colors.white60 : AppTheme.gray600),
          ),
          trailing: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(80, 36),
              backgroundColor: AppTheme.userPrimaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Follow'),
          ),
        );
      },
    );
  }
}
