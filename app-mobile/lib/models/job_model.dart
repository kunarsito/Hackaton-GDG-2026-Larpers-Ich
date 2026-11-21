import 'user_model.dart';

/// Vacante (RF-08, RF-17). Sincronizado con `JobOpportunity` (models.ts).
class JobOpportunityModel {
  final String id;
  final String title;
  final String companyOrPoster;
  final String type; // 'Pasantía' | 'Junior' | 'Freelance'
  final String modality; // 'Remoto' | 'Híbrido' | 'Presencial'
  final String description;
  final String contactUrl;
  final List<String> requirements;
  final String? createdAt;
  final String? posterId;
  bool hasApplied;
  final int? applicationsCount; // sólo para quien publicó

  JobOpportunityModel({
    required this.id,
    required this.title,
    required this.companyOrPoster,
    required this.type,
    required this.modality,
    required this.description,
    required this.contactUrl,
    this.requirements = const [],
    this.createdAt,
    this.posterId,
    this.hasApplied = false,
    this.applicationsCount,
  });

  factory JobOpportunityModel.fromJson(Map<String, dynamic> json) {
    return JobOpportunityModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      companyOrPoster: json['companyOrPoster'] as String? ?? '',
      type: json['type'] as String? ?? 'Junior',
      modality: json['modality'] as String? ?? 'Remoto',
      description: json['description'] as String? ?? '',
      contactUrl: json['contactUrl'] as String? ?? '',
      requirements: (json['requirements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: json['createdAt'] as String?,
      posterId: json['posterId'] as String?,
      hasApplied: json['hasApplied'] as bool? ?? false,
      applicationsCount: (json['applicationsCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'companyOrPoster': companyOrPoster,
      'type': type,
      'modality': modality,
      'description': description,
      'contactUrl': contactUrl,
      'requirements': requirements,
      if (createdAt != null) 'createdAt': createdAt,
      if (posterId != null) 'posterId': posterId,
      'hasApplied': hasApplied,
      if (applicationsCount != null) 'applicationsCount': applicationsCount,
    };
  }
}

/// Postulación con CV (RF-17). Sincronizado con `JobApplication` (models.ts).
class JobApplicationModel {
  final String id;
  final String jobId;
  final String applicantId;
  final String cvUrl;
  final String message;
  final String status; // enviada | vista | contactado
  final String createdAt;
  final UserSummaryModel? applicant;
  final String? jobTitle;

  JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.cvUrl,
    required this.message,
    required this.status,
    required this.createdAt,
    this.applicant,
    this.jobTitle,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) => JobApplicationModel(
        id: json['id'] as String? ?? '',
        jobId: json['jobId'] as String? ?? '',
        applicantId: json['applicantId'] as String? ?? '',
        cvUrl: json['cvUrl'] as String? ?? '',
        message: json['message'] as String? ?? '',
        status: json['status'] as String? ?? 'enviada',
        createdAt: json['createdAt'] as String? ?? '',
        applicant: json['applicant'] is Map<String, dynamic>
            ? UserSummaryModel.fromJson(json['applicant'] as Map<String, dynamic>)
            : null,
        jobTitle: json['jobTitle'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'applicantId': applicantId,
        'cvUrl': cvUrl,
        'message': message,
        'status': status,
        'createdAt': createdAt,
        if (applicant != null) 'applicant': applicant!.toJson(),
        if (jobTitle != null) 'jobTitle': jobTitle,
      };
}
