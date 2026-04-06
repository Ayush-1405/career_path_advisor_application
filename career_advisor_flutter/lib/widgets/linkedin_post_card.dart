import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../providers/app_auth_provider.dart';
import '../providers/connections_provider.dart';
import '../providers/social_feed_provider.dart';
import '../utils/image_helper.dart';
import '../screens/user/member_profile_screen.dart';

class LinkedInPostCard extends ConsumerStatefulWidget {
  final Post post;
  final bool isDark;
  final VoidCallback? onFeedRefresh;

  const LinkedInPostCard({
    super.key,
    required this.post,
    required this.isDark,
    this.onFeedRefresh,
  });

  @override
  ConsumerState<LinkedInPostCard> createState() => _LinkedInPostCardState();
}

class _LinkedInPostCardState extends ConsumerState<LinkedInPostCard> {
  bool _isLiking = false;

  void _sharePost(Post post) {
    Share.share(
      '${post.userName} shared a post: "${post.content}"\n\nJoin the conversation on Career Advisor!',
    );
  }

  void _showOtherPostOptionsSheet(BuildContext context, Post post, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.share, color: AppTheme.userPrimaryBlue),
                title: const Text('Share via...'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePost(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Save'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post saved!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: const Text('Report this post'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post reported. Thank you.')),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showPostOptionsSheet(BuildContext context, Post post, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppTheme.userPrimaryBlue),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditPostDialog(context, post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Post?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            try {
                              // Use provider's optimistic delete — no screen flash
                              await ref.read(socialFeedProvider.notifier).deletePost(post.id);
                              ref.read(myPostsProvider.notifier).fetchMyPosts(background: true);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: AppTheme.userPrimaryBlue),
                title: const Text('Share via...'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePost(post);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showEditPostDialog(BuildContext context, Post post) {
    final editController = TextEditingController(text: post.content);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: editController,
                  maxLines: 5,
                  style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Edit your post...',
                    hintStyle: TextStyle(color: widget.isDark ? Colors.white38 : Colors.black38),
                    border: InputBorder.none,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final text = editController.text.trim();
                      if (text.isNotEmpty) {
                        try {
                          // Optimistic via provider — no flicker
                          await ref.read(socialFeedProvider.notifier).updatePost(post.id, text);
                          ref.read(myPostsProvider.notifier).fetchMyPosts(background: true);
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update: $e')),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.userPrimaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommentDialog(BuildContext context, Post post) {
    final commentController = TextEditingController();
    bool isCommenting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Header handle
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Comments (${post.comments.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.isDark ? Colors.white : AppTheme.gray900,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              color: widget.isDark ? Colors.white70 : Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Comments List
                      Expanded(
                        child: post.comments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 48, color: widget.isDark ? Colors.white24 : Colors.black12),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No comments yet. Be the first to share your thoughts!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: widget.isDark ? Colors.white38 : Colors.black38),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: post.comments.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final comment = post.comments[index];
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundImage: comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                                            ? CachedNetworkImageProvider(ImageHelper.getImageUrl(comment.userAvatar!)!)
                                            : null,
                                        child: (comment.userAvatar == null || comment.userAvatar!.isEmpty)
                                            ? Text(comment.userName != null && comment.userName!.isNotEmpty ? comment.userName![0].toUpperCase() : '?')
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    comment.userName ?? 'Unknown User',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: widget.isDark ? Colors.white : AppTheme.gray900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    comment.text,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: widget.isDark ? Colors.white70 : AppTheme.gray700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (comment.createdAt != null)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4),
                                                child: Text(
                                                  _formatTimestamp(comment.createdAt!),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: widget.isDark ? Colors.white38 : Colors.black38,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 1),
                      // Input Field
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                          left: 16,
                          right: 16,
                          top: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentController,
                                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: TextStyle(color: widget.isDark ? Colors.white38 : Colors.black38),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  fillColor: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F8F8),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                maxLines: null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            isCommenting
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : IconButton(
                                    icon: const Icon(Icons.send_rounded, color: AppTheme.userPrimaryBlue),
                                    onPressed: () async {
                                      final text = commentController.text.trim();
                                      if (text.isNotEmpty) {
                                        setModalState(() => isCommenting = true);
                                        try {
                                          await ref.read(socialFeedProvider.notifier).commentOnPost(post.id, text);
                                          ref.read(myPostsProvider.notifier).fetchMyPosts(background: true);
                                          if (context.mounted) Navigator.pop(context);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                                          }
                                        } finally {
                                          setModalState(() => isCommenting = false);
                                        }
                                      }
                                    },
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
        );
      },
    );
  }

  void _showBottomSendSheet(BuildContext context, Post post, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Send to...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.gray900,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final connectionsState = ref.watch(connectionsProvider);
                      return connectionsState.when(
                        data: (state) {
                          if (state.network.isEmpty) {
                            return const Center(child: Text('No connections found.'));
                          }
                          return ListView.builder(
                            itemCount: state.network.length,
                            itemBuilder: (context, index) {
                              final user = state.network[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user.profilePictureUrl != null &&
                                          user.profilePictureUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(ImageHelper.getImageUrl(user.profilePictureUrl)!)
                                      : null,
                                  child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U')
                                      : null,
                                ),
                                title: Text(
                                  user.name,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(apiServiceProvider)
                                          .sendMessage(
                                            user.id,
                                            'Check out this post from ${post.userName}: ${post.content}',
                                          );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Post sent!')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.userPrimaryBlue),
                                  child: const Text('Send', style: TextStyle(color: Colors.white)),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostContent(Post post, bool isDark) {
    final content = post.content;
    final isEvent = content.startsWith('🗓 EVENT:');
    final isArticle = content.startsWith('📰 ARTICLE');
    final hasMedia = post.mediaUrls.isNotEmpty;

    if ((isEvent || isArticle) && hasMedia) {
      // Banner image on top, type badge, then text
      final badgeColor = isEvent ? Colors.orange : Colors.redAccent;
      final badgeIcon = isEvent ? Icons.event : Icons.article;
      final badgeLabel = isEvent ? 'Event' : 'Article';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image fills width
          Stack(
            children: [
              _networkImage(
                post.mediaUrls.first,
                isDark,
                height: 220,
              ),
              // Type badge overlay
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Tap to fullscreen
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, post.mediaUrls.first),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
          // Text content below image
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : AppTheme.gray900,
                height: 1.4,
              ),
            ),
          ),
          // Extra images if any (shouldn't happen for event/article but just in case)
          if (post.mediaUrls.length > 1)
            _buildMediaSection(
              Post(
                id: post.id, content: post.content, isAchievement: post.isAchievement,
                createdAt: post.createdAt, likesCount: post.likesCount, commentsCount: post.commentsCount,
                userId: post.userId, userName: post.userName, userAvatar: post.userAvatar,
                userBio: post.userBio, comments: post.comments, likes: post.likes,
                mediaUrls: post.mediaUrls.sublist(1),
                mediaType: post.mediaType,
              ),
              isDark,
            ),
        ],
      );
    }

    // Default: text then media grid
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : AppTheme.gray900,
              height: 1.4,
            ),
          ),
        ),
        if (hasMedia) _buildMediaSection(post, isDark),
      ],
    );
  }

  Widget _buildMediaSection(Post post, bool isDark) {
    final urls = post.mediaUrls;
    final isVideo = post.mediaType == 'VIDEO';

    if (isVideo) {
      // Video: show thumbnail-like placeholder with play button
      final videoUrl = ImageHelper.getImageUrl(urls.first) ?? urls.first;
      return Container(
        width: double.infinity,
        height: 220,
        margin: const EdgeInsets.only(top: 4),
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: videoUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.videocam, color: Colors.white38, size: 64),
              ),
            ),
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.black54,
              child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
            ),
          ],
        ),
      );
    }

    if (urls.length == 1) {
      final imgUrl = ImageHelper.getImageUrl(urls[0]) ?? urls[0];
      return GestureDetector(
        onTap: () => _showFullScreenImage(context, urls[0]),
        child: CachedNetworkImage(
          imageUrl: imgUrl,
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 260,
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 120,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            child: const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey)),
          ),
        ),
      );
    }

    // Multiple images: grid layout
    final displayCount = urls.length > 4 ? 4 : urls.length;
    final extra = urls.length - 4;

    if (displayCount == 2) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            for (int i = 0; i < 2; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, urls[i]),
                  child: _networkImage(urls[i], isDark, margin: i == 0 ? const EdgeInsets.only(right: 1) : const EdgeInsets.only(left: 1)),
                ),
              ),
          ],
        ),
      );
    }

    if (displayCount == 3) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, urls[0]),
                child: _networkImage(urls[0], isDark, margin: const EdgeInsets.only(right: 1)),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(context, urls[1]),
                      child: _networkImage(urls[1], isDark, margin: const EdgeInsets.only(left: 1, bottom: 1)),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(context, urls[2]),
                      child: _networkImage(urls[2], isDark, margin: const EdgeInsets.only(left: 1, top: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4 or more images
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(context, urls[0]),
                    child: _networkImage(urls[0], isDark, margin: const EdgeInsets.only(right: 1, bottom: 1)),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(context, urls[2]),
                    child: _networkImage(urls[2], isDark, margin: const EdgeInsets.only(right: 1, top: 1)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(context, urls[1]),
                    child: _networkImage(urls[1], isDark, margin: const EdgeInsets.only(left: 1, bottom: 1)),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(context, urls[3]),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _networkImage(urls[3], isDark, margin: const EdgeInsets.only(left: 1, top: 1)),
                        if (extra > 0)
                          Positioned.fill(
                            left: 1,
                            top: 1,
                            child: Container(
                              color: Colors.black54,
                              alignment: Alignment.center,
                              child: Text(
                                '+$extra',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
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

  Widget _networkImage(String url, bool isDark, {EdgeInsets? margin, double? height}) {
    return Container(
      height: height,
      margin: margin,
      child: CachedNetworkImage(
        imageUrl: ImageHelper.getImageUrl(url) ?? url,
        width: double.infinity,
        height: height ?? double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: height,
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: ImageHelper.getImageUrl(url) ?? url,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({

    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? activeColor,
    bool isActive = false,
  }) {
    final color = isActive
        ? (activeColor ?? AppTheme.userPrimaryBlue)
        : (widget.isDark ? Colors.white70 : const Color(0xFF666666));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = widget.isDark;
    final currentUser = ref.watch(currentUserProvider).value;
    final bool isMyPost = post.userId == currentUser?.id;
    final bool isLiked = currentUser != null && post.likes.contains(currentUser.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    if (isMyPost) {
                      context.push('/profile');
                    } else {
                      context.push('/profile/member/${post.userId}');
                    }
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: isDark
                        ? AppTheme.userPrimaryBlue.withAlpha(51)
                        : AppTheme.userPrimaryBlue.withAlpha(26),
                    backgroundImage: post.userAvatar != null && post.userAvatar!.isNotEmpty
                        ? CachedNetworkImageProvider(ImageHelper.getImageUrl(post.userAvatar)!)
                        : null,
                    child: post.userAvatar == null || post.userAvatar!.isEmpty
                        ? Text(
                            post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.userPrimaryBlue,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: () {
                                if (isMyPost) {
                                  context.push('/profile');
                                } else {
                                  context.push('/profile/member/${post.userId}');
                                }
                              },
                              child: Text(
                                post.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : AppTheme.gray900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (!isMyPost) ...[
                            const SizedBox(width: 8),
                            Consumer(
                              builder: (context, ref, child) {
                                final connectionsState = ref.watch(connectionsProvider);
                                final isConnected = connectionsState.maybeWhen(
                                  data: (state) => state.network.any((u) => u.id == post.userId),
                                  orElse: () => false,
                                );

                                return InkWell(
                                  onTap: () async {
                                    try {
                                      if (isConnected) {
                                        await ref.read(connectionsProvider.notifier).unfollowUser(post.userId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Unfollowed user')),
                                          );
                                        }
                                      } else {
                                        await ref.read(connectionsProvider.notifier).followUser(post.userId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Connection request sent!')),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Text(
                                      isConnected ? 'Unfollow' : '+ Connect',
                                      style: TextStyle(
                                        color: isConnected ? Colors.redAccent : AppTheme.userPrimaryBlue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      Text(
                        post.userBio ?? 'Career Professional',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF666666),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            _formatTimestamp(post.createdAt),
                            style: TextStyle(
                              color: isDark ? Colors.white38 : const Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.public, size: 12, color: isDark ? Colors.white38 : const Color(0xFF666666)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  color: isDark ? Colors.white54 : const Color(0xFF666666),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (isMyPost) {
                      _showPostOptionsSheet(context, post, isDark);
                    } else {
                      _showOtherPostOptionsSheet(context, post, isDark);
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Smart Content + Media rendering ────────────────────────
          _buildPostContent(post, isDark),

          // Stats row
          if (post.likesCount > 0 || post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  if (post.likesCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.userPrimaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.thumb_up, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF666666),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (post.commentsCount > 0)
                    InkWell(
                      onTap: () => _showCommentDialog(context, post),
                      child: Text(
                        '${post.commentsCount} comment${post.commentsCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF666666),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const Divider(height: 1, thickness: 0.5),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                  label: 'Like',
                  isActive: isLiked,
                  activeColor: AppTheme.userPrimaryBlue,
                  onTap: _isLiking
                      ? () {}
                      : () async {
                          if (currentUser == null) return;
                          setState(() => _isLiking = true);
                          try {
                            await ref
                                .read(socialFeedProvider.notifier)
                                .likePost(post.id, currentUser.id);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to like: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLiking = false);
                          }
                        },
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: () => _showCommentDialog(context, post),
                ),
                _buildActionButton(
                  icon: Icons.repeat_rounded,
                  label: 'Repost',
                  onTap: () {
                    _sharePost(post);
                  },
                ),
                _buildActionButton(
                  icon: Icons.send_outlined,
                  label: 'Send',
                  onTap: () => _showBottomSendSheet(context, post, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
