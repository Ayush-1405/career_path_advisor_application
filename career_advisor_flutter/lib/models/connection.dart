class ConnectionUser {
  final String id;
  final String name;
  final String? profilePictureUrl;
  final String? bio;
  final String? role;

  ConnectionUser({
    required this.id,
    required this.name,
    this.profilePictureUrl,
    this.bio,
    this.role,
  });

  factory ConnectionUser.fromJson(Map<String, dynamic> json) {
    return ConnectionUser(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      profilePictureUrl: json['profilePictureUrl'],
      bio: json['bio'],
      role: json['role'],
    );
  }
}
