import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/challenge_model.dart';
import '../services/api_service.dart';
import 'challenge_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  void _loadChallenges() {
    setState(() {
      _challengesFuture = _apiService.getChallenges();
    });
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
            : allChallenges
                .where((c) =>
                    c.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase())
                .toList();

        return RefreshIndicator(
          color: AppTheme.phosphorGreen,
          backgroundColor: AppTheme.darkSilicon,
          onRefresh: () async => _loadChallenges(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header de Zona de Práctica
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
                        color: AppTheme.solderGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOD_02 // ZONA DE PRÁCTICA INTERACTIVA',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.solderGold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Resuelve algoritmos con casos de prueba (< 2s) y acumula +50 Karma Técnico.',
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
                            color: isSelected
                                ? AppTheme.solderMask
                                : AppTheme.boneWhite,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.phosphorGreen,
                        backgroundColor: AppTheme.darkSilicon,
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.phosphorGreen
                              : AppTheme.circuitTrace,
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
              ...filtered.map((challenge) {
                final isSolved = _apiService.currentUser.solvedChallenges
                    .contains(challenge.id);
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
    if (challenge.difficulty.toLowerCase().contains('básic') ||
        challenge.difficulty.toLowerCase().contains('basic')) {
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
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: AppTheme.phosphorGreen),
                        SizedBox(width: 4),
                        Text(
                          '[RESUELTO +50K]',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.phosphorGreen,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      '[PENDIENTE: +50K]',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 10,
                        color: AppTheme.greenishGray,
                      ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${challenge.testCases.length} Casos de prueba',
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 11,
                      color: AppTheme.greenishGray,
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
