class ArticleModel {
  final String id;
  final String title;
  final String pioneerName;
  final String era;
  final String summary;
  final String content;
  final String relatedChallengeId;

  ArticleModel({
    required this.id,
    required this.title,
    required this.pioneerName,
    required this.era,
    required this.summary,
    required this.content,
    required this.relatedChallengeId,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pioneerName: json['pioneerName'] as String? ?? '',
      era: json['era'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
      relatedChallengeId: json['relatedChallengeId'] as String? ?? '',
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
    };
  }
}
