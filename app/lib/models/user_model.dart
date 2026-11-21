/// Usuario / perfil (SRS §5.1 · RF-15). Sincronizado con `User` en backend/src/types/models.ts.
class UserModel {
  final String id;
  final String name;
  final String university;
  int karmaPoints;
  final List<String> solvedChallenges;
  final List<String> roles;
  final String? avatarUrl;
  final String bio;
  final Map<String, String> links; // github, linkedin, website
  final List<String> skills;
  final int followers;
  final int following;
  final bool openToWork;
  final String? cvUrl;
  final bool? isFollowing;

  UserModel({
    required this.id,
    required this.name,
    required this.university,
    required this.karmaPoints,
    required this.solvedChallenges,
    this.roles = const ['student'],
    this.avatarUrl,
    this.bio = '',
    this.links = const {},
    this.skills = const [],
    this.followers = 0,
    this.following = 0,
    this.openToWork = false,
    this.cvUrl,
    this.isFollowing,
  });

  bool get isCreator => roles.contains('creator');
  bool get isRecruiter => roles.contains('recruiter');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['links'];
    return UserModel(
      id: json['id'] as String? ?? 'usr-001',
      name: json['name'] as String? ?? 'Estudiante Dev',
      university: json['university'] as String? ?? 'Campus Central',
      karmaPoints: (json['karmaPoints'] as num?)?.toInt() ?? 100,
      solvedChallenges: (json['solvedChallenges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['student'],
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String? ?? '',
      links: rawLinks is Map ? rawLinks.map((k, v) => MapEntry(k.toString(), v.toString())) : const {},
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      openToWork: json['openToWork'] as bool? ?? false,
      cvUrl: json['cvUrl'] as String?,
      isFollowing: json['isFollowing'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'university': university,
      'karmaPoints': karmaPoints,
      'solvedChallenges': solvedChallenges,
      'roles': roles,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'bio': bio,
      'links': links,
      'skills': skills,
      'followers': followers,
      'following': following,
      'openToWork': openToWork,
      if (cvUrl != null) 'cvUrl': cvUrl,
      if (isFollowing != null) 'isFollowing': isFollowing,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? university,
    int? karmaPoints,
    List<String>? solvedChallenges,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      university: university ?? this.university,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      solvedChallenges: solvedChallenges ?? this.solvedChallenges,
      roles: roles,
      avatarUrl: avatarUrl,
      bio: bio,
      links: links,
      skills: skills,
      followers: followers,
      following: following,
      openToWork: openToWork,
      cvUrl: cvUrl,
      isFollowing: isFollowing,
    );
  }
}

/// Resumen público de un usuario (listas de mensajes, postulantes, ranking).
class UserSummaryModel {
  final String id;
  final String name;
  final String university;
  final String? avatarUrl;
  final int karmaPoints;

  UserSummaryModel({
    required this.id,
    required this.name,
    required this.university,
    this.avatarUrl,
    required this.karmaPoints,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) => UserSummaryModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Usuario',
        university: json['university'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        karmaPoints: (json['karmaPoints'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'university': university,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'karmaPoints': karmaPoints,
      };
}
