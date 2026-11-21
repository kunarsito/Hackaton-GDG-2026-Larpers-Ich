import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/challenge_model.dart';
import '../services/api_service.dart';
import '../widgets/symbol_keyboard.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;
  final Function(String challengeTitle, String codeSnippet)? onNavigateToCommunity;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
    this.onNavigateToCommunity,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _codeController = TextEditingController();

  ChallengeModel? _challenge;
  bool _isLoading = true;
  bool _isValidating = false;
  Map<String, dynamic>? _lastValidationResult;

  @override
  void initState() {
    super.initState();
    _fetchChallenge();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchChallenge() async {
    final ch = await _apiService.getChallengeById(widget.challengeId);
    if (mounted) {
      setState(() {
        _challenge = ch;
        _codeController.text = ch?.starterCode ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _runCode() async {
    if (_challenge == null) return;
    setState(() {
      _isValidating = true;
      _lastValidationResult = null;
    });

    final res = await _apiService.validateCode(
      challengeId: _challenge!.id,
      code: _codeController.text,
    );

    if (mounted) {
      setState(() {
        _isValidating = false;
        _lastValidationResult = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.phosphorGreen),
        ),
      );
    }

    if (_challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ERROR // NO ENCONTRADO')),
        body: const Center(
          child: Text(
            'El reto solicitado no se encuentra disponible.',
            style: TextStyle(color: AppTheme.alertRed),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('EJECUCIÓN // ${_challenge!.id.toUpperCase()}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.darkSilicon,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.circuitTrace),
                ),
                child: Text(
                  'DIFF: ${_challenge!.difficulty.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    color: AppTheme.solderGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // --- LAYOUT WEB / ESCRITORIO (>= 600px): Vista dividida en 2 columnas ---
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Columna Izquierda: Enunciado y Casos de Prueba
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppTheme.circuitTrace, width: 1),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildChallengeInfoSection(),
                const SizedBox(height: 20),
                _buildTestCasesSection(),
              ],
            ),
          ),
        ),

        // Columna Derecha: Editor de Código + Consola de Salida
        Expanded(
          flex: 6,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  color: AppTheme.darkSiliconDeep,
                  padding: const EdgeInsets.all(16),
                  child: _buildCodeEditor(),
                ),
              ),
              _buildBottomActionConsole(),
            ],
          ),
        ),
      ],
    );
  }

  // --- LAYOUT MÓVIL (< 600px): Vista apilada con SymbolKeyboard visible ---
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChallengeInfoSection(),
              const SizedBox(height: 16),
              _buildTestCasesSection(),
              const SizedBox(height: 16),
              const Text(
                '// CONSOLA DE PROGRAMACIÓN (DART):',
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 11,
                  color: AppTheme.greenishGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: AppTheme.darkSiliconDeep,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.circuitTrace),
                ),
                padding: const EdgeInsets.all(12),
                child: _buildCodeEditor(),
              ),
            ],
          ),
        ),

        // Widget SymbolKeyboard justo encima de los controles táctiles
        SymbolKeyboard(
          controller: _codeController,
          onSymbolInserted: () => setState(() {}),
        ),

        _buildBottomActionConsole(),
      ],
    );
  }

  Widget _buildChallengeInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _challenge!.title,
          style: const TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.boneWhite,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'CATEGORÍA: ${_challenge!.category.toUpperCase()}',
          style: const TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 11,
            color: AppTheme.phosphorGreen,
          ),
        ),
        const Divider(height: 24),
        Text(
          _challenge!.description,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppTheme.boneWhite,
            height: 1.5,
            fontFamily: 'sans-serif',
          ),
        ),
      ],
    );
  }

  Widget _buildTestCasesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '// CASOS DE PRUEBA ESPERADOS:',
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 11,
            color: AppTheme.greenishGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._challenge!.testCases.map((tc) {
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
                Text(
                  'Aserción: ${tc.description}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.boneWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Input: ${tc.input}',
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        color: AppTheme.greenishGray,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Output: ${tc.expectedOutput}',
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        color: AppTheme.phosphorGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCodeEditor() {
    return TextField(
      controller: _codeController,
      maxLines: null,
      expands: true,
      style: AppTheme.codeTextStyle.copyWith(fontSize: 13),
      cursorColor: AppTheme.phosphorGreen,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: '// Escribe tu código aquí...',
        hintStyle: TextStyle(
          color: AppTheme.circuitTrace,
          fontFamily: AppTheme.monoFont,
        ),
      ),
    );
  }

  Widget _buildBottomActionConsole() {
    final hasResult = _lastValidationResult != null;
    final passed = hasResult && _lastValidationResult!['passed'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.darkSilicon,
        border: Border(
          top: BorderSide(color: AppTheme.circuitTrace, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Alerta de feedback si hubo validación
          if (hasResult) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: passed
                    ? AppTheme.phosphorGreen.withValues(alpha: 0.12)
                    : AppTheme.alertRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: passed ? AppTheme.phosphorGreen : AppTheme.alertRed,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    passed ? Icons.check_circle_rounded : Icons.bug_report_rounded,
                    color: passed ? AppTheme.phosphorGreen : AppTheme.alertRed,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passed
                              ? '[TEST_PASSED] ¡Solución correcta! (+50 Karma)'
                              : '[TEST_FAILED] Error de validación',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: passed ? AppTheme.phosphorGreen : AppTheme.alertRed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastValidationResult!['message'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.boneWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BOTÓN HAPPY PATH: "Pedir ayuda en el foro" cuando falla
            if (!passed)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.solderGold,
                    side: const BorderSide(color: AppTheme.solderGold, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (widget.onNavigateToCommunity != null) {
                      widget.onNavigateToCommunity!(
                        _challenge!.title,
                        _codeController.text,
                      );
                    }
                  },
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: const Text(
                    'PEDIR AYUDA EN EL FORO ->',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
          ],

          // Botón Ejecutar Pruebas
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.phosphorGreen,
                foregroundColor: AppTheme.solderMask,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isValidating ? null : _runCode,
              child: _isValidating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.solderMask,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'EJECUTAR PRUEBAS (< 2s)',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
