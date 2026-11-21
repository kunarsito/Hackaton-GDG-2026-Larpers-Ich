/// Lección de un curso: enlaza un artículo o un reto. Sincronizado con `CourseLesson` (models.ts).
class CourseLesson {
  final int order;
  final String title;
  final String? articleId;
  final String? challengeId;

  CourseLesson({required this.order, required this.title, this.articleId, this.challengeId});

  factory CourseLesson.fromJson(Map<String, dynamic> json) => CourseLesson(
        order: (json['order'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        articleId: json['articleId'] as String?,
        challengeId: json['challengeId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'order': order,
        'title': title,
        if (articleId != null) 'articleId': articleId,
        if (challengeId != null) 'challengeId': challengeId,
      };
}

/// Curso oficial o de creador (RF-09). Sincronizado con `Course` (models.ts).
class CourseModel {
  final String id;
  final String source; // 'official' | 'community'
  final String? authorId;
  final String? authorName;
  final String title;
  final String description;
  final String? coverUrl;
  final String level;
  final List<String> tags;
  final List<CourseLesson> lessons;
  final double ratingAvg;
  final int ratingCount;
  final int enrolledCount;
  final String createdAt;
  final bool isEnrolled;
  final bool isCompleted;
  final int myRating;

  CourseModel({
    required this.id,
    required this.source,
    this.authorId,
    this.authorName,
    required this.title,
    required this.description,
    this.coverUrl,
    required this.level,
    this.tags = const [],
    this.lessons = const [],
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.enrolledCount = 0,
    this.createdAt = '',
    this.isEnrolled = false,
    this.isCompleted = false,
    this.myRating = 0,
  });

  bool get isOfficial => source == 'official';

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as String? ?? '',
        source: json['source'] as String? ?? 'community',
        authorId: json['authorId'] as String?,
        authorName: json['authorName'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        coverUrl: json['coverUrl'] as String?,
        level: json['level'] as String? ?? 'Básico',
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        lessons: (json['lessons'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(CourseLesson.fromJson)
                .toList() ??
            const [],
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        enrolledCount: (json['enrolledCount'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] as String? ?? '',
        isEnrolled: json['isEnrolled'] as bool? ?? false,
        isCompleted: json['isCompleted'] as bool? ?? false,
        myRating: (json['myRating'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        if (authorId != null) 'authorId': authorId,
        if (authorName != null) 'authorName': authorName,
        'title': title,
        'description': description,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'level': level,
        'tags': tags,
        'lessons': lessons.map((l) => l.toJson()).toList(),
        'ratingAvg': ratingAvg,
        'ratingCount': ratingCount,
        'enrolledCount': enrolledCount,
        'createdAt': createdAt,
        'isEnrolled': isEnrolled,
        'isCompleted': isCompleted,
        'myRating': myRating,
      };
}
