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

class ChallengeModel {
  final String id;
  final String title;
  final String difficulty; // 'Básico', 'Intermedio', 'Avanzado'
  final String category;
  final String description;
  final String starterCode;
  final List<TestCase> testCases;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.category,
    required this.description,
    required this.starterCode,
    required this.testCases,
  });

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
    };
  }
}
