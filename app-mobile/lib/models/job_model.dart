class JobOpportunityModel {
  final String id;
  final String title;
  final String companyOrPoster;
  final String type; // 'Pasantía' | 'Junior' | 'Freelance'
  final String modality; // 'Remoto' | 'Híbrido' | 'Presencial'
  final String description;
  final String contactUrl;

  JobOpportunityModel({
    required this.id,
    required this.title,
    required this.companyOrPoster,
    required this.type,
    required this.modality,
    required this.description,
    required this.contactUrl,
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
    };
  }
}
