import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/challenge_model.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import '../widgets/social_widgets.dart';
import 'challenge_detail_screen.dart';
import 'create_content_sheets.dart';

class PracticeScreen extends StatefulWidget {
  final Function(String challengeId)? onOpenChallenge;
  final Function(String challengeTitle, String codeSnippet)? onNavigateToCommunity;

  const PracticeScreen({
    super.key,
    this.onOpenChallenge,
    this.onNavigateToCommunity,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ChallengeModel>> _challengesFuture;
  String _selectedDifficulty = 'Todos';
  String _source = 'official'; // official | community (SRS §1.1)
  String _sort = 'top';

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  void _loadChallenges() {
    setState(() {
      _challengesFuture = _apiService.getChallenges(source: _source, sort: _sort);
    });
  }

  Future<void> _vote(ChallengeModel challenge, int value) async {
    try {
      final updated = await _apiService.voteChallenge(challenge.id, value);
      setState(() {
        challenge
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
    return FutureBuilder<List<ChallengeModel>>(
      future: _challengesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.phosphorGreen),
          );
        }

        final allChallenges = snapshot.data ?? [];
        final filtered = _selectedDifficulty == 'Todos'
            ? allChallenges
            : allChallenges.where((c) => c.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase()).toList();

        return RefreshIndicator(
          color: AppTheme.phosphorGreen,
          backgroundColor: AppTheme.darkSilicon,
          onRefresh: () async => _loadChallenges(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header de Zona de Práctica
              ModuleHeader(
                title: 'MOD_02 // ZONA DE PRÁCTICA INTERACTIVA',
                subtitle: _source == 'official'
                    ? 'Retos oficiales con casos de prueba (< 2s): +10 Karma Técnico cada uno.'
                    : 'Retos creados por la comunidad: +5 Karma cada uno. Vota, haz fork o crea el tuyo.',
                color: AppTheme.solderGold,
                action: TerminalButton(
                  label: 'CREAR RETO',
                  icon: Icons.add,
                  color: AppTheme.solderGold,
                  onPressed: () async {
                    if (await showCreateChallengeSheet(context)) {
                      _source = 'community';
                      _sort = 'new';
                      _loadChallenges();
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              ChoiceChipsRow(
                options: const ['official', 'community'],
                labels: const ['Oficial', 'Comunidad'],
                selected: _source,
                onSelected: (v) {
                  _source = v;
                  _loadChallenges();
                },
              ),
              if (_source == 'community') ...[
                const SizedBox(height: 8),
                ChoiceChipsRow(
                  options: const ['top', 'new'],
                  labels: const ['Top', 'Recientes'],
                  selected: _sort,
                  onSelected: (v) {
                    _sort = v;
                    _loadChallenges();
                  },
                ),
              ],
              const SizedBox(height: 8),

              // Selector de Dificultad (Chips con bordes verdes y dorados)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todos', 'Básico', 'Intermedio', 'Avanzado'].map((diff) {
                    final isSelected = _selectedDifficulty == diff;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          diff.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.solderMask : AppTheme.boneWhite,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.phosphorGreen,
                        backgroundColor: AppTheme.darkSilicon,
                        side: BorderSide(
                          color: isSelected ? AppTheme.phosphorGreen : AppTheme.circuitTrace,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedDifficulty = diff);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Lista de Retos
              if (filtered.isEmpty)
                EmptyState(
                  icon: Icons.code_off_rounded,
                  message: _apiService.isOfflineMode && _source == 'community'
                      ? '// Los retos de la comunidad necesitan conexión con el servidor.'
                      : '// No hay retos con este filtro. ¡Crea uno!',
                ),
              ...filtered.map((challenge) {
                final isSolved = _apiService.currentUser.solvedChallenges.contains(challenge.id);
                return _buildChallengeCard(context, challenge, isSolved);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    ChallengeModel challenge,
    bool isSolved,
  ) {
    Color badgeColor;
    if (challenge.difficulty.toLowerCase().contains('básic') || challenge.difficulty.toLowerCase().contains('basic')) {
      badgeColor = AppTheme.phosphorGreen;
    } else if (challenge.difficulty.toLowerCase().contains('inter')) {
      badgeColor = AppTheme.solderGold;
    } else {
      badgeColor = AppTheme.alertRed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSolved ? AppTheme.phosphorGreen : AppTheme.circuitTrace,
          width: isSolved ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          if (widget.onOpenChallenge != null) {
            widget.onOpenChallenge!(challenge.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengeDetailScreen(
                  challengeId: challenge.id,
                  onNavigateToCommunity: widget.onNavigateToCommunity,
                ),
              ),
            ).then((_) => setState(() {}));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  SourceBadge(
                    isOfficial: challenge.isOfficial,
                    authorId: challenge.authorId,
                    authorName: challenge.authorName,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: badgeColor, width: 0.8),
                    ),
                    child: Text(
                      'DIFF: ${challenge.difficulty.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  if (isSolved)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.phosphorGreen),
                        const SizedBox(width: 4),
                        Text(
                          '[RESUELTO +${challenge.karmaReward}K]',
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.phosphorGreen,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '[PENDIENTE: +${challenge.karmaReward}K]',
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 10,
                        color: AppTheme.greenishGray,
                      ),
                    ),
                  if (challenge.forkedFromId != null)
                    const Text(
                      '[FORK]',
                      style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 10, color: AppTheme.greenishGray),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                challenge.title,
                style: const TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.boneWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'CATEGORÍA: ${challenge.category}',
                style: const TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 11,
                  color: AppTheme.greenishGray,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  VoteBar(
                    score: challenge.score,
                    myVote: challenge.myVote,
                    allowDownvote: !challenge.isOfficial, // §1.1: lo oficial no se vota negativo
                    onVote: (v) => _vote(challenge, v),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Fork: crea tu propia versión de este reto',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () async {
                        if (await showCreateChallengeSheet(context, forkOf: challenge)) {
                          _source = 'community';
                          _sort = 'new';
                          _loadChallenges();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.call_split_rounded, size: 16, color: AppTheme.greenishGray),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${challenge.testCases.length} casos',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        color: AppTheme.greenishGray,
                      ),
                    ),
                  ),
                  const Text(
                    'ABRIR CONSOLA >',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.phosphorGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
