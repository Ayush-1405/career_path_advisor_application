import 'package:career_advisor_flutter/models/user.dart';
import 'package:career_advisor_flutter/models/career_path.dart';

class UserCareerPath {
  final String id;
  final User? user;
  final CareerPath? careerPath;
  final String? userId;
  final String? careerPathId;
  final String status;
  final DateTime appliedAt;
  final DateTime? updatedAt;

  UserCareerPath({
    required this.id,
    this.user,
    this.careerPath,
    this.userId,
    this.careerPathId,
    required this.status,
    required this.appliedAt,
    this.updatedAt,
  });

  factory UserCareerPath.fromJson(Map<String, dynamic> json) {
    String rawStatus =
        (json['status'] ??
                json['applicationStatus'] ??
                json['currentStatus'] ??
                'APPLIED')
            .toString();
    String norm = rawStatus.trim().toUpperCase().replaceAll(' ', '_');
    if (norm == 'PENDING' || norm == 'PROCESSING') {
      norm = 'IN_PROGRESS';
    }
    return UserCareerPath(
      id: json['id']?.toString() ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      careerPath: json['careerPath'] != null
          ? CareerPath.fromJson(json['careerPath'])
          : null,
      userId: json['userId']?.toString(),
      careerPathId: json['careerPathId']?.toString(),
      status: norm,
      appliedAt: json['appliedAt'] != null
          ? DateTime.parse(json['appliedAt'])
          : DateTime.now(),
      updatedAt:
          (json['updatedAt'] is String &&
              (json['updatedAt'] as String).isNotEmpty)
          ? DateTime.parse(json['updatedAt'])
          : json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }
}
