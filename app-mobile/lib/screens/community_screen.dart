import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/attachment_model.dart';
import '../models/forum_post_model.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import '../widgets/code_block_view.dart';
import '../widgets/social_widgets.dart';
import 'challenge_detail_screen.dart';
import 'courses_screen.dart';
import 'library_screen.dart';

/// MOD_03 — Comunidad: feed estilo Facebook + GitHub (RF-11, RF-12, RF-13, RF-14).
class CommunityScreen extends StatefulWidget {
  final String? initialPrefilledTitle;
  final String? initialPrefilledCode;
  final String? initialChallengeId;

  const CommunityScreen({
    super.key,
    this.initialPrefilledTitle,
    this.initialPrefilledCode,
    this.initialChallengeId,
  });

  @override
  State<CommunityScreen> createState() => CommunityScreenState();
}

class CommunityScreenState extends State<CommunityScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ForumPostModel>> _postsFuture;
  String _filter = 'top'; // top | new | saved

  @override
  void initState() {
    super.initState();
    _loadPosts();
    if (widget.initialPrefilledTitle != null || widget.initialPrefilledCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openNewPostDialog(
          prefilledTitle: widget.initialPrefilledTitle,
          prefilledCode: widget.initialPrefilledCode,
          challengeId: widget.initialChallengeId,
        );
      });
    }
  }

  void _loadPosts() {
    setState(() {
      _postsFuture = _apiService.getForumPosts(
        sort: _filter == 'new' ? 'new' : 'top',
        savedOnly: _filter == 'saved',
      );
    });
  }

  // Permite abrir el formulario de publicación desde el layout principal o internamente
  void openNewPostDialog({String? prefilledTitle, String? prefilledCode, String? challengeId}) {
    showNewPostSheet(
      context,
      prefilledTitle: prefilledTitle,
      prefilledCode: prefilledCode,
      challengeId: challengeId,
    ).then((published) {
      if (published == true) _loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ForumPostModel>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return RefreshIndicator(
          color: AppTheme.phosphorGreen,
          backgroundColor: AppTheme.darkSilicon,
          onRefresh: () async => _loadPosts(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ModuleHeader(
                title: 'MOD_03 // COMUNIDAD TÉCNICA & REPUTACIÓN',
                subtitle: 'Publica código y archivos, vota lo mejor, haz fork y gana Karma Técnico.',
                action: TerminalButton(
                  label: 'CREAR',
                  icon: Icons.add,
                  onPressed: () => openNewPostDialog(),
                ),
              ),
              const SizedBox(height: 12),
              ChoiceChipsRow(
                options: const ['top', 'new', 'saved'],
                labels: const ['Top', 'Recientes', 'Guardados'],
                selected: _filter,
                onSelected: (v) {
                  _filter = v;
                  _loadPosts();
                },
              ),
              const SizedBox(height: 14),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen)),
                )
              else if (posts.isEmpty)
                EmptyState(
                  message: _filter == 'saved'
                      ? '// Aún no guardas publicaciones. Usa la estrella para guardarlas.'
                      : '// No hay publicaciones todavía. ¡Sé el primero!',
                  icon: _filter == 'saved' ? Icons.star_border_rounded : Icons.forum_outlined,
                )
              else
                ...posts.map((post) => PostCard(
                      key: ValueKey('${post.id}-${post.score}-${post.replies.length}'),
                      post: post,
                      onForked: _loadPosts,
                    )),
            ],
          ),
        );
      },
    );
  }
}

/// Formulario de nueva publicación con adjuntos (máx. 4). Devuelve true si se publicó.
Future<bool?> showNewPostSheet(
  BuildContext context, {
  String? prefilledTitle,
  String? prefilledCode,
  String? challengeId, // vincula la pregunta al reto de origen ("Pedir ayuda en el foro")
}) {
  final api = ApiService();
  final titleCtrl = TextEditingController(
    text: prefilledTitle != null ? 'Ayuda con solución para: $prefilledTitle' : '',
  );
  final bodyCtrl = TextEditingController(
    text: prefilledCode != null
        ? 'Hola comunidad, estoy intentando resolver este reto pero mis casos de prueba no pasan. ¿Alguien detecta el error en mi lógica?'
        : '',
  );
  final codeCtrl = TextEditingController(text: prefilledCode ?? '');
  final attachments = <AttachmentModel>[];
  var isQuestion = prefilledCode != null;
  var busy = false;
  String? error;

  return showTerminalSheet<bool>(
    context,
    title: 'NUEVA PUBLICACIÓN // COMUNIDAD',
    icon: Icons.edit_note_rounded,
    builder: (ctx, setSheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceChipsRow(
          options: const ['post', 'question'],
          labels: const ['Publicación', 'Pregunta'],
          selected: isQuestion ? 'question' : 'post',
          onSelected: (v) => setSheet(() => isQuestion = v == 'question'),
        ),
        const FieldLabel('TÍTULO:'),
        TextField(
          controller: titleCtrl,
          style: const TextStyle(color: AppTheme.boneWhite, fontFamily: AppTheme.monoFont, fontSize: 13),
          decoration: terminalInput('Ej. Duda con matriz de adyacencia...'),
        ),
        const FieldLabel('DESCRIPCIÓN:'),
        TextField(
          controller: bodyCtrl,
          maxLines: 4,
          style: const TextStyle(color: AppTheme.boneWhite, fontSize: 13),
          decoration: terminalInput('Cuenta qué hiciste, qué intentaste o qué compartes...'),
        ),
        FieldLabel(prefilledCode != null
            ? 'SNIPPET DE CÓDIGO (PRECARGADO AUTOMÁTICAMENTE):'
            : 'SNIPPET DE CÓDIGO (OPCIONAL):'),
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: AppTheme.darkSiliconDeep,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.circuitTrace),
          ),
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: codeCtrl,
            maxLines: null,
            expands: true,
            style: AppTheme.codeTextStyle.copyWith(fontSize: 12),
            cursorColor: AppTheme.phosphorGreen,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '// Pega tu código aquí...',
              hintStyle: TextStyle(color: AppTheme.circuitTrace, fontFamily: AppTheme.monoFont),
            ),
          ),
        ),
        const FieldLabel('ARCHIVOS (IMÁGENES, PDF, ZIP, CÓDIGO · MÁX. 4 DE 10 MB):'),
        AttachmentList(
          attachments: attachments,
          onRemove: (a) => setSheet(() => attachments.remove(a)),
        ),
        if (attachments.length < 4)
          TextButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final added = await pickAndUploadFiles(ctx, maxFiles: 4 - attachments.length);
                    setSheet(() => attachments.addAll(added));
                  },
            icon: const Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.phosphorGreen),
            label: const Text('Adjuntar archivo', style: TextStyle(color: AppTheme.phosphorGreen)),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: const TextStyle(color: AppTheme.alertRed, fontSize: 12.5)),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.phosphorGreen,
              foregroundColor: AppTheme.solderMask,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: busy
                ? null
                : () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      setSheet(() => error = 'Escribe un título.');
                      return;
                    }
                    setSheet(() {
                      busy = true;
                      error = null;
                    });
                    final newPost = ForumPostModel(
                      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                      authorId: api.currentUser.id,
                      authorName: api.currentUser.name,
                      title: titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim(),
                      codeSnippet: codeCtrl.text.trim(),
                      challengeId: challengeId,
                      replies: [],
                      upvotes: 0,
                      type: isQuestion ? 'question' : 'post',
                      attachments: List.of(attachments),
                    );
                    try {
                      await api.addForumPost(newPost);
                      if (ctx.mounted) Navigator.pop(ctx, true);
                      if (context.mounted) showSysSnack(context, 'Publicado exitosamente. (+10 Karma)');
                    } catch (e) {
                      setSheet(() {
                        busy = false;
                        error = e.toString();
                      });
                    }
                  },
            child: const Text(
              'PUBLICAR EN LA COMUNIDAD (+10 KARMA)',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Tarjeta de publicación del feed. Se actualiza en el lugar al votar/guardar.
class PostCard extends StatefulWidget {
  final ForumPostModel post;
  final VoidCallback? onForked;

  const PostCard({super.key, required this.post, this.onForked});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final ApiService _api = ApiService();
  late ForumPostModel _post = widget.post;

  Future<void> _vote(int value) async {
    try {
      final updated = await _api.votePost(_post.id, value);
      if (updated != null && mounted) setState(() => _post = updated);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _toggleSave() async {
    if (!requireOnline(context)) return;
    try {
      final updated = await _api.toggleSavePost(_post.id);
      if (mounted) {
        setState(() => _post = updated);
        showSysSnack(context, updated.isSaved ? 'Guardado en tu perfil.' : 'Quitado de guardados.');
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _fork() async {
    if (!requireOnline(context)) return;
    final codeCtrl = TextEditingController(text: _post.codeSnippet);
    final noteCtrl = TextEditingController();
    final ok = await showTerminalSheet<bool>(
      context,
      title: 'FORK // ${_post.title.toUpperCase()}',
      icon: Icons.call_split_rounded,
      builder: (ctx, setSheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crea tu propia versión del código de @${_post.authorName}. Quedará enlazada al original.',
            style: const TextStyle(color: AppTheme.greenishGray, fontSize: 12.5),
          ),
          const FieldLabel('¿QUÉ MEJORASTE?'),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            style: const TextStyle(color: AppTheme.boneWhite, fontSize: 13),
            decoration: terminalInput('Ej. Usé un PriorityQueue para bajar la complejidad'),
          ),
          const FieldLabel('TU CÓDIGO:'),
          Container(
            height: 180,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.darkSiliconDeep,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.circuitTrace),
            ),
            child: TextField(
              controller: codeCtrl,
              maxLines: null,
              expands: true,
              style: AppTheme.codeTextStyle.copyWith(fontSize: 12),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.phosphorGreen,
                foregroundColor: AppTheme.solderMask,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.call_split_rounded, size: 18),
              label: const Text('PUBLICAR FORK',
                  style: TextStyle(fontFamily: AppTheme.monoFont, fontWeight: FontWeight.bold)),
              onPressed: () async {
                try {
                  await _api.forkPost(
                    _post.id,
                    codeSnippet: codeCtrl.text,
                    body: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) showApiError(ctx, e);
                }
              },
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      showSysSnack(context, 'Fork publicado. (+10 Karma)');
      widget.onForked?.call();
    }
  }

  Future<void> _openRef() async {
    final ref = _post.refId;
    if (ref == null) return;
    switch (_post.type) {
      case 'challenge':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChallengeDetailScreen(challengeId: ref),
        ));
      case 'course':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CourseDetailScreen(courseId: ref),
        ));
      case 'article':
        final article = await _api.getArticleById(ref);
        if (article != null && mounted) showArticleSheet(context, article);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final typeLabel = switch (post.type) {
      'question' => 'PREGUNTA',
      'challenge' => 'RETO NUEVO',
      'course' => 'CURSO NUEVO',
      'article' => 'ARTÍCULO NUEVO',
      'snippet' => post.forkedFromId != null ? 'FORK' : 'SNIPPET',
      _ => null,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: post.acceptedReplyId != null ? AppTheme.phosphorGreen : AppTheme.circuitTrace,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => openProfile(context, post.authorId),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UserAvatar(name: post.authorName, size: 26),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${post.authorName}',
                            style: const TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 11,
                              color: AppTheme.solderGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            post.createdAt,
                            style: const TextStyle(fontSize: 10, color: AppTheme.greenishGray),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (typeLabel != null) _TypeBadge(typeLabel),
                if (post.challengeId != null && post.type == 'question') ...[
                  const SizedBox(width: 6),
                  _TypeBadge('RETO: ${post.challengeId}', subtle: true),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.boneWhite,
              ),
            ),
            if (post.body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                post.body,
                style: const TextStyle(fontSize: 12.5, color: AppTheme.greenishGray, height: 1.4),
              ),
            ],
            if (post.codeSnippet.isNotEmpty) ...[
              const SizedBox(height: 10),
              CodeBlockView(code: post.codeSnippet, language: 'dart'),
            ],
            if (post.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              AttachmentList(attachments: post.attachments),
            ],
            if (post.refId != null && post.type != 'post') ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openRef,
                icon: Icon(
                  post.type == 'course'
                      ? Icons.school_outlined
                      : post.type == 'article'
                          ? Icons.auto_stories_outlined
                          : Icons.terminal_rounded,
                  size: 16,
                ),
                label: Text(
                  post.type == 'course'
                      ? 'VER CURSO >'
                      : post.type == 'article'
                          ? 'LEER ARTÍCULO >'
                          : 'RESOLVER RETO >',
                  style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 11),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                VoteBar(score: post.score, myVote: post.myVote, onVote: _vote),
                _IconCount(
                  icon: post.isSaved ? Icons.star_rounded : Icons.star_border_rounded,
                  count: post.savedCount,
                  color: post.isSaved ? AppTheme.solderGold : AppTheme.greenishGray,
                  tooltip: post.isSaved ? 'Quitar de guardados' : 'Guardar',
                  onTap: _toggleSave,
                ),
                if (post.codeSnippet.isNotEmpty)
                  _IconCount(
                    icon: Icons.call_split_rounded,
                    label: 'FORK',
                    color: AppTheme.greenishGray,
                    tooltip: 'Crear tu versión del código',
                    onTap: _fork,
                  ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  onPressed: () async {
                    final updated = await showPostThreadSheet(context, post);
                    if (updated != null && mounted) setState(() => _post = updated);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (post.acceptedReplyId != null) ...[
                        const Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.phosphorGreen),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'RESPUESTAS (${post.replies.length}) >',
                        style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final bool subtle;
  const _TypeBadge(this.label, {this.subtle = false});

  @override
  Widget build(BuildContext context) {
    final color = subtle ? AppTheme.greenishGray : AppTheme.phosphorGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: subtle ? const Color(0xFF0F1511) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: subtle ? AppTheme.circuitTrace : color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 9.5, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _IconCount extends StatelessWidget {
  final IconData icon;
  final int? count;
  final String? label;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconCount({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.count,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.darkSiliconDeep,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.circuitTrace),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              if (count != null || label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label ?? '$count',
                  style: TextStyle(
                      fontFamily: AppTheme.monoFont, fontSize: 10.5, color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Hilo con respuestas. El autor puede marcar una como solución (+15 Karma a quien respondió).
/// Devuelve la publicación actualizada (o null si no cambió).
Future<ForumPostModel?> showPostThreadSheet(BuildContext context, ForumPostModel initial) {
  final api = ApiService();
  final replyCtrl = TextEditingController();
  var post = initial;
  var changed = false;
  var sending = false;

  return showModalBottomSheet<ForumPostModel?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.solderMask,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      side: BorderSide(color: AppTheme.circuitTrace, width: 1),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) {
        final isAuthor = post.authorId == api.currentUser.id;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'HILO // ${post.authorName.toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 12,
                          color: AppTheme.phosphorGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.greenishGray),
                      onPressed: () => Navigator.pop(ctx, changed ? post : null),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.boneWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(post.body, style: const TextStyle(fontSize: 13, color: AppTheme.boneWhite, height: 1.4)),
                      if (post.codeSnippet.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        CodeBlockView(code: post.codeSnippet, language: 'dart'),
                      ],
                      if (post.attachments.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        AttachmentList(attachments: post.attachments),
                      ],
                      const Divider(height: 24),
                      Text(
                        isAuthor && post.acceptedReplyId == null
                            ? 'RESPUESTAS · MARCA LA QUE TE AYUDÓ (+15 KARMA A SU AUTOR):'
                            : 'RESPUESTAS DE LA COMUNIDAD:',
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 11,
                          color: AppTheme.greenishGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (post.replies.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '// No hay respuestas aún. Si tu respuesta se marca como solución ganas +15 Karma.',
                            style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 11, color: AppTheme.greenishGray),
                          ),
                        ),
                      ...post.replies.map((rep) {
                        final accepted = rep.id == post.acceptedReplyId;
                        final canAccept = isAuthor &&
                            post.acceptedReplyId == null &&
                            rep.authorId != null &&
                            rep.authorId != api.currentUser.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accepted ? AppTheme.phosphorGreen.withValues(alpha: 0.08) : AppTheme.darkSilicon,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: accepted ? AppTheme.phosphorGreen : AppTheme.circuitTrace),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  InkWell(
                                    onTap: rep.authorId == null ? null : () => openProfile(ctx, rep.authorId!),
                                    child: Text(
                                      '@${rep.authorName}',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.monoFont,
                                        fontSize: 11,
                                        color: AppTheme.solderGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (accepted)
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.phosphorGreen),
                                        SizedBox(width: 3),
                                        Text(
                                          'SOLUCIÓN',
                                          style: TextStyle(
                                            fontFamily: AppTheme.monoFont,
                                            fontSize: 10,
                                            color: AppTheme.phosphorGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const Spacer(),
                                  Text(
                                    rep.createdAt,
                                    style: const TextStyle(
                                        fontFamily: AppTheme.monoFont, fontSize: 10, color: AppTheme.greenishGray),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(rep.body, style: const TextStyle(fontSize: 12.5, color: AppTheme.boneWhite)),
                              if (canAccept)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      if (!requireOnline(ctx)) return;
                                      try {
                                        final updated = await api.acceptReply(post.id, rep.id);
                                        setModal(() {
                                          post = updated;
                                          changed = true;
                                        });
                                        if (ctx.mounted) {
                                          showSysSnack(ctx, '@${rep.authorName} recibió +15 Karma.');
                                        }
                                      } catch (e) {
                                        if (ctx.mounted) showApiError(ctx, e);
                                      }
                                    },
                                    icon: const Icon(Icons.check_rounded, size: 15, color: AppTheme.phosphorGreen),
                                    label: const Text(
                                      'MARCAR SOLUCIÓN',
                                      style: TextStyle(
                                          fontFamily: AppTheme.monoFont, fontSize: 10, color: AppTheme.phosphorGreen),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyCtrl,
                        style: const TextStyle(color: AppTheme.boneWhite, fontFamily: AppTheme.monoFont, fontSize: 12),
                        decoration: terminalInput('Aporta una solución o feedback...'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.phosphorGreen,
                        foregroundColor: AppTheme.solderMask,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      onPressed: sending
                          ? null
                          : () async {
                              if (replyCtrl.text.trim().isEmpty) return;
                              setModal(() => sending = true);
                              final newRep = ForumReply(
                                id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
                                authorId: api.currentUser.id,
                                authorName: api.currentUser.name,
                                body: replyCtrl.text.trim(),
                                createdAt: 'Ahora',
                              );
                              try {
                                final updated = await api.addReplyToPost(post.id, newRep);
                                replyCtrl.clear();
                                setModal(() {
                                  if (updated != null) post = updated;
                                  changed = true;
                                  sending = false;
                                });
                              } catch (e) {
                                setModal(() => sending = false);
                                if (ctx.mounted) showApiError(ctx, e);
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    ),
  ).then((value) => value ?? (changed ? post : null));
}
