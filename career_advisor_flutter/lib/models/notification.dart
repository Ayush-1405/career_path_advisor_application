class AppNotification {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String type;
  final String message;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.type,
    required this.message,
    this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      recipientId: json['recipientId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Someone',
      senderAvatarUrl: json['senderAvatarUrl'],
      type: json['type'] ?? 'SYS',
      message: json['message'] ?? '',
      relatedEntityId: json['relatedEntityId'],
      isRead: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
