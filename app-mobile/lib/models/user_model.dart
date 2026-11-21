class UserModel {
  final String id;
  final String name;
  final String university;
  int karmaPoints;
  final List<String> solvedChallenges;

  UserModel({
    required this.id,
    required this.name,
    required this.university,
    required this.karmaPoints,
    required this.solvedChallenges,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? 'usr-001',
      name: json['name'] as String? ?? 'Estudiante Dev',
      university: json['university'] as String? ?? 'Campus Central',
      karmaPoints: (json['karmaPoints'] as num?)?.toInt() ?? 100,
      solvedChallenges: (json['solvedChallenges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'university': university,
      'karmaPoints': karmaPoints,
      'solvedChallenges': solvedChallenges,
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
    );
  }
}
