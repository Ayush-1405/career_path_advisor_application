class ResumeProfile {
  final String id;
  final String userId;

  final String? originalFileName;
  final String? storedFileName;
  final String? fileType;
  final int? fileSize;
  final String? filePath;
  final String? fileUrl;

  final String? name;
  final String? email;
  final String? phone;
  final String? summary;
  final List<String> skills;
  final List<EducationEntry> education;
  final List<ExperienceEntry> experience;
  final List<ProjectEntry> projects;

  ResumeProfile({
    required this.id,
    required this.userId,
    this.originalFileName,
    this.storedFileName,
    this.fileType,
    this.fileSize,
    this.filePath,
    this.fileUrl,
    this.name,
    this.email,
    this.phone,
    this.summary,
    this.skills = const [],
    this.education = const [],
    this.experience = const [],
    this.projects = const [],
  });

  factory ResumeProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userId =
        (user is Map ? (user['id'] ?? user['userId']) : null)?.toString() ??
        json['userId']?.toString() ??
        '';

    return ResumeProfile(
      id: json['id']?.toString() ?? '',
      userId: userId,
      originalFileName: json['originalFileName']?.toString(),
      storedFileName: json['storedFileName']?.toString(),
      fileType: json['fileType']?.toString(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      filePath: json['filePath']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      summary: json['summary']?.toString(),
      skills: (json['skills'] is List)
          ? List<String>.from((json['skills'] as List).map((e) => e.toString()))
          : const [],
      education: (json['education'] is List)
          ? (json['education'] as List)
                .map(
                  (e) => EducationEntry.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      experience: (json['experience'] is List)
          ? (json['experience'] as List)
                .map(
                  (e) => ExperienceEntry.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      projects: (json['projects'] is List)
          ? (json['projects'] as List)
                .map((e) => ProjectEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toUpdatePayload({String? overrideUserId}) {
    return {
      'userId': ?overrideUserId,
      'name': name,
      'email': email,
      'phone': phone,
      'summary': summary,
      'skills': skills,
      'education': education.map((e) => e.toJson()).toList(),
      'experience': experience.map((e) => e.toJson()).toList(),
      'projects': projects.map((e) => e.toJson()).toList(),
    };
  }
}

class EducationEntry {
  final String? degree;
  final String? institute;
  final String? startYear;
  final String? endYear;
  final String? score;
  final String? details;

  EducationEntry({
    this.degree,
    this.institute,
    this.startYear,
    this.endYear,
    this.score,
    this.details,
  });

  factory EducationEntry.fromJson(Map<String, dynamic> json) => EducationEntry(
    degree: json['degree']?.toString(),
    institute: json['institute']?.toString(),
    startYear: json['startYear']?.toString(),
    endYear: json['endYear']?.toString(),
    score: json['score']?.toString(),
    details: json['details']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'degree': degree,
    'institute': institute,
    'startYear': startYear,
    'endYear': endYear,
    'score': score,
    'details': details,
  };
}

class ExperienceEntry {
  final String? title;
  final String? company;
  final String? startDate;
  final String? endDate;
  final String? location;
  final List<String> highlights;

  ExperienceEntry({
    this.title,
    this.company,
    this.startDate,
    this.endDate,
    this.location,
    this.highlights = const [],
  });

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) =>
      ExperienceEntry(
        title: json['title']?.toString(),
        company: json['company']?.toString(),
        startDate: json['startDate']?.toString(),
        endDate: json['endDate']?.toString(),
        location: json['location']?.toString(),
        highlights: (json['highlights'] is List)
            ? List<String>.from(
                (json['highlights'] as List).map((e) => e.toString()),
              )
            : const [],
      );

  Map<String, dynamic> toJson() => {
    'title': title,
    'company': company,
    'startDate': startDate,
    'endDate': endDate,
    'location': location,
    'highlights': highlights,
  };
}

class ProjectEntry {
  final String? title;
  final String? link;
  final String? description;
  final List<String> technologies;

  ProjectEntry({
    this.title,
    this.link,
    this.description,
    this.technologies = const [],
  });

  factory ProjectEntry.fromJson(Map<String, dynamic> json) => ProjectEntry(
    title: json['title']?.toString(),
    link: json['link']?.toString(),
    description: json['description']?.toString(),
    technologies: (json['technologies'] is List)
        ? List<String>.from(
            (json['technologies'] as List).map((e) => e.toString()),
          )
        : const [],
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'link': link,
    'description': description,
    'technologies': technologies,
  };
}
