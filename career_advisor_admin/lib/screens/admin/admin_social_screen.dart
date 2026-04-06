import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class AdminSocialScreen extends ConsumerStatefulWidget {
  const AdminSocialScreen({super.key});

  @override
  ConsumerState<AdminSocialScreen> createState() => _AdminSocialScreenState();
}

class _AdminSocialScreenState extends ConsumerState<AdminSocialScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _posts = [];
  Map<String, dynamic> _stats = {
    'totalPosts': 0,
    'totalConnections': 0,
    'activeChatRooms': 0,
    'totalMessages': 0,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final apiService = ref.read(apiServiceProvider);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final postsResponse = await apiService.fetchAdminPosts();
      final statsResponse = await apiService.fetchAdminSocialStats();

      if (mounted) {
        setState(() {
          if (postsResponse is List) {
            _posts = postsResponse;
          }
          if (statsResponse is Map) {
            _stats = {
              'totalPosts': statsResponse['totalPosts'] ?? 0,
              'totalConnections': statsResponse['totalConnections'] ?? 0,
              'activeChatRooms': statsResponse['activeChatRooms'] ?? 0,
              'totalMessages': statsResponse['totalMessages'] ?? 0,
            };
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin social data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load social data.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to permanently delete this post?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.adminPrimaryRed,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.deleteAdminPost(postId);
        await _loadData(); // refresh list and stats
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Social Moderation')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Social Moderation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _MetricCard(
                    title: 'Total Posts',
                    value: '${_stats['totalPosts']}',
                    icon: Icons.feed_rounded,
                    color: Colors.blue,
                  ),
                  _MetricCard(
                    title: 'Connections',
                    value: '${_stats['totalConnections']}',
                    icon: Icons.people_alt_rounded,
                    color: Colors.green,
                  ),
                  _MetricCard(
                    title: 'Active Chats',
                    value: '${_stats['activeChatRooms']}',
                    icon: Icons.chat_rounded,
                    color: Colors.orange,
                  ),
                  _MetricCard(
                    title: 'Messages Sent',
                    value: '${_stats['totalMessages']}',
                    icon: Icons.message_rounded,
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Global Feed Moderation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = _posts[index];
              return _buildAdminPostCard(post);
            }, childCount: _posts.length),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: AppTheme.adminPrimaryRed.withOpacity(0.1),
          backgroundImage: post['userAvatar'] != null
              ? NetworkImage(post['userAvatar'])
              : null,
          child: post['userAvatar'] == null
              ? Text(post['userName'] != null ? post['userName'][0] : 'U')
              : null,
        ),
        title: Text(
          '${post['userName']} ${post['isAchievement'] == true ? '🏆' : ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(post['content'] ?? ''),
            const SizedBox(height: 8),
            Text(
              'Likes: ${post['likesCount']} • Comments: ${post['commentsCount']} • Posted: ${post['createdAt']}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () => _deletePost(post['id']),
          tooltip: 'Delete Post',
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
