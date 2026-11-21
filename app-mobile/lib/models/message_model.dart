import 'attachment_model.dart';
import 'user_model.dart';

/// Conversación 1 a 1 (RF-16). Sincronizado con `Conversation` (models.ts).
class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String lastMessageAt;
  final int unreadCount;
  final UserSummaryModel otherUser;
  final String? lastMessage;

  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.otherUser,
    this.lastMessage,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
        id: json['id'] as String? ?? '',
        participantIds: (json['participantIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        lastMessageAt: json['lastMessageAt'] as String? ?? '',
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        otherUser: UserSummaryModel.fromJson(
            (json['otherUser'] as Map<String, dynamic>?) ?? const {'id': '', 'name': 'Usuario'}),
        lastMessage: json['lastMessage'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantIds': participantIds,
        'lastMessageAt': lastMessageAt,
        'unreadCount': unreadCount,
        'otherUser': otherUser.toJson(),
        if (lastMessage != null) 'lastMessage': lastMessage,
      };
}

/// Mensaje privado (RF-16). Sincronizado con `Message` (models.ts).
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final List<AttachmentModel> attachments;
  final String createdAt;
  final String? readAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.attachments,
    required this.createdAt,
    this.readAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String? ?? '',
        conversationId: json['conversationId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        body: json['body'] as String? ?? '',
        attachments: AttachmentModel.listFromJson(json['attachments']),
        createdAt: json['createdAt'] as String? ?? '',
        readAt: json['readAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'body': body,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'createdAt': createdAt,
        if (readAt != null) 'readAt': readAt,
      };
}

/// Movimiento de Karma (auditoría, RF-14). Sincronizado con `KarmaEvent` (models.ts).
class KarmaEventModel {
  final String id;
  final String userId;
  final int amount;
  final String reason;
  final String? fromUserId;
  final String createdAt;

  KarmaEventModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    this.fromUserId,
    required this.createdAt,
  });

  factory KarmaEventModel.fromJson(Map<String, dynamic> json) => KarmaEventModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String? ?? '',
        fromUserId: json['fromUserId'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'amount': amount,
        'reason': reason,
        if (fromUserId != null) 'fromUserId': fromUserId,
        'createdAt': createdAt,
      };
}
