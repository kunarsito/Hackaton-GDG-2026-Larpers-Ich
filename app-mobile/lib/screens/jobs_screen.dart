import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<JobOpportunityModel>> _jobsFuture;
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    setState(() {
      _jobsFuture = _apiService.getJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<JobOpportunityModel>>(
      future: _jobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.phosphorGreen),
          );
        }

        final allJobs = snapshot.data ?? [];
        final filteredJobs = _selectedFilter == 'Todos'
            ? allJobs
            : allJobs
                .where((j) =>
                    j.type.toLowerCase() == _selectedFilter.toLowerCase())
                .toList();

        return RefreshIndicator(
          color: AppTheme.phosphorGreen,
          backgroundColor: AppTheme.darkSilicon,
          onRefresh: () async => _loadJobs(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header de Sección Bolsa de Trabajo
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
                            'MOD_04 // BOLSA DE TRABAJO COLABORATIVA',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.solderGold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Vacantes junior, pasantías y proyectos freelance para estudiantes.',
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

              // Filtros Horizontales (ChoiceChip)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todos', 'Pasantía', 'Junior', 'Freelance'].map((f) {
                    final isSelected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          f.toUpperCase(),
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
                            setState(() => _selectedFilter = f);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              ...filteredJobs.map((job) => _buildJobCard(job)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobCard(JobOpportunityModel job) {
    Color typeColor;
    if (job.type.toLowerCase().contains('pasant')) {
      typeColor = AppTheme.phosphorGreen;
    } else if (job.type.toLowerCase().contains('junior')) {
      typeColor = AppTheme.solderGold;
    } else {
      typeColor = const Color(0xFF64B5F6); // Azul claro para Freelance
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: typeColor, width: 0.8),
                  ),
                  child: Text(
                    job.type.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                Text(
                  '[MODALIDAD: ${job.modality.toUpperCase()}]',
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 10,
                    color: AppTheme.greenishGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.title,
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.boneWhite,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business_rounded, size: 14, color: AppTheme.greenishGray),
                const SizedBox(width: 4),
                Text(
                  job.companyOrPoster,
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    color: AppTheme.phosphorGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.greenishGray,
                height: 1.4,
                fontFamily: 'sans-serif',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ESTADO: ABIERTA',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 10,
                    color: AppTheme.phosphorGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.darkSilicon,
                        content: Text(
                          '[CANAL DE CONTACTO]: ${job.contactUrl}',
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFont,
                            color: AppTheme.phosphorGreen,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'POSTULARME >',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
