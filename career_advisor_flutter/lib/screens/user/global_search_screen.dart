import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/theme.dart';
import '../../widgets/animated_screen.dart';
import '../../providers/social_feed_provider.dart';
import '../../providers/connections_provider.dart';
import '../../models/post.dart';
import '../../models/connection.dart';
import '../../widgets/linkedin_post_card.dart';
import '../../utils/image_helper.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final feedState = ref.watch(socialFeedProvider);
    final connectionsState = ref.watch(connectionsProvider);

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F2EF),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF3F8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val.toLowerCase()),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search people or posts',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF666666),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: isDark ? Colors.white38 : const Color(0xFF666666),
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.userPrimaryBlue,
            labelColor: AppTheme.userPrimaryBlue,
            unselectedLabelColor: isDark ? Colors.white54 : const Color(0xFF666666),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'People'),
              Tab(text: 'Posts'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPeopleSearch(connectionsState, isDark),
            _buildPostsSearch(feedState, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleSearch(AsyncValue<ConnectionsState> state, bool isDark) {
    if (_query.isEmpty) {
      return _buildSearchPlaceholder('Search for people by name, role, or bio.');
    }

    return state.when(
      data: (connections) {
        final List<ConnectionUser> allUsers = [
          ...connections.network,
          ...connections.suggested,
          ...connections.invitations,
          ...connections.sentRequests,
        ];

        // Deduplicate by ID
        final Map<String, ConnectionUser> uniqueUsers = {};
        for (var u in allUsers) {
          uniqueUsers[u.id] = u;
        }

        final results = uniqueUsers.values.where((u) {
          return u.name.toLowerCase().contains(_query) ||
              (u.role?.toLowerCase().contains(_query) ?? false) ||
              (u.bio?.toLowerCase().contains(_query) ?? false);
        }).toList();

        if (results.isEmpty) {
          return _buildNoResults();
        }

        return ListView.builder(
          itemCount: results.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final user = results[index];
            return Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              margin: const EdgeInsets.only(bottom: 1),
              child: ListTile(
                onTap: () => context.push('/profile/member/${user.id}'),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark ? Colors.white12 : AppTheme.userPrimaryBlue.withAlpha(20),
                  backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(ImageHelper.getImageUrl(user.profilePictureUrl)!)
                      : null,
                  child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U')
                      : null,
                ),
                title: Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.gray900,
                  ),
                ),
                subtitle: Text(
                  user.role ?? user.bio ?? 'Career Advisor User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppTheme.gray600,
                    fontSize: 13,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPostsSearch(AsyncValue<List<Post>> state, bool isDark) {
    if (_query.isEmpty) {
      return _buildSearchPlaceholder('Search for posts by content or author.');
    }

    return state.when(
      data: (posts) {
        final results = posts.where((p) {
          return p.content.toLowerCase().contains(_query) ||
              p.userName.toLowerCase().contains(_query);
        }).toList();

        if (results.isEmpty) {
          return _buildNoResults();
        }

        return ListView.builder(
          itemCount: results.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            return LinkedInPostCard(
              post: results[index],
              isDark: isDark,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSearchPlaceholder(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: isDark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: isDark ? Colors.white30 : Colors.black26),
          const SizedBox(height: 16),
          Text(
            'No results found for "$_query"',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try checking your spelling or using more general terms.',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
