class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? profilePictureUrl;
  final String? bio;
  final String? phoneNumber;
  final String? location;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? websiteUrl;
  final int? profileCompletion;
  final String? resumeUrl;
  final bool isPrivate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePictureUrl,
    this.bio,
    this.phoneNumber,
    this.location,
    this.linkedinUrl,
    this.githubUrl,
    this.websiteUrl,
    this.profileCompletion,
    this.resumeUrl,
    this.isPrivate = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      profilePictureUrl: json['profilePictureUrl'],
      bio: json['bio'],
      phoneNumber: json['phoneNumber'],
      location: json['location'],
      linkedinUrl: json['linkedinUrl'],
      githubUrl: json['githubUrl'],
      websiteUrl: json['websiteUrl'],
      profileCompletion: json['profileCompletion'],
      resumeUrl: json['resumeUrl'],
      isPrivate: json['isPrivate'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'location': location,
      'linkedinUrl': linkedinUrl,
      'githubUrl': githubUrl,
      'websiteUrl': websiteUrl,
      'profileCompletion': profileCompletion,
      'resumeUrl': resumeUrl,
      'isPrivate': isPrivate,
    };
  }

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isUser => role.toUpperCase() == 'USER';

  double get calculatedCompletionPercentage {
    int total = 9;
    int filled = 0;

    if (name.isNotEmpty) filled++;
    if (email.isNotEmpty) filled++;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) filled++;
    if (bio != null && bio!.isNotEmpty) filled++;
    if (location != null && location!.isNotEmpty) filled++;
    if (linkedinUrl != null && linkedinUrl!.isNotEmpty) filled++;
    if (githubUrl != null && githubUrl!.isNotEmpty) filled++;
    if (websiteUrl != null && websiteUrl!.isNotEmpty) filled++;
    if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) filled++;

    return filled / total;
  }
}
