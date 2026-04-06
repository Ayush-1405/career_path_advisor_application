import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../services/api_service.dart';

final socialFeedProvider = StateNotifierProvider<SocialFeedNotifier, AsyncValue<List<Post>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SocialFeedNotifier(apiService);
});

class SocialFeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final ApiService _apiService;

  SocialFeedNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchFeed();
  }

  Future<void> fetchFeed({bool background = false}) async {
    if (!background) {
      state = const AsyncValue.loading();
    }
    try {
      final response = await _apiService.fetchFeed();
      if (response is List) {
        final posts = response.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(posts);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      if (!background) {
        state = AsyncValue.error(e, st);
      } else if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  // Silent background refresh — NEVER shows loading spinner
  Future<void> _silentRefresh() async {
    try {
      final response = await _apiService.fetchFeed();
      if (response is List) {
        final posts = response.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(posts);
      }
    } catch (_) {}
  }

  Future<void> createPost(String content, {
    bool isAchievement = false,
    List<String>? mediaUrls,
    String? mediaType,
  }) async {
    try {
      await _apiService.createPost(
        content,
        isAchievement: isAchievement,
        mediaUrls: mediaUrls,
        mediaType: mediaType,
      );
      await _silentRefresh();
    } catch (e) {
      rethrow;
    }
  }

  /// Optimistic like/unlike — toggles instantly, syncs in background
  Future<void> likePost(String postId, String currentUserId) async {
    if (state.value == null) return;
    final currentPosts = List<Post>.from(state.value!);
    final index = currentPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = currentPosts[index];
    final alreadyLiked = post.likes.contains(currentUserId);

    final newLikes = List<String>.from(post.likes);
    if (alreadyLiked) {
      newLikes.remove(currentUserId);
    } else {
      newLikes.add(currentUserId);
    }
    currentPosts[index] = post.copyWith(
      likes: newLikes,
      likesCount: alreadyLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
    state = AsyncValue.data(currentPosts);

    try {
      await _apiService.likePost(postId);
      await _silentRefresh();
    } catch (e) {
      await _silentRefresh();
      rethrow;
    }
  }

  /// Optimistic comment count increment
  Future<void> commentOnPost(String postId, String text) async {
    if (state.value != null) {
      final currentPosts = List<Post>.from(state.value!);
      final index = currentPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = currentPosts[index];
        currentPosts[index] = post.copyWith(commentsCount: post.commentsCount + 1);
        state = AsyncValue.data(currentPosts);
      }
    }
    try {
      await _apiService.commentOnPost(postId, text);
      await _silentRefresh();
    } catch (e) {
      await _silentRefresh();
      rethrow;
    }
  }

  /// Optimistic content edit
  Future<void> updatePost(String postId, String content) async {
    if (state.value != null) {
      final currentPosts = List<Post>.from(state.value!);
      final index = currentPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        currentPosts[index] = currentPosts[index].copyWith(content: content);
        state = AsyncValue.data(currentPosts);
      }
    }
    try {
      await _apiService.updatePost(postId, content);
    } catch (e) {
      await _silentRefresh();
      rethrow;
    }
  }

  /// Optimistic delete — removes instantly from list
  Future<void> deletePost(String postId) async {
    if (state.value != null) {
      final currentPosts = state.value!.where((p) => p.id != postId).toList();
      state = AsyncValue.data(currentPosts);
    }
    try {
      await _apiService.deletePost(postId);
    } catch (e) {
      await _silentRefresh();
      rethrow;
    }
  }
}

final myPostsProvider =
    StateNotifierProvider<MyPostsNotifier, AsyncValue<List<Post>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MyPostsNotifier(apiService);
});

class MyPostsNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final ApiService _apiService;

  MyPostsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchMyPosts();
  }

  Future<void> fetchMyPosts({bool background = false}) async {
    if (!background && state.value == null) {
      state = const AsyncValue.loading();
    }
    try {
      final response = await _apiService.fetchMyPosts();
      if (response is List) {
        final posts = response
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(posts);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      if (!background) {
        state = AsyncValue.error(e, st);
      } else if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final response = await _apiService.fetchMyPosts();
      if (response is List) {
        final posts = response
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(posts);
      }
    } catch (_) {}
  }
}
