import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/article_model.dart';
import '../models/challenge_model.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import '../widgets/social_widgets.dart';

/// Formularios para que los creadores publiquen contenido en el espacio
/// Comunidad (RF-09, RF-10). Devuelven true si se publicó algo.

Widget _submitButton(String label, bool busy, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.phosphorGreen,
        foregroundColor: AppTheme.solderMask,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.solderMask),
            )
          : Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
    ),
  );
}

Widget _errorText(String? error) => error == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(error, style: const TextStyle(color: AppTheme.alertRed, fontSize: 12.5)),
      );

const _textStyle = TextStyle(color: AppTheme.boneWhite, fontSize: 13);

// ---------------------------------------------------------------------------
// Artículo de comunidad
// ---------------------------------------------------------------------------

Future<bool> showCreateArticleSheet(BuildContext context) async {
  if (!requireOnline(context)) return false;
  final api = ApiService();
  final title = TextEditingController();
  final summary = TextEditingController();
  final content = TextEditingController();
  final pioneer = TextEditingController();
  final era = TextEditingController();
  String? challengeId;
  String? error;
  var busy = false;

  final myChallenges = await api.getChallenges(source: 'community', authorId: api.currentUser.id);
  if (!context.mounted) return false;

  final result = await showTerminalSheet<bool>(
    context,
    title: 'NUEVO ARTÍCULO // COMUNIDAD',
    icon: Icons.article_outlined,
    builder: (ctx, setSheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('TÍTULO:'),
        TextField(
            controller: title, style: _textStyle, decoration: terminalInput('Ej. Recursión explicada con dominós')),
        const FieldLabel('RESUMEN (APARECE EN LA TARJETA):'),
        TextField(controller: summary, maxLines: 2, style: _textStyle, decoration: terminalInput('Una o dos frases')),
        const FieldLabel('CONTENIDO:'),
        TextField(
            controller: content,
            minLines: 5,
            maxLines: 12,
            style: _textStyle,
            decoration: terminalInput('Escribe tu artículo...')),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('PERSONAJE / TEMA (OPCIONAL):'),
                  TextField(controller: pioneer, style: _textStyle, decoration: terminalInput('Ej. Alan Turing')),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('ÉPOCA (OPCIONAL):'),
                  TextField(controller: era, style: _textStyle, decoration: terminalInput('Ej. 1912 - 1954')),
                ],
              ),
            ),
          ],
        ),
        const FieldLabel('RETO VINCULADO (OPCIONAL, DE TUS RETOS):'),
        DropdownButtonFormField<String?>(
          initialValue: challengeId,
          dropdownColor: AppTheme.darkSilicon,
          style: _textStyle,
          isExpanded: true,
          decoration: terminalInput(''),
          items: [
            const DropdownMenuItem(value: null, child: Text('Sin reto')),
            ...myChallenges
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.title, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) => setSheet(() => challengeId = v),
        ),
        _errorText(error),
        const SizedBox(height: 16),
        _submitButton('PUBLICAR ARTÍCULO', busy, () async {
          if (title.text.trim().isEmpty || summary.text.trim().isEmpty || content.text.trim().isEmpty) {
            setSheet(() => error = 'Título, resumen y contenido son obligatorios.');
            return;
          }
          setSheet(() {
            busy = true;
            error = null;
          });
          try {
            await api.createArticle(
              title: title.text.trim(),
              summary: summary.text.trim(),
              content: content.text.trim(),
              pioneerName: pioneer.text.trim(),
              era: era.text.trim(),
              relatedChallengeId: challengeId ?? '',
            );
            if (ctx.mounted) Navigator.pop(ctx, true);
          } catch (e) {
            setSheet(() {
              busy = false;
              error = e.toString();
            });
          }
        }),
      ],
    ),
  );
  if (result == true && context.mounted) showSysSnack(context, 'Artículo publicado en Comunidad.');
  return result == true;
}

// ---------------------------------------------------------------------------
// Reto de comunidad (también para "fork" de un reto existente)
// ---------------------------------------------------------------------------

class _CaseRow {
  final input = TextEditingController();
  final expected = TextEditingController();
  final description = TextEditingController();
}

Future<bool> showCreateChallengeSheet(BuildContext context, {ChallengeModel? forkOf}) async {
  if (!requireOnline(context)) return false;
  final api = ApiService();
  final title = TextEditingController(text: forkOf != null ? '${forkOf.title} (fork)' : '');
  final category = TextEditingController(text: forkOf?.category ?? '');
  final description = TextEditingController(text: forkOf?.description ?? '');
  final starter = TextEditingController(
    text: forkOf?.starterCode ?? 'int miFuncion(int n) {\n  // Tu lógica aquí\n  return 0;\n}\n',
  );
  var difficulty = forkOf?.difficulty ?? 'Básico';
  final cases = <_CaseRow>[];
  for (final tc in forkOf?.testCases ?? <TestCase>[]) {
    final row = _CaseRow();
    row.input.text = tc.input;
    row.expected.text = tc.expectedOutput;
    row.description.text = tc.description;
    cases.add(row);
  }
  if (cases.isEmpty) cases.add(_CaseRow());
  String? error;
  var busy = false;

  final result = await showTerminalSheet<bool>(
    context,
    title: forkOf != null ? 'FORK DE RETO // ${forkOf.title.toUpperCase()}' : 'NUEVO RETO // COMUNIDAD',
    icon: forkOf != null ? Icons.call_split_rounded : Icons.code_rounded,
    builder: (ctx, setSheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('TÍTULO:'),
        TextField(controller: title, style: _textStyle, decoration: terminalInput('Ej. Invertir una palabra')),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('DIFICULTAD:'),
                  DropdownButtonFormField<String>(
                    initialValue: difficulty,
                    dropdownColor: AppTheme.darkSilicon,
                    style: _textStyle,
                    decoration: terminalInput(''),
                    items: const ['Básico', 'Intermedio', 'Avanzado']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setSheet(() => difficulty = v ?? 'Básico'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('CATEGORÍA:'),
                  TextField(controller: category, style: _textStyle, decoration: terminalInput('Ej. Strings')),
                ],
              ),
            ),
          ],
        ),
        const FieldLabel('ENUNCIADO:'),
        TextField(
            controller: description,
            minLines: 3,
            maxLines: 8,
            style: _textStyle,
            decoration: terminalInput('Explica qué debe hacer la función y da un ejemplo')),
        const FieldLabel('CÓDIGO BASE (DART). EL VALIDADOR LLAMA A LA PRIMERA FUNCIÓN:'),
        Container(
          height: 140,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.darkSiliconDeep,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.circuitTrace),
          ),
          child: TextField(
            controller: starter,
            maxLines: null,
            expands: true,
            style: AppTheme.codeTextStyle.copyWith(fontSize: 12),
            cursorColor: AppTheme.phosphorGreen,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        const FieldLabel('CASOS DE PRUEBA (ENTRADA = LITERAL DART, p. ej. [1, 2] o "texto"):'),
        for (var i = 0; i < cases.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: cases[i].input,
                    style: AppTheme.codeTextStyle.copyWith(fontSize: 12),
                    decoration: terminalInput('Entrada ${i + 1}'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: cases[i].expected,
                    style: AppTheme.codeTextStyle.copyWith(fontSize: 12),
                    decoration: terminalInput('Salida'),
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar caso',
                  icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppTheme.alertRed),
                  onPressed: cases.length == 1 ? null : () => setSheet(() => cases.removeAt(i)),
                ),
              ],
            ),
          ),
        if (cases.length < 10)
          TextButton.icon(
            onPressed: () => setSheet(() => cases.add(_CaseRow())),
            icon: const Icon(Icons.add, size: 16, color: AppTheme.phosphorGreen),
            label: const Text('Agregar caso', style: TextStyle(color: AppTheme.phosphorGreen)),
          ),
        _errorText(error),
        const SizedBox(height: 12),
        _submitButton(forkOf != null ? 'PUBLICAR FORK' : 'PUBLICAR RETO', busy, () async {
          final testCases = cases
              .where((c) => c.input.text.trim().isNotEmpty || c.expected.text.trim().isNotEmpty)
              .map((c) => TestCase(
                    input: c.input.text.trim(),
                    expectedOutput: c.expected.text.trim(),
                    description: c.description.text.trim(),
                  ))
              .toList();
          if (title.text.trim().isEmpty || description.text.trim().isEmpty || testCases.isEmpty) {
            setSheet(() => error = 'Título, enunciado y al menos un caso de prueba son obligatorios.');
            return;
          }
          setSheet(() {
            busy = true;
            error = null;
          });
          try {
            await api.createChallenge(
              title: title.text.trim(),
              difficulty: difficulty,
              category: category.text.trim().isEmpty ? 'General' : category.text.trim(),
              description: description.text.trim(),
              starterCode: starter.text,
              testCases: testCases,
              forkedFromId: forkOf?.id,
            );
            if (ctx.mounted) Navigator.pop(ctx, true);
          } catch (e) {
            setSheet(() {
              busy = false;
              error = e.toString();
            });
          }
        }),
      ],
    ),
  );
  if (result == true && context.mounted) showSysSnack(context, 'Reto publicado en Comunidad.');
  return result == true;
}

// ---------------------------------------------------------------------------
// Curso (lecciones = artículos o retos, propios u oficiales)
// ---------------------------------------------------------------------------

Future<bool> showCreateCourseSheet(BuildContext context) async {
  if (!requireOnline(context)) return false;
  final api = ApiService();
  final title = TextEditingController();
  final description = TextEditingController();
  final tags = TextEditingController();
  var level = 'Básico';
  final lessons = <CourseLesson>[];
  String? error;
  var busy = false;

  // Contenido disponible para las lecciones: lo propio primero, luego lo oficial.
  final results = await Future.wait([
    api.getArticles(authorId: api.currentUser.id),
    api.getArticles(source: 'official'),
    api.getChallenges(authorId: api.currentUser.id),
    api.getChallenges(source: 'official'),
  ]);
  final articles = [...results[0] as List<ArticleModel>, ...results[1] as List<ArticleModel>];
  final challenges = [...results[2] as List<ChallengeModel>, ...results[3] as List<ChallengeModel>];
  if (!context.mounted) return false;

  final result = await showTerminalSheet<bool>(
    context,
    title: 'NUEVO CURSO // CREADOR',
    icon: Icons.school_outlined,
    builder: (ctx, setSheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('TÍTULO DEL CURSO:'),
        TextField(controller: title, style: _textStyle, decoration: terminalInput('Ej. Grafos desde cero')),
        const FieldLabel('DESCRIPCIÓN:'),
        TextField(
            controller: description,
            minLines: 2,
            maxLines: 5,
            style: _textStyle,
            decoration: terminalInput('¿Qué aprenderán?')),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('NIVEL:'),
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    dropdownColor: AppTheme.darkSilicon,
                    style: _textStyle,
                    decoration: terminalInput(''),
                    items: const ['Básico', 'Intermedio', 'Avanzado']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setSheet(() => level = v ?? 'Básico'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('ETIQUETAS (SEPARADAS POR COMA):'),
                  TextField(controller: tags, style: _textStyle, decoration: terminalInput('grafos, dart')),
                ],
              ),
            ),
          ],
        ),
        FieldLabel('LECCIONES (${lessons.length}):'),
        if (lessons.isEmpty)
          const Text(
            'Agrega artículos y retos en el orden en que se deben estudiar.',
            style: TextStyle(color: AppTheme.greenishGray, fontSize: 12),
          ),
        for (var i = 0; i < lessons.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.darkSilicon,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.circuitTrace),
            ),
            child: Row(
              children: [
                Icon(
                  lessons[i].articleId != null ? Icons.auto_stories_outlined : Icons.code_rounded,
                  size: 16,
                  color: AppTheme.phosphorGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${i + 1}. ${lessons[i].title}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.boneWhite, fontSize: 12.5),
                  ),
                ),
                InkWell(
                  onTap: () => setSheet(() => lessons.removeAt(i)),
                  child: const Icon(Icons.close, size: 16, color: AppTheme.alertRed),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            _AddLessonButton(
              label: '+ Artículo',
              icon: Icons.auto_stories_outlined,
              items: articles.map((a) => (a.id, a.title, a.isOfficial)).toList(),
              onPicked: (id, label) =>
                  setSheet(() => lessons.add(CourseLesson(order: lessons.length + 1, title: label, articleId: id))),
            ),
            _AddLessonButton(
              label: '+ Reto',
              icon: Icons.code_rounded,
              items: challenges.map((c) => (c.id, c.title, c.isOfficial)).toList(),
              onPicked: (id, label) =>
                  setSheet(() => lessons.add(CourseLesson(order: lessons.length + 1, title: label, challengeId: id))),
            ),
          ],
        ),
        _errorText(error),
        const SizedBox(height: 12),
        _submitButton('PUBLICAR CURSO', busy, () async {
          if (title.text.trim().isEmpty || description.text.trim().isEmpty || lessons.isEmpty) {
            setSheet(() => error = 'Título, descripción y al menos una lección son obligatorios.');
            return;
          }
          setSheet(() {
            busy = true;
            error = null;
          });
          try {
            await api.createCourse(
              title: title.text.trim(),
              description: description.text.trim(),
              level: level,
              tags: tags.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
              lessons: [
                for (var i = 0; i < lessons.length; i++)
                  CourseLesson(
                    order: i + 1,
                    title: lessons[i].title,
                    articleId: lessons[i].articleId,
                    challengeId: lessons[i].challengeId,
                  ),
              ],
            );
            if (ctx.mounted) Navigator.pop(ctx, true);
          } catch (e) {
            setSheet(() {
              busy = false;
              error = e.toString();
            });
          }
        }),
      ],
    ),
  );
  if (result == true && context.mounted) showSysSnack(context, 'Curso publicado.');
  return result == true;
}

class _AddLessonButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<(String, String, bool)> items; // id, título, oficial
  final void Function(String id, String title) onPicked;

  const _AddLessonButton({
    required this.label,
    required this.icon,
    required this.items,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<(String, String)>(
      color: AppTheme.darkSilicon,
      tooltip: label,
      enabled: items.isNotEmpty,
      onSelected: (v) => onPicked(v.$1, v.$2),
      itemBuilder: (_) => items
          .map((it) => PopupMenuItem(
                value: (it.$1, it.$2),
                child: Text(
                  '${it.$3 ? '[OFICIAL] ' : ''}${it.$2}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.boneWhite, fontSize: 12.5),
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.phosphorGreen),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.phosphorGreen),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppTheme.phosphorGreen, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
