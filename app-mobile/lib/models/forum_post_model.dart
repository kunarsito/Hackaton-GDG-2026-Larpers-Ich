import 'attachment_model.dart';

/// Respuesta en un hilo. Sincronizado con `ForumReply` (models.ts).
class ForumReply {
  final String id;
  final String? authorId;
  final String authorName;
  final String body;
  final String createdAt;
  int upvotes;

  ForumReply({
    required this.id,
    this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.upvotes = 0,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    return ForumReply(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String? ?? 'Anónimo',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? 'Ahora',
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (authorId != null) 'authorId': authorId,
      'authorName': authorName,
      'body': body,
      'createdAt': createdAt,
      'upvotes': upvotes,
    };
  }
}

/// Publicación del feed de Comunidad (RF-11). Sincronizado con `ForumPost` (models.ts).
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
  final String createdAt;
  final String type; // post | question | challenge | course | snippet | article
  int downvotes;
  final List<AttachmentModel> attachments;
  int savedCount;
  final String? forkedFromId;
  String? acceptedReplyId;
  final String? refId;
  int myVote;
  bool isSaved;

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
    this.createdAt = 'Ahora',
    this.type = 'post',
    this.downvotes = 0,
    this.attachments = const [],
    this.savedCount = 0,
    this.forkedFromId,
    this.acceptedReplyId,
    this.refId,
    this.myVote = 0,
    this.isSaved = false,
  });

  int get score => upvotes - downvotes;

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
      createdAt: json['createdAt'] as String? ?? 'Ahora',
      type: json['type'] as String? ?? 'post',
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      attachments: AttachmentModel.listFromJson(json['attachments']),
      savedCount: (json['savedCount'] as num?)?.toInt() ?? 0,
      forkedFromId: json['forkedFromId'] as String?,
      acceptedReplyId: json['acceptedReplyId'] as String?,
      refId: json['refId'] as String?,
      myVote: (json['myVote'] as num?)?.toInt() ?? 0,
      isSaved: json['isSaved'] as bool? ?? false,
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
      'createdAt': createdAt,
      'type': type,
      'downvotes': downvotes,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'savedCount': savedCount,
      if (forkedFromId != null) 'forkedFromId': forkedFromId,
      if (acceptedReplyId != null) 'acceptedReplyId': acceptedReplyId,
      if (refId != null) 'refId': refId,
      'myVote': myVote,
      'isSaved': isSaved,
    };
  }
}
