class ChatRoom {
  final String chatRoomId;
  final String? lastMessage;
  final DateTime? lastUpdate;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final int unreadCount;

  ChatRoom({
    required this.chatRoomId,
    this.lastMessage,
    this.lastUpdate,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.unreadCount,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      chatRoomId: json['chatRoomId'] ?? '',
      lastMessage: json['lastMessage'],
      lastUpdate: json['lastUpdate'] != null ? DateTime.parse(json['lastUpdate']) : null,
      otherUserId: json['otherUserId'] ?? '',
      otherUserName: json['otherUserName'] ?? 'Unknown User',
      otherUserAvatar: json['otherUserAvatar'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  String get id => chatRoomId;

  ChatRoom copyWith({
    String? chatRoomId,
    String? lastMessage,
    DateTime? lastUpdate,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    int? unreadCount,
  }) {
    return ChatRoom(
      chatRoomId: chatRoomId ?? this.chatRoomId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      chatRoomId: json['chatRoomId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
