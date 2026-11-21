import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/forum_post_model.dart';
import '../services/api_service.dart';
import '../widgets/code_block_view.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPosts();
    if (widget.initialPrefilledTitle != null ||
        widget.initialPrefilledCode != null) {
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
      _postsFuture = _apiService.getForumPosts();
    });
  }

  // Permite abrir el formulario de publicación desde el layout principal o internamente
  void openNewPostDialog({
    String? prefilledTitle,
    String? prefilledCode,
    String? challengeId,
  }) {
    final titleCtrl = TextEditingController(
      text: prefilledTitle != null
          ? 'Ayuda con solución para: $prefilledTitle'
          : '',
    );
    final bodyCtrl = TextEditingController(
      text: prefilledCode != null
          ? 'Hola comunidad, estoy intentando resolver este reto pero mis casos de prueba no pasan. ¿Alguien detecta el error en mi lógica?'
          : '',
    );
    final codeCtrl = TextEditingController(text: prefilledCode ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.solderMask,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.circuitTrace, width: 1),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note_rounded,
                        color: AppTheme.phosphorGreen),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'NUEVO HILO // FORO TÉCNICO',
                        style: TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.phosphorGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.close, color: AppTheme.greenishGray),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 16),
                const Text(
                  'TÍTULO DEL HILO:',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    color: AppTheme.greenishGray,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(
                    color: AppTheme.boneWhite,
                    fontFamily: AppTheme.monoFont,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.darkSilicon,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide:
                          const BorderSide(color: AppTheme.circuitTrace),
                    ),
                    hintText: 'Ej. Duda con matriz de adyacencia...',
                    hintStyle: const TextStyle(color: AppTheme.circuitTrace),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'DESCRIPCIÓN DE TU DUDA:',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    color: AppTheme.greenishGray,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                    color: AppTheme.boneWhite,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.darkSilicon,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide:
                          const BorderSide(color: AppTheme.circuitTrace),
                    ),
                    hintText: 'Explica qué intentaste o en qué línea falla...',
                    hintStyle: const TextStyle(color: AppTheme.circuitTrace),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SNIPPET DE CÓDIGO (PRECARGADO AUTOMÁTICAMENTE):',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    color: AppTheme.solderGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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
                      hintStyle: TextStyle(
                        color: AppTheme.circuitTrace,
                        fontFamily: AppTheme.monoFont,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.phosphorGreen,
                      foregroundColor: AppTheme.solderMask,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;

                      final newPost = ForumPostModel(
                        id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                        authorId: _apiService.currentUser.id,
                        authorName: _apiService.currentUser.name,
                        title: titleCtrl.text.trim(),
                        body: bodyCtrl.text.trim(),
                        codeSnippet: codeCtrl.text.trim(),
                        challengeId: challengeId,
                        replies: [],
                        upvotes: 1,
                      );

                      await _apiService.addForumPost(newPost);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _loadPosts();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppTheme.darkSilicon,
                              content: Text(
                                '[SYS_MSG]: Hilo publicado exitosamente. (+10 Karma)',
                                style: TextStyle(
                                  color: AppTheme.phosphorGreen,
                                  fontFamily: AppTheme.monoFont,
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'PUBLICAR EN LA COMUNIDAD (+10 KARMA)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPostRepliesModal(BuildContext context, ForumPostModel post) {
    final replyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.solderMask,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.circuitTrace, width: 1),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'HILO // ${post.authorName.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 12,
                              color: AppTheme.phosphorGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: AppTheme.greenishGray),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    // Todo el contenido del hilo es desplazable: así el campo de
                    // respuesta siempre cabe aunque el teclado esté abierto.
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
                          Text(
                            post.body,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.boneWhite,
                              height: 1.4,
                            ),
                          ),
                          if (post.codeSnippet.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            CodeBlockView(
                                code: post.codeSnippet, language: 'dart'),
                          ],
                          const Divider(height: 24),
                          const Text(
                            'RESPUESTAS DE LA COMUNIDAD:',
                            style: TextStyle(
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
                                '// No hay respuestas aún. Sé el primero en colaborar (+15 Karma).',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.monoFont,
                                  fontSize: 11,
                                  color: AppTheme.greenishGray,
                                ),
                              ),
                            )
                          else
                            ...post.replies.map(_buildReplyTile),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: replyCtrl,
                            style: const TextStyle(
                              color: AppTheme.boneWhite,
                              fontFamily: AppTheme.monoFont,
                              fontSize: 12,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.darkSilicon,
                              hintText: 'Aporta una solución o feedback...',
                              hintStyle: const TextStyle(
                                color: AppTheme.circuitTrace,
                                fontSize: 11,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                    color: AppTheme.circuitTrace),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.phosphorGreen,
                            foregroundColor: AppTheme.solderMask,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          onPressed: () async {
                            if (replyCtrl.text.trim().isEmpty) return;
                            final newRep = ForumReply(
                              id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
                              authorName: _apiService.currentUser.name,
                              body: replyCtrl.text.trim(),
                              createdAt: 'Ahora',
                            );
                            replyCtrl.clear();
                            await _apiService.addReplyToPost(post.id, newRep);
                            if (!mounted) return;
                            setModalState(() {});
                            setState(() {});
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
        );
      },
    );
  }

  Widget _buildReplyTile(ForumReply rep) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.circuitTrace),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '@${rep.authorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    color: AppTheme.solderGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rep.createdAt,
                style: const TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 10,
                  color: AppTheme.greenishGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rep.body,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.boneWhite,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ForumPostModel>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.phosphorGreen),
          );
        }

        final posts = snapshot.data ?? [];

        return RefreshIndicator(
          color: AppTheme.phosphorGreen,
          backgroundColor: AppTheme.darkSilicon,
          onRefresh: () async => _loadPosts(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header de Sección Foro Técnico
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkSilicon,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.circuitTrace),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.phosphorGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOD_03 // COMUNIDAD TÉCNICA & REPUTACIÓN',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.phosphorGreen,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Comparte código, desbloquea dudas y gana Karma Técnico resolviendo bloqueos.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.greenishGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.phosphorGreen,
                        foregroundColor: AppTheme.solderMask,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => openNewPostDialog(),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'CREAR HILO',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ...posts.map((post) => _buildPostCard(post)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostCard(ForumPostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.circuitTrace, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.solderGold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '@${post.authorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 11,
                      color: AppTheme.solderGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (post.challengeId != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1511),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.circuitTrace),
                      ),
                      child: Text(
                        '[RETO: ${post.challengeId}]',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 10,
                          color: AppTheme.greenishGray,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.title,
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.boneWhite,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.body,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.greenishGray,
                height: 1.4,
              ),
            ),
            if (post.codeSnippet.isNotEmpty) ...[
              const SizedBox(height: 10),
              CodeBlockView(
                code: post.codeSnippet,
                language: 'dart',
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Upvote button
                InkWell(
                  onTap: () async {
                    await _apiService.upvotePost(post.id);
                    if (mounted) setState(() {});
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSiliconDeep,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.circuitTrace),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: AppTheme.phosphorGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.upvotes} UPVOTES',
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.phosphorGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  onPressed: () => _showPostRepliesModal(context, post),
                  child: Text(
                    'RESPUESTAS (${post.replies.length}) >',
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 10,
                    ),
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
