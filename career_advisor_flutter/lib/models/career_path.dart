class CareerPath {
  final String id;
  final String title;
  final String description;
  final String level;
  final String category;
  final String image;
  final String averageSalary;
  final String growth;
  final int popularity;
  final List<String> requiredSkills;
  final List<Map<String, String>> careerProgression;

  CareerPath({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.category,
    required this.image,
    required this.averageSalary,
    required this.growth,
    required this.popularity,
    required this.requiredSkills,
    required this.careerProgression,
  });

  factory CareerPath.fromJson(Map<String, dynamic> json) {
    return CareerPath(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] ?? '',
      category: json['category'] ?? '',
      image: json['image'] ?? '',
      averageSalary: json['averageSalary'] ?? '',
      growth: json['growth'] ?? '',
      popularity: json['popularity'] ?? 0,
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      careerProgression: (json['careerProgression'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'level': level,
      'category': category,
      'image': image,
      'averageSalary': averageSalary,
      'growth': growth,
      'popularity': popularity,
      'requiredSkills': requiredSkills,
      'careerProgression': careerProgression,
    };
  }
}
