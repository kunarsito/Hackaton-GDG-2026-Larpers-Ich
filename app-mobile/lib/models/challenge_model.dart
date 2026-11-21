class TestCase {
  final String input;
  final String expectedOutput;
  final String description;

  TestCase({
    required this.input,
    required this.expectedOutput,
    required this.description,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      input: json['input']?.toString() ?? '',
      expectedOutput: json['expectedOutput']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      'expectedOutput': expectedOutput,
      'description': description,
    };
  }
}

/// Reto de práctica (oficial o de comunidad). Sincronizado con `Challenge` (models.ts).
class ChallengeModel {
  final String id;
  final String title;
  final String difficulty; // 'Básico', 'Intermedio', 'Avanzado'
  final String category;
  final String description;
  final String starterCode;
  final List<TestCase> testCases;
  final String source; // 'official' | 'community'
  final String? authorId;
  final String? authorName;
  int upvotes;
  int downvotes;
  final String? forkedFromId;
  final String createdAt;
  int myVote;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.category,
    required this.description,
    required this.starterCode,
    required this.testCases,
    this.source = 'official',
    this.authorId,
    this.authorName,
    this.upvotes = 0,
    this.downvotes = 0,
    this.forkedFromId,
    this.createdAt = '',
    this.myVote = 0,
  });

  bool get isOfficial => source == 'official';
  int get score => upvotes - downvotes;

  /// RF-14: +10 Karma los oficiales, +5 los de comunidad.
  int get karmaReward => isOfficial ? 10 : 5;

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    var rawCases = json['testCases'];
    List<TestCase> parsedCases = [];
    if (rawCases is List) {
      parsedCases = rawCases.map((c) {
        if (c is Map<String, dynamic>) {
          return TestCase.fromJson(c);
        } else {
          return TestCase(
            input: c.toString(),
            expectedOutput: '',
            description: '',
          );
        }
      }).toList();
    }

    return ChallengeModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Básico',
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      starterCode: json['starterCode'] as String? ?? '',
      testCases: parsedCases,
      source: json['source'] as String? ?? 'official',
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      forkedFromId: json['forkedFromId'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      myVote: (json['myVote'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'category': category,
      'description': description,
      'starterCode': starterCode,
      'testCases': testCases.map((e) => e.toJson()).toList(),
      'source': source,
      if (authorId != null) 'authorId': authorId,
      if (authorName != null) 'authorName': authorName,
      'upvotes': upvotes,
      'downvotes': downvotes,
      if (forkedFromId != null) 'forkedFromId': forkedFromId,
      'createdAt': createdAt,
      'myVote': myVote,
    };
  }
}
