import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import '../widgets/social_widgets.dart';
import 'challenge_detail_screen.dart';
import 'courses_screen.dart';
import 'create_content_sheets.dart';

/// MOD_01 — Biblioteca. Dos fuentes de contenido (SRS §1.1): Oficial (FARO_DEV)
/// y Comunidad (creadores), más los Cursos (RF-09).
class LibraryScreen extends StatefulWidget {
  final Function(int targetTab, {String? challengeId})? onNavigateToTab;

  const LibraryScreen({super.key, this.onNavigateToTab});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ArticleModel>> _articlesFuture;
  String _tab = 'official'; // official | community | courses
  String _sort = 'top';

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles() {
    setState(() {
      _articlesFuture = _apiService.getArticles(
        source: _tab == 'community' ? 'community' : 'official',
        sort: _sort,
      );
    });
  }

  Future<void> _vote(ArticleModel article, int value) async {
    try {
      final updated = await _apiService.voteArticle(article.id, value);
      setState(() {
        article
          ..upvotes = updated.upvotes
          ..downvotes = updated.downvotes
          ..myVote = updated.myVote;
      });
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.phosphorGreen,
      backgroundColor: AppTheme.darkSilicon,
      onRefresh: () async => _loadArticles(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModuleHeader(
            title: 'MOD_01 // BIBLIOTECA DIGITAL & HISTORIA',
            subtitle: _tab == 'official'
                ? 'Contenido oficial de Dev Hub: el legado de los pioneros y sus algoritmos.'
                : _tab == 'community'
                    ? 'Artículos escritos por la comunidad. Lo mejor votado aparece arriba.'
                    : 'Cursos oficiales y de creadores: lecturas y retos en orden.',
            action: _tab == 'community'
                ? TerminalButton(
                    label: 'PUBLICAR',
                    icon: Icons.add,
                    onPressed: () async {
                      if (await showCreateArticleSheet(context)) _loadArticles();
                    },
                  )
                : null,
          ),
          const SizedBox(height: 12),
          ChoiceChipsRow(
            options: const ['official', 'community', 'courses'],
            labels: const ['Oficial', 'Comunidad', 'Cursos'],
            selected: _tab,
            onSelected: (v) {
              _tab = v;
              if (v != 'courses') _loadArticles();
              setState(() {});
            },
          ),
          if (_tab == 'community') ...[
            const SizedBox(height: 8),
            ChoiceChipsRow(
              options: const ['top', 'new'],
              labels: const ['Top', 'Recientes'],
              selected: _sort,
              onSelected: (v) {
                _sort = v;
                _loadArticles();
              },
            ),
          ],
          const SizedBox(height: 16),
          if (_tab == 'courses')
            const CoursesView()
          else
            FutureBuilder<List<ArticleModel>>(
              future: _articlesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen)),
                  );
                }
                final articles = snapshot.data ?? [];
                if (articles.isEmpty) {
                  return EmptyState(
                    icon: Icons.auto_stories_outlined,
                    message: _apiService.isOfflineMode
                        ? '// El contenido de la comunidad necesita conexión con el servidor.'
                        : '// Aún no hay artículos de la comunidad. ¡Publica el primero!',
                  );
                }
                return Column(children: articles.map(_buildDatasheetCard).toList());
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDatasheetCard(ArticleModel article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.circuitTrace, width: 1),
      ),
      child: Stack(
        children: [
          // Puntos decorativos en las esquinas simulando pines dorados
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: AppTheme.solderGold, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: AppTheme.solderGold, shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SourceBadge(
                      isOfficial: article.isOfficial,
                      authorId: article.authorId,
                      authorName: article.authorName,
                    ),
                    if (article.era.isNotEmpty)
                      Text(
                        '[ERA: ${article.era}]',
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 11,
                          color: AppTheme.solderGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.boneWhite,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.summary,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.greenishGray,
                    height: 1.4,
                    fontFamily: 'sans-serif',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!article.isOfficial)
                      VoteBar(
                        score: article.score,
                        myVote: article.myVote,
                        onVote: (v) => _vote(article, v),
                      )
                    else if (article.pioneerName.isNotEmpty)
                      Expanded(
                        child: Text(
                          'PIONERO: ${article.pioneerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 11,
                            color: AppTheme.phosphorGreen,
                          ),
                        ),
                      ),
                    if (!article.isOfficial || article.pioneerName.isEmpty) const Spacer(),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () => showArticleSheet(
                        context,
                        article,
                        onNavigateToTab: widget.onNavigateToTab,
                      ),
                      child: const Text(
                        'LEER ARCHIVO >',
                        style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lector de artículo (oficial o de comunidad). Si tiene reto vinculado muestra
/// "Pon en práctica su legado" (RF-02, Happy Path).
void showArticleSheet(
  BuildContext context,
  ArticleModel article, {
  Function(int targetTab, {String? challengeId})? onNavigateToTab,
  bool allowPractice = true,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.solderMask,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      side: BorderSide(color: AppTheme.circuitTrace, width: 1),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.circuitTrace,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SourceBadge(
                            isOfficial: article.isOfficial,
                            authorId: article.authorId,
                            authorName: article.authorName,
                          ),
                          if (article.era.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSilicon,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.solderGold),
                              ),
                              child: Text(
                                '[DATASHEET // ${article.era}]',
                                style: const TextStyle(
                                  fontFamily: AppTheme.monoFont,
                                  fontSize: 11,
                                  color: AppTheme.solderGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.greenishGray),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.boneWhite,
                    height: 1.3,
                  ),
                ),
                if (article.pioneerName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'PIONERO/A: ${article.pioneerName.toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 12,
                      color: AppTheme.phosphorGreen,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
                const Divider(height: 28),
                Text(
                  article.content,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.6,
                    color: AppTheme.boneWhite,
                    fontFamily: 'sans-serif',
                  ),
                ),
                const SizedBox(height: 28),

                // BOTÓN HAPPY PATH: "Pon en práctica su legado ->"
                if (allowPractice && article.relatedChallengeId.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.phosphorGreen.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.phosphorGreen,
                        foregroundColor: AppTheme.solderMask,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (onNavigateToTab != null) {
                          onNavigateToTab(1, challengeId: article.relatedChallengeId);
                        } else {
                          Navigator.push(
                            context,
                            MaterialUrlRoute(
                              builder: (_) => ChallengeDetailScreen(challengeId: article.relatedChallengeId),
                            ),
                          );
                        }
                      },
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          const Icon(Icons.terminal_rounded, size: 20),
                          Text(
                            article.isOfficial ? 'PON EN PRÁCTICA SU LEGADO ->' : 'PRACTICAR EL RETO ->',
                            style: const TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}

class MaterialUrlRoute<T> extends MaterialPageRoute<T> {
  MaterialUrlRoute({required super.builder});
}
