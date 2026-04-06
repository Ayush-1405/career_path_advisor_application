class Comment {
  final String text;
  final String? userName;
  final String? userAvatar;
  final DateTime? createdAt;

  Comment({
    required this.text,
    this.userName,
    this.userAvatar,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      text: json['text'] ?? '',
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class Post {
  final String id;
  final String content;
  final bool isAchievement;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? userBio;
  final List<Comment> comments;
  final List<String> likes;
  final List<String> mediaUrls;
  final String? mediaType; // 'IMAGE', 'VIDEO', or null

  Post({
    required this.id,
    required this.content,
    required this.isAchievement,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.userBio,
    required this.comments,
    required this.likes,
    this.mediaUrls = const [],
    this.mediaType,
  });

  Post copyWith({
    String? id,
    String? content,
    bool? isAchievement,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    String? userId,
    String? userName,
    String? userAvatar,
    String? userBio,
    List<Comment>? comments,
    List<String>? likes,
    List<String>? mediaUrls,
    String? mediaType,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      isAchievement: isAchievement ?? this.isAchievement,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userBio: userBio ?? this.userBio,
      comments: comments ?? this.comments,
      likes: likes ?? this.likes,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      isAchievement: json['isAchievement'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      userAvatar: json['userAvatar'],
      userBio: json['userBio'],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      likes: (json['likes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      mediaType: json['mediaType'],
    );
  }
}

