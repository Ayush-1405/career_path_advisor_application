import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../utils/image_helper.dart';
import '../../widgets/animated_screen.dart';
import '../../widgets/linkedin_post_card.dart';
import '../../providers/connections_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/post.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const MemberProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _socialStats = {
    'connectionsCount': 0,
  };
  List<Post> _userPosts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.userId.isEmpty) {
        debugPrint('--- MemberProfileScreen Error: userId is empty! ---');
        if (mounted) setState(() => _isLoading = false);
        return;
    }
    if (mounted) setState(() => _isLoading = true);
    debugPrint('--- MemberProfileScreen: Starting Fetch for ${widget.userId} ---');
    try {
      final results = await Future.wait([
        ref.read(apiServiceProvider).fetchUserProfile(widget.userId),
        ref.read(apiServiceProvider).fetchUserSocialStats(userId: widget.userId).catchError((e) {
            debugPrint('Error fetching social stats: $e');
            return {'connectionsCount': 0};
        }),
        ref.read(apiServiceProvider).fetchUserPosts(widget.userId).catchError((e) {
            debugPrint('Error fetching user posts: $e');
            return [];
        }),
      ]);
      debugPrint('--- MemberProfileScreen: API results received ---');
      debugPrint('Profile Data: ${results[0]}');

      if (mounted) {
        setState(() {
          if (results[0] is Map) {
            _profile = Map<String, dynamic>.from(results[0] as Map);
          }
          
          if (results[1] is Map) {
            _socialStats = Map<String, dynamic>.from(results[1] as Map);
          } else {
            _socialStats = {'connectionsCount': 0};
          }
          
          final postsData = results[2];
          if (postsData is List) {
            _userPosts = postsData.map((json) => Post.fromJson(Map<String, dynamic>.from(json as Map))).toList();
          }
          
          _isLoading = false;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint('--- MemberProfileScreen Error: $e ---');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F2EF),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F2EF),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('User not found'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final connectionsState = ref.watch(connectionsProvider);
    final isConnected = connectionsState.maybeWhen(
      data: (state) => state.network.any((u) => u.id == widget.userId),
      orElse: () => false,
    );
    final isPending = connectionsState.maybeWhen(
      data: (state) => state.sentRequests.any((u) => u.id == widget.userId),
      orElse: () => false,
    );

    return AnimatedScreen(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F2EF),
        appBar: AppBar(
          title: Text(_profile!['name'] ?? 'Profile'),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppTheme.gray900,
          elevation: 0.5,
        ),
        body: RefreshIndicator(
          onRefresh: _fetchData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildMemberHeader(isDark, isConnected, isPending),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _buildAboutSection(isDark),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_isLoadingPosts)
                const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                )
              else if (_userPosts.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyActivity(isDark),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LinkedInPostCard(
                          post: _userPosts[index],
                          isDark: isDark,
                          onFeedRefresh: _fetchData,
                        ),
                      );
                    },
                    childCount: _userPosts.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberHeader(bool isDark, bool isConnected, bool isPending) {
    final avatarUrl = _profile!['profilePictureUrl'] as String?;
    final name = _profile!['name'] ?? 'Unknown User';
    final bio = _profile!['bio'] ?? 'Career Professional';
    final location = _profile!['location'] ?? '';
    
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.bottomLeft,
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFA0B4CB),
                      gradient: isDark 
                        ? const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]) 
                        : const LinearGradient(colors: [AppTheme.userPrimaryBlue, Color(0xFF7E9EC9)]),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: isDark ? Colors.black26 : Colors.grey.shade200,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? CachedNetworkImageProvider(ImageHelper.getImageUrl(avatarUrl)!) : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontSize: 40,
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
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bio,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                if (location.isNotEmpty)
                  Row(
                    children: [
                      Icon(Remix.map_pin_line, size: 14, color: isDark ? Colors.white54 : AppTheme.gray500),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${_socialStats['connectionsCount'] ?? 0} connections',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Action Button (Connect/Unfollow)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            if (isConnected) {
                              await ref.read(connectionsProvider.notifier).unfollowUser(widget.userId);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unfollowed user')));
                            } else {
                              await ref.read(connectionsProvider.notifier).followUser(widget.userId);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection request sent!')));
                            }
                            _fetchData(); // Refresh counts
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected 
                              ? Colors.redAccent 
                              : (isPending ? Colors.blueGrey : AppTheme.userPrimaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          isConnected ? 'Disconnect' : (isPending ? 'Pending' : 'Connect'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        // Find existing chat room if one exists
                        final myChats = ref.read(myChatsProvider).valueOrNull ?? [];
                        String roomId = 'new';
                        try {
                          final existingChat = myChats.firstWhere((chat) => chat.otherUserId == widget.userId);
                          roomId = existingChat.id;
                        } catch (_) {
                          // No existing chat found, will use 'new'
                        }

                        // Open chat logic
                        context.push('/chat/$roomId', extra: {
                          'userId': widget.userId,
                          'userName': name,
                          'userAvatar': avatarUrl,
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.userPrimaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: const Text('Message', style: TextStyle(color: AppTheme.userPrimaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAboutSection(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _profile!['bio']?.isNotEmpty == true
                ? _profile!['bio']
                : 'No bio available.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : AppTheme.gray900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          "No recent activity to show.",
          style: TextStyle(color: isDark ? Colors.white54 : AppTheme.gray500),
        ),
      ),
    );
  }
}
