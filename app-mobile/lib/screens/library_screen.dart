import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import 'challenge_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  final Function(int targetTab, {String? challengeId})? onNavigateToTab;

  const LibraryScreen({super.key, this.onNavigateToTab});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ArticleModel>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles() {
    setState(() {
      _articlesFuture = _apiService.getArticles();
    });
  }

  void _showArticleDetailModal(BuildContext context, ArticleModel article) {
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(1, challengeId: article.relatedChallengeId);
                        } else {
                          Navigator.push(
                            context,
                            MaterialUrlRoute(
                              builder: (_) => ChallengeDetailScreen(
                                challengeId: article.relatedChallengeId,
                                onNavigateToCommunity: (title, code) {
                                  if (widget.onNavigateToTab != null) {
                                    widget.onNavigateToTab!(2);
                                  }
                                },
                              ),
                            ),
                          );
                        }
                      },
                      child: const Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Icon(Icons.terminal_rounded, size: 20),
                          Text(
                            'PON EN PRÁCTICA SU LEGADO ->',
                            style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ArticleModel>>(
      future: _articlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.phosphorGreen),
          );
        }

        final articles = snapshot.data ?? [];

        return RefreshIndicator(
          color: AppTheme.phosphorGreen,
          backgroundColor: AppTheme.darkSilicon,
          onRefresh: () async => _loadArticles(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header de Sección Estilo Chip de Memoria ROM
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
                            'MOD_01 // BIBLIOTECA DIGITAL & HISTORIA',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.phosphorGreen,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Explora el legado y ejecuta los algoritmos que fundaron la computación.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.greenishGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ...articles.map((article) {
                return _buildDatasheetCard(article);
              }),
            ],
          ),
        );
      },
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
              decoration: const BoxDecoration(
                color: AppTheme.solderGold,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppTheme.solderGold,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '[ERA: ${article.era}]',
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        color: AppTheme.solderGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1511),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: AppTheme.circuitTrace),
                      ),
                      child: const Text(
                        'IC-BIO',
                        style: TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 10,
                          color: AppTheme.greenishGray,
                        ),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
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
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () => _showArticleDetailModal(context, article),
                      child: const Text(
                        'LEER ARCHIVO >',
                        style: TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 11,
                        ),
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

class MaterialUrlRoute<T> extends MaterialPageRoute<T> {
  MaterialUrlRoute({required super.builder});
}
