import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import '../widgets/social_widgets.dart';
import 'challenge_detail_screen.dart';
import 'create_content_sheets.dart';
import 'library_screen.dart';

/// RF-09: lista de cursos (oficiales y de creadores), ordenados por rating (RF-13).
class CoursesView extends StatefulWidget {
  const CoursesView({super.key});

  @override
  State<CoursesView> createState() => _CoursesViewState();
}

class _CoursesViewState extends State<CoursesView> {
  final ApiService _api = ApiService();
  String _filter = 'all'; // all | official | community | mine
  String _sort = 'top';
  Future<List<CourseModel>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _api
          .getCourses(
            source: _filter == 'official' || _filter == 'community' ? _filter : null,
            sort: _sort,
            enrolledOnly: _filter == 'mine',
          )
          .catchError((Object e) => <CourseModel>[]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ChoiceChipsRow(
                options: const ['all', 'official', 'community', 'mine'],
                labels: const ['Todos', 'Oficiales', 'Creadores', 'Inscrito'],
                selected: _filter,
                onSelected: (v) {
                  _filter = v;
                  _load();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChipsRow(
                options: const ['top', 'new'],
                labels: const ['Mejor valorados', 'Recientes'],
                selected: _sort,
                onSelected: (v) {
                  _sort = v;
                  _load();
                },
              ),
            ),
            TerminalButton(
              label: 'CREAR CURSO',
              icon: Icons.add,
              onPressed: () async {
                if (await showCreateCourseSheet(context)) _load();
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<CourseModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen)),
              );
            }
            final courses = snap.data ?? [];
            if (courses.isEmpty) {
              return EmptyState(
                icon: Icons.school_outlined,
                message: _api.isOfflineMode
                    ? '// Los cursos necesitan conexión con el servidor.'
                    : _filter == 'mine'
                        ? '// Aún no te inscribes a ningún curso.'
                        : '// No hay cursos aquí todavía. ¡Crea el primero!',
              );
            }
            return Column(
              children: courses
                  .map((c) => CourseCard(
                        course: c,
                        onChanged: _load,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class StarsRow extends StatelessWidget {
  final double value;
  final double size;
  final ValueChanged<int>? onRate;

  const StarsRow({super.key, required this.value, this.size = 14, this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = value >= i + 1;
        final half = !filled && value > i;
        final icon = Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_border_rounded,
          size: size,
          color: AppTheme.solderGold,
        );
        return onRate == null
            ? icon
            : InkWell(
                onTap: () => onRate!(i + 1),
                borderRadius: BorderRadius.circular(size),
                child: Padding(padding: const EdgeInsets.all(2), child: icon),
              );
      }),
    );
  }
}

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onChanged;

  const CourseCard({super.key, required this.course, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: course.isEnrolled ? AppTheme.phosphorGreen : AppTheme.circuitTrace,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)),
          );
          onChanged?.call();
        },
        child: Padding(
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
                    isOfficial: course.isOfficial,
                    authorId: course.authorId,
                    authorName: course.authorName,
                  ),
                  Text(
                    'NIVEL: ${course.level.toUpperCase()}',
                    style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 10, color: AppTheme.greenishGray),
                  ),
                  if (course.isCompleted)
                    const Text(
                      '[COMPLETADO]',
                      style: TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 10,
                          color: AppTheme.phosphorGreen,
                          fontWeight: FontWeight.bold),
                    )
                  else if (course.isEnrolled)
                    const Text(
                      '[INSCRITO]',
                      style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 10, color: AppTheme.phosphorGreen),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                course.title,
                style: const TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.boneWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                course.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppTheme.greenishGray, height: 1.4),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StarsRow(value: course.ratingAvg),
                      const SizedBox(width: 4),
                      Text(
                        course.ratingCount == 0 ? 'Sin calificar' : '${course.ratingAvg} (${course.ratingCount})',
                        style:
                            const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 10.5, color: AppTheme.solderGold),
                      ),
                    ],
                  ),
                  Text(
                    '${course.lessons.length} lecciones · ${course.enrolledCount} inscritos',
                    style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 10.5, color: AppTheme.greenishGray),
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

/// Detalle del curso: lecciones, inscripción, completar (+20 al creador) y calificar.
class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final ApiService _api = ApiService();
  CourseModel? _course;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _api.getCourse(widget.courseId);
      if (mounted) setState(() => _course = c);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!requireOnline(context)) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLesson(CourseLesson lesson) async {
    if (lesson.challengeId != null) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(challengeId: lesson.challengeId!),
      ));
      if (mounted) setState(() {}); // refresca "resuelto"
    } else if (lesson.articleId != null) {
      final article = await _api.getArticleById(lesson.articleId!);
      if (article != null && mounted) showArticleSheet(context, article, allowPractice: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      appBar: AppBar(title: const Text('CURSO')),
      body: course == null
          ? Center(
              child: _error != null
                  ? EmptyState(message: _error!, icon: Icons.error_outline)
                  : const CircularProgressIndicator(color: AppTheme.phosphorGreen),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SourceBadge(
                            isOfficial: course.isOfficial, authorId: course.authorId, authorName: course.authorName),
                        Text(
                          'NIVEL: ${course.level.toUpperCase()}',
                          style: const TextStyle(
                              fontFamily: AppTheme.monoFont, fontSize: 10.5, color: AppTheme.greenishGray),
                        ),
                        ...course.tags.map((t) => Text(
                              '#$t',
                              style: const TextStyle(
                                  fontFamily: AppTheme.monoFont, fontSize: 10.5, color: AppTheme.phosphorGreen),
                            )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      course.title,
                      style: const TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.boneWhite),
                    ),
                    const SizedBox(height: 8),
                    Text(course.description,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.boneWhite)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StarsRow(value: course.ratingAvg, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          course.ratingCount == 0
                              ? 'Sin calificar'
                              : '${course.ratingAvg} · ${course.ratingCount} calificaciones',
                          style:
                              const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 11, color: AppTheme.solderGold),
                        ),
                        const Spacer(),
                        Text(
                          '${course.enrolledCount} inscritos',
                          style: const TextStyle(
                              fontFamily: AppTheme.monoFont, fontSize: 11, color: AppTheme.greenishGray),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!course.isEnrolled)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.phosphorGreen,
                          foregroundColor: AppTheme.solderMask,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                  final c = await _api.enrollCourse(course.id);
                                  setState(() => _course = c);
                                  if (mounted) showSysSnack(this.context, 'Te inscribiste al curso.');
                                }),
                        icon: const Icon(Icons.how_to_reg_rounded),
                        label: const Text('INSCRIBIRME',
                            style: TextStyle(fontFamily: AppTheme.monoFont, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'LECCIONES:',
                      style: TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 11,
                          color: AppTheme.greenishGray,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...course.lessons.map((lesson) {
                      final isChallenge = lesson.challengeId != null;
                      final solved = isChallenge && _api.currentUser.solvedChallenges.contains(lesson.challengeId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSilicon,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: solved ? AppTheme.phosphorGreen : AppTheme.circuitTrace),
                        ),
                        child: ListTile(
                          onTap: () => _openLesson(lesson),
                          leading: Icon(
                            solved
                                ? Icons.check_circle_rounded
                                : isChallenge
                                    ? Icons.code_rounded
                                    : Icons.auto_stories_outlined,
                            color: solved ? AppTheme.phosphorGreen : AppTheme.solderGold,
                          ),
                          title: Text(
                            '${lesson.order}. ${lesson.title}',
                            style:
                                const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 13, color: AppTheme.boneWhite),
                          ),
                          subtitle: Text(
                            isChallenge ? 'Reto de práctica' : 'Lectura',
                            style: const TextStyle(fontSize: 11, color: AppTheme.greenishGray),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.greenishGray),
                        ),
                      );
                    }),
                    if (course.isEnrolled) ...[
                      const SizedBox(height: 12),
                      if (!course.isCompleted)
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                    final (c, karma) = await _api.completeCourse(course.id);
                                    setState(() => _course = c);
                                    if (mounted) {
                                      showSysSnack(
                                        this.context,
                                        karma > 0
                                            ? '¡Curso completado! El creador recibió +$karma Karma.'
                                            : '¡Curso completado!',
                                      );
                                    }
                                  }),
                          icon: const Icon(Icons.flag_rounded),
                          label: const Text('MARCAR CURSO COMO COMPLETADO',
                              style: TextStyle(fontFamily: AppTheme.monoFont)),
                        )
                      else
                        const Text(
                          '✔ Completaste este curso.',
                          style: TextStyle(fontFamily: AppTheme.monoFont, color: AppTheme.phosphorGreen),
                        ),
                      if (course.authorId != _api.currentUser.id) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'TU CALIFICACIÓN:',
                          style: TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 11,
                              color: AppTheme.greenishGray,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        StarsRow(
                          value: course.myRating.toDouble(),
                          size: 28,
                          onRate: _busy
                              ? null
                              : (r) => _run(() async {
                                    final c = await _api.rateCourse(course.id, r);
                                    setState(() => _course = c);
                                  }),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
