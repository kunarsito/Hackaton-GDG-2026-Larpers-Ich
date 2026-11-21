class ForumReply {
  final String id;
  final String authorName;
  final String body;
  final String createdAt;

  ForumReply({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    return ForumReply(
      id: json['id'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Anónimo',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? 'Ahora',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'body': body,
      'createdAt': createdAt,
    };
  }
}

class ForumPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String body;
  final String codeSnippet;
  final String? challengeId;
  final List<ForumReply> replies;
  int upvotes;

  ForumPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    required this.codeSnippet,
    this.challengeId,
    required this.replies,
    required this.upvotes,
  });

  factory ForumPostModel.fromJson(Map<String, dynamic> json) {
    var rawReplies = json['replies'];
    List<ForumReply> parsedReplies = [];
    if (rawReplies is List) {
      parsedReplies = rawReplies.map((r) {
        if (r is Map<String, dynamic>) {
          return ForumReply.fromJson(r);
        } else {
          return ForumReply(
            id: 'rep-${DateTime.now().microsecondsSinceEpoch}',
            authorName: 'Compañero',
            body: r.toString(),
            createdAt: 'Reciente',
          );
        }
      }).toList();
    }

    return ForumPostModel(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Estudiante Dev',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      codeSnippet: json['codeSnippet'] as String? ?? '',
      challengeId: json['challengeId'] as String?,
      replies: parsedReplies,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'body': body,
      'codeSnippet': codeSnippet,
      'challengeId': challengeId,
      'replies': replies.map((e) => e.toJson()).toList(),
      'upvotes': upvotes,
    };
  }
}
