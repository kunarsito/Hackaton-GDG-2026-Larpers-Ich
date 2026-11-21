/// Artículo de la Biblioteca (oficial o de comunidad). Sincronizado con `Article` (models.ts).
class ArticleModel {
  final String id;
  final String title;
  final String pioneerName;
  final String era;
  final String summary;
  final String content;
  final String relatedChallengeId;
  final String source; // 'official' | 'community'
  final String? authorId;
  final String? authorName;
  int upvotes;
  int downvotes;
  final String createdAt;
  int myVote; // 1, -1 o 0

  ArticleModel({
    required this.id,
    required this.title,
    required this.pioneerName,
    required this.era,
    required this.summary,
    required this.content,
    required this.relatedChallengeId,
    this.source = 'official',
    this.authorId,
    this.authorName,
    this.upvotes = 0,
    this.downvotes = 0,
    this.createdAt = '',
    this.myVote = 0,
  });

  bool get isOfficial => source == 'official';
  int get score => upvotes - downvotes;

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pioneerName: json['pioneerName'] as String? ?? '',
      era: json['era'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
      relatedChallengeId: json['relatedChallengeId'] as String? ?? '',
      source: json['source'] as String? ?? 'official',
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      myVote: (json['myVote'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pioneerName': pioneerName,
      'era': era,
      'summary': summary,
      'content': content,
      'relatedChallengeId': relatedChallengeId,
      'source': source,
      if (authorId != null) 'authorId': authorId,
      if (authorName != null) 'authorName': authorName,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'createdAt': createdAt,
      'myVote': myVote,
    };
  }
}
