import '../models/article_model.dart';
import '../models/attachment_model.dart';
import '../models/challenge_model.dart';
import '../models/course_model.dart';
import '../models/forum_post_model.dart';
import '../models/job_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Endpoints de la red social (SRS §5.2, RF-09 a RF-18).
/// Lanzan [ApiException]; las pantallas muestran el mensaje del servidor.
extension SocialApi on ApiService {
  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) =>
      data is List ? data.whereType<Map<String, dynamic>>().map(fromJson).toList() : <T>[];

  // --- Perfiles (RF-15) y talento (RF-13, RF-17) ---

  Future<UserModel> getUserProfile(String id) async =>
      UserModel.fromJson(await request('GET', '/users/$id') as Map<String, dynamic>);

  /// [sort] 'karma' | 'new'; [role] 'creator' | 'recruiter'.
  Future<List<UserModel>> searchUsers({
    String sort = 'karma',
    String? role,
    String? q,
    String? skill,
    String? university,
    bool openToWorkOnly = false,
    int limit = 20,
  }) async {
    final data = await request('GET', '/users', query: {
      'sort': sort,
      'role': role ?? '',
      'q': q ?? '',
      'skill': skill ?? '',
      'university': university ?? '',
      'openToWork': openToWorkOnly ? 'true' : '',
      'limit': '$limit',
    });
    return _list(data, UserModel.fromJson);
  }

  /// PATCH /users/me — sólo los campos enviados. Actualiza el usuario actual.
  Future<UserModel> updateMyProfile(Map<String, dynamic> changes) async {
    final data = await request('PATCH', '/users/me', body: changes);
    applyServerUser(data);
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UserModel> setFollow(String userId, bool follow) async {
    final data = await request(follow ? 'POST' : 'DELETE', '/users/$userId/follow');
    await refreshCurrentUser();
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<UserModel>> getFollowList(String userId, {required bool followers}) async {
    final data = await request('GET', '/users/$userId/${followers ? 'followers' : 'following'}');
    return _list(data, UserModel.fromJson);
  }

  // --- Contenido de creadores (RF-09, RF-10) ---

  Future<ArticleModel> createArticle({
    required String title,
    required String summary,
    required String content,
    String pioneerName = '',
    String era = '',
    String relatedChallengeId = '',
  }) async {
    final data = await request('POST', '/articles', body: {
      'title': title,
      'summary': summary,
      'content': content,
      'pioneerName': pioneerName,
      'era': era,
      'relatedChallengeId': relatedChallengeId,
    });
    await refreshCurrentUser();
    return ArticleModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ChallengeModel> createChallenge({
    required String title,
    required String difficulty,
    required String category,
    required String description,
    required String starterCode,
    required List<TestCase> testCases,
    String? forkedFromId,
  }) async {
    final data = await request('POST', '/challenges', body: {
      'title': title,
      'difficulty': difficulty,
      'category': category,
      'description': description,
      'starterCode': starterCode,
      'testCases': testCases.map((t) => t.toJson()).toList(),
      if (forkedFromId != null) 'forkedFromId': forkedFromId,
    });
    await refreshCurrentUser();
    return ChallengeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ArticleModel> voteArticle(String id, int value) async => ArticleModel.fromJson(
      await request('POST', '/articles/$id/vote', body: {'value': value}) as Map<String, dynamic>);

  Future<ChallengeModel> voteChallenge(String id, int value) async => ChallengeModel.fromJson(
      await request('POST', '/challenges/$id/vote', body: {'value': value}) as Map<String, dynamic>);

  // --- Cursos (RF-09) ---

  Future<List<CourseModel>> getCourses({
    String? source,
    String sort = 'top',
    String? authorId,
    bool enrolledOnly = false,
  }) async {
    final data = await request('GET', '/courses', query: {
      'source': source ?? '',
      'sort': sort,
      'authorId': authorId ?? '',
      'enrolled': enrolledOnly ? 'me' : '',
    });
    return _list(data, CourseModel.fromJson);
  }

  Future<CourseModel> getCourse(String id) async =>
      CourseModel.fromJson(await request('GET', '/courses/$id') as Map<String, dynamic>);

  Future<CourseModel> createCourse({
    required String title,
    required String description,
    required String level,
    required List<String> tags,
    required List<CourseLesson> lessons,
  }) async {
    final data = await request('POST', '/courses', body: {
      'title': title,
      'description': description,
      'level': level,
      'tags': tags,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    });
    await refreshCurrentUser();
    return CourseModel.fromJson(data as Map<String, dynamic>);
  }

  /// Edita un curso propio (mismos campos que al crearlo).
  Future<CourseModel> updateCourse(
    String id, {
    required String title,
    required String description,
    required String level,
    required List<String> tags,
    required List<CourseLesson> lessons,
  }) async {
    final data = await request('PATCH', '/courses/$id', body: {
      'title': title,
      'description': description,
      'level': level,
      'tags': tags,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    });
    return CourseModel.fromJson(data as Map<String, dynamic>);
  }

  /// Borra un curso propio (y su anuncio en el feed).
  Future<void> deleteCourse(String id) async {
    await request('DELETE', '/courses/$id');
  }

  Future<CourseModel> enrollCourse(String id) async =>
      CourseModel.fromJson(await request('POST', '/courses/$id/enroll') as Map<String, dynamic>);

  /// Devuelve el curso y los puntos otorgados al creador.
  Future<(CourseModel, int)> completeCourse(String id) async {
    final data = await request('POST', '/courses/$id/complete') as Map<String, dynamic>;
    return (
      CourseModel.fromJson(data['course'] as Map<String, dynamic>),
      (data['karmaAwarded'] as num?)?.toInt() ?? 0,
    );
  }

  Future<CourseModel> rateCourse(String id, int rating) async => CourseModel.fromJson(
      await request('POST', '/courses/$id/rate', body: {'rating': rating}) as Map<String, dynamic>);

  // --- Comunidad (RF-11) ---

  Future<ForumPostModel> toggleSavePost(String id) async =>
      ForumPostModel.fromJson(await request('POST', '/posts/$id/save') as Map<String, dynamic>);

  Future<ForumPostModel> forkPost(String id, {String? title, String? body, String? codeSnippet}) async {
    final data = await request('POST', '/posts/$id/fork', body: {
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (codeSnippet != null) 'codeSnippet': codeSnippet,
    }) as Map<String, dynamic>;
    applyServerUser(data['user']);
    return ForumPostModel.fromJson(data['post'] as Map<String, dynamic>);
  }

  Future<ForumPostModel> acceptReply(String postId, String replyId) async =>
      ForumPostModel.fromJson(await request('POST', '/posts/$postId/replies/$replyId/accept') as Map<String, dynamic>);

  // --- Mensajes privados (RF-16) ---

  Future<List<ConversationModel>> getConversations() async =>
      _list(await request('GET', '/conversations'), ConversationModel.fromJson);

  Future<int> getUnreadCount() async {
    final data = await request('GET', '/conversations/unread', timeout: const Duration(seconds: 4));
    return (data is Map ? (data['count'] as num?)?.toInt() : null) ?? 0;
  }

  Future<ConversationModel> openConversation(String userId) async => ConversationModel.fromJson(
      await request('POST', '/conversations', body: {'userId': userId}) as Map<String, dynamic>);

  Future<List<MessageModel>> getMessages(String conversationId, {String? after}) async => _list(
      await request('GET', '/conversations/$conversationId/messages', query: {'after': after ?? ''}),
      MessageModel.fromJson);

  Future<MessageModel> sendMessage(
    String conversationId,
    String body, {
    List<AttachmentModel> attachments = const [],
  }) async =>
      MessageModel.fromJson(await request('POST', '/conversations/$conversationId/messages', body: {
        'body': body,
        'attachments': attachments.map((a) => a.id).toList(),
      }) as Map<String, dynamic>);

  // --- Empleo y CV (RF-17) ---

  Future<JobOpportunityModel> createJob({
    required String title,
    required String companyOrPoster,
    required String type,
    required String modality,
    required String description,
    List<String> requirements = const [],
    String contactUrl = '',
  }) async {
    final data = await request('POST', '/jobs', body: {
      'title': title,
      'companyOrPoster': companyOrPoster,
      'type': type,
      'modality': modality,
      'description': description,
      'requirements': requirements,
      'contactUrl': contactUrl,
    });
    await refreshCurrentUser();
    return JobOpportunityModel.fromJson(data as Map<String, dynamic>);
  }

  Future<JobApplicationModel> applyToJob(String jobId, {String message = '', String? cvUrl}) async =>
      JobApplicationModel.fromJson(await request('POST', '/jobs/$jobId/apply', body: {
        'message': message,
        if (cvUrl != null) 'cvUrl': cvUrl,
      }) as Map<String, dynamic>);

  Future<List<JobApplicationModel>> getJobApplications(String jobId) async =>
      _list(await request('GET', '/jobs/$jobId/applications'), JobApplicationModel.fromJson);

  Future<List<JobApplicationModel>> getMyApplications() async =>
      _list(await request('GET', '/jobs/applications/mine'), JobApplicationModel.fromJson);

  Future<JobApplicationModel> setApplicationStatus(String jobId, String appId, String status) async =>
      JobApplicationModel.fromJson(
          await request('PATCH', '/jobs/$jobId/applications/$appId', body: {'status': status}) as Map<String, dynamic>);

  // --- Karma (RF-14) ---

  Future<int> remainingGiftToday() async {
    final data = await request('GET', '/karma/gift');
    return (data is Map ? (data['remainingToday'] as num?)?.toInt() : null) ?? 0;
  }

  /// Regala [amount] puntos. Devuelve el perfil actualizado de quien los recibe.
  Future<UserModel> giftKarma(String toUserId, int amount) async {
    final data =
        await request('POST', '/karma/gift', body: {'toUserId': toUserId, 'amount': amount}) as Map<String, dynamic>;
    applyServerUser(data['user']);
    return UserModel.fromJson(data['recipient'] as Map<String, dynamic>);
  }
}
