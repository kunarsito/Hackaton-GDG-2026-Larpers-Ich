import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/attachment_model.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import '../widgets/social_widgets.dart';
import 'messages_screen.dart';
import 'talent_screen.dart';

/// MOD_04 — Bolsa de trabajo (RF-08) + canal de empleo con CV (RF-17).
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<JobOpportunityModel>> _jobsFuture;
  Future<List<JobApplicationModel>>? _myApplications;
  String _selectedFilter = 'Todos'; // Todos | Pasantía | Junior | Freelance | Mis vacantes | Mis postulaciones

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    setState(() {
      _jobsFuture = _apiService.getJobs();
      if (_selectedFilter == 'Mis postulaciones') {
        _myApplications = _apiService.getMyApplications().catchError((Object _) => <JobApplicationModel>[]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = _apiService.currentUser.id;
    return RefreshIndicator(
      color: AppTheme.phosphorGreen,
      backgroundColor: AppTheme.darkSilicon,
      onRefresh: () async => _loadJobs(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ModuleHeader(
            title: 'MOD_04 // BOLSA DE TRABAJO COLABORATIVA',
            subtitle: 'Postúlate con tu CV, publica vacantes y encuentra talento por Karma y habilidades.',
            color: AppTheme.solderGold,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TerminalButton(
                label: 'PUBLICAR VACANTE',
                icon: Icons.add_business_outlined,
                color: AppTheme.solderGold,
                onPressed: () async {
                  if (await showCreateJobSheet(context)) {
                    _selectedFilter = 'Mis vacantes';
                    _loadJobs();
                  }
                },
              ),
              TerminalButton(
                label: 'BUSCAR TALENTO',
                icon: Icons.person_search_outlined,
                color: const Color(0xFF64B5F6),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TalentScreen(initialTab: 'talent')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ChoiceChipsRow(
            options: const ['Todos', 'Pasantía', 'Junior', 'Freelance', 'Mis vacantes', 'Mis postulaciones'],
            selected: _selectedFilter,
            onSelected: (f) {
              _selectedFilter = f;
              _loadJobs();
            },
          ),
          const SizedBox(height: 16),
          if (_selectedFilter == 'Mis postulaciones')
            _applicationsList()
          else
            FutureBuilder<List<JobOpportunityModel>>(
              future: _jobsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen)),
                  );
                }
                final allJobs = snapshot.data ?? [];
                final filteredJobs = switch (_selectedFilter) {
                  'Todos' => allJobs,
                  'Mis vacantes' => allJobs.where((j) => j.posterId == myId).toList(),
                  _ => allJobs.where((j) => j.type.toLowerCase() == _selectedFilter.toLowerCase()).toList(),
                };
                if (filteredJobs.isEmpty) {
                  return EmptyState(
                    icon: Icons.work_off_outlined,
                    message: _selectedFilter == 'Mis vacantes'
                        ? '// No has publicado vacantes. Usa "PUBLICAR VACANTE".'
                        : '// No hay vacantes con este filtro.',
                  );
                }
                return Column(children: filteredJobs.map(_buildJobCard).toList());
              },
            ),
        ],
      ),
    );
  }

  Widget _applicationsList() {
    if (_apiService.isOfflineMode || !_apiService.hasSession) {
      return const EmptyState(
          message: '// Tus postulaciones necesitan conexión con el servidor.', icon: Icons.cloud_off_rounded);
    }
    return FutureBuilder<List<JobApplicationModel>>(
      future: _myApplications,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen)),
          );
        }
        final apps = snap.data ?? [];
        if (apps.isEmpty) {
          return const EmptyState(message: '// Aún no te postulas a ninguna vacante.', icon: Icons.send_outlined);
        }
        return Column(
          children: apps
              .map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSilicon,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.circuitTrace),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppTheme.solderGold),
                      title: Text(
                        a.jobTitle ?? a.jobId,
                        style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 13, color: AppTheme.boneWhite),
                      ),
                      subtitle: Text(
                        a.message.isEmpty ? 'Sin mensaje' : a.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.greenishGray),
                      ),
                      trailing: _StatusChip(a.status),
                    ),
                  ))
              .toList(),
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
    final isMine = job.posterId != null && job.posterId == _apiService.currentUser.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isMine ? AppTheme.solderGold : AppTheme.circuitTrace, width: 1),
      ),
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
                        fontFamily: AppTheme.monoFont, fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                  ),
                ),
                Text(
                  '[MODALIDAD: ${job.modality.toUpperCase()}]',
                  style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 10, color: AppTheme.greenishGray),
                ),
                if (isMine)
                  const Text(
                    '[TU VACANTE]',
                    style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 10,
                        color: AppTheme.solderGold,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.title,
              style: const TextStyle(
                  fontFamily: AppTheme.monoFont, fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.boneWhite),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: job.posterId == null || isMine ? null : () => openProfile(context, job.posterId!),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.business_rounded, size: 14, color: AppTheme.greenishGray),
                  Text(
                    job.companyOrPoster,
                    style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 11, color: AppTheme.phosphorGreen),
                  ),
                  if (job.posterId != null && !isMine)
                    const Text('· ver perfil', style: TextStyle(fontSize: 10.5, color: AppTheme.greenishGray)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style:
                  const TextStyle(fontSize: 12.5, color: AppTheme.greenishGray, height: 1.4, fontFamily: 'sans-serif'),
            ),
            if (job.requirements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: job.requirements
                    .map((r) => Text('• $r', style: const TextStyle(fontSize: 11.5, color: AppTheme.boneWhite)))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (job.contactUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => openExternalUrl(context, job.contactUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.greenishGray),
                    label: const Text('Sitio de la vacante',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.greenishGray)),
                  ),
                if (isMine)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.solderGold,
                      foregroundColor: AppTheme.solderMask,
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () => _showApplicants(job),
                    icon: const Icon(Icons.groups_outlined, size: 16),
                    label: Text(
                      'POSTULANTES (${job.applicationsCount ?? 0})',
                      style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (job.hasApplied)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.phosphorGreen),
                      SizedBox(width: 4),
                      Text(
                        'POSTULADO',
                        style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 11,
                            color: AppTheme.phosphorGreen,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () async {
                      if (await showApplySheet(context, job)) _loadJobs();
                    },
                    child: const Text(
                      'POSTULARME >',
                      style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApplicants(JobOpportunityModel job) async {
    if (!requireOnline(context)) return;
    List<JobApplicationModel> apps;
    try {
      apps = await _apiService.getJobApplications(job.id);
    } catch (e) {
      if (mounted) showApiError(context, e);
      return;
    }
    if (!mounted) return;
    await showTerminalSheet<void>(
      context,
      title: 'POSTULANTES // ${job.title.toUpperCase()}',
      icon: Icons.groups_outlined,
      builder: (ctx, setSheet) => apps.isEmpty
          ? const EmptyState(
              message: '// Todavía nadie se postula. Prueba "BUSCAR TALENTO".', icon: Icons.hourglass_empty_rounded)
          : Column(
              children: [
                for (var i = 0; i < apps.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSilicon,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.circuitTrace),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => openProfile(ctx, apps[i].applicantId),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  UserAvatar(
                                      name: apps[i].applicant?.name ?? '?',
                                      avatarUrl: apps[i].applicant?.avatarUrl,
                                      size: 32),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        apps[i].applicant?.name ?? apps[i].applicantId,
                                        style: const TextStyle(
                                            fontFamily: AppTheme.monoFont, fontSize: 13, color: AppTheme.boneWhite),
                                      ),
                                      Text(
                                        apps[i].applicant?.university ?? '',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.greenishGray),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            KarmaBadge(points: apps[i].applicant?.karmaPoints ?? 0, compact: true),
                          ],
                        ),
                        if (apps[i].message.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(apps[i].message, style: const TextStyle(fontSize: 12.5, color: AppTheme.boneWhite)),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _StatusChip(apps[i].status),
                            TextButton.icon(
                              onPressed: () => openExternalUrl(ctx, _apiService.fileUrl(apps[i].cvUrl)),
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 15, color: AppTheme.solderGold),
                              label: const Text('Ver CV', style: TextStyle(color: AppTheme.solderGold, fontSize: 12)),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                try {
                                  final conv = await _apiService.openConversation(apps[i].applicantId);
                                  final updated =
                                      await _apiService.setApplicationStatus(job.id, apps[i].id, 'contactado');
                                  setSheet(() => apps[i] = updated);
                                  if (ctx.mounted) {
                                    Navigator.of(ctx)
                                        .push(MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
                                  }
                                } catch (e) {
                                  if (ctx.mounted) showApiError(ctx, e);
                                }
                              },
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF64B5F6)),
                              label: const Text('Contactar', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
    _loadJobs();
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'contactado' => AppTheme.phosphorGreen,
      'vista' => const Color(0xFF64B5F6),
      _ => AppTheme.greenishGray,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

/// RF-17 Postularme: envía el CV del perfil (o uno nuevo) y un mensaje al publicador.
Future<bool> showApplySheet(BuildContext context, JobOpportunityModel job) async {
  if (!requireOnline(context)) return false;
  final api = ApiService();
  final message = TextEditingController();
  AttachmentModel? otherCv;
  var saveToProfile = true;
  var busy = false;
  String? error;

  final result = await showTerminalSheet<bool>(
    context,
    title: 'POSTULARME // ${job.title.toUpperCase()}',
    icon: Icons.send_outlined,
    builder: (ctx, setSheet) {
      final profileCv = api.currentUser.cvUrl;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu CV y tu mensaje llegan por mensaje privado a ${job.companyOrPoster}.',
            style: const TextStyle(color: AppTheme.greenishGray, fontSize: 12.5),
          ),
          const FieldLabel('CV (PDF):'),
          if (otherCv != null)
            AttachmentList(attachments: [otherCv!], onRemove: (_) => setSheet(() => otherCv = null))
          else if (profileCv != null)
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.solderGold, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Se enviará el CV de tu perfil.',
                      style: TextStyle(color: AppTheme.boneWhite, fontSize: 12.5)),
                ),
                TextButton(
                  onPressed: () => openExternalUrl(ctx, api.fileUrl(profileCv)),
                  child: const Text('Ver', style: TextStyle(color: AppTheme.solderGold)),
                ),
              ],
            )
          else
            const Text(
              'Aún no tienes CV en tu perfil. Súbelo aquí:',
              style: TextStyle(color: AppTheme.alertRed, fontSize: 12.5),
            ),
          TextButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final files = await pickAndUploadFiles(ctx, maxFiles: 1, extensions: const ['pdf']);
                    if (files.isNotEmpty) setSheet(() => otherCv = files.first);
                  },
            icon: const Icon(Icons.upload_file_rounded, size: 16, color: AppTheme.phosphorGreen),
            label: Text(
              profileCv == null ? 'Subir CV (PDF)' : 'Usar otro PDF',
              style: const TextStyle(color: AppTheme.phosphorGreen),
            ),
          ),
          if (otherCv != null)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: saveToProfile,
              activeColor: AppTheme.solderGold,
              onChanged: (v) => setSheet(() => saveToProfile = v ?? false),
              title: const Text('Guardar también en mi perfil',
                  style: TextStyle(color: AppTheme.boneWhite, fontSize: 12.5)),
            ),
          const FieldLabel('MENSAJE PARA EL RECLUTADOR:'),
          TextField(
            controller: message,
            maxLines: 4,
            style: const TextStyle(color: AppTheme.boneWhite, fontSize: 13),
            decoration: terminalInput('Cuéntale por qué te interesa y qué sabes hacer'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(color: AppTheme.alertRed, fontSize: 12.5)),
            ),
          const SizedBox(height: 14),
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
                      if (otherCv == null && profileCv == null) {
                        setSheet(() => error = 'Sube tu CV en PDF para postularte.');
                        return;
                      }
                      setSheet(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        if (otherCv != null && saveToProfile) {
                          await api.updateMyProfile({'cvUrl': otherCv!.url, 'openToWork': true});
                        }
                        await api.applyToJob(job.id, message: message.text.trim(), cvUrl: otherCv?.url);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setSheet(() {
                          busy = false;
                          error = e.toString();
                        });
                      }
                    },
              child: const Text('ENVIAR POSTULACIÓN',
                  style: TextStyle(fontFamily: AppTheme.monoFont, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    },
  );
  if (result == true && context.mounted) {
    showSysSnack(context, 'Postulación enviada. La verás en "Mis postulaciones" y en tus mensajes.');
  }
  return result == true;
}

/// Publicar vacante (RF-17/RF-18: quien publica obtiene el rol de reclutador).
Future<bool> showCreateJobSheet(BuildContext context) async {
  if (!requireOnline(context)) return false;
  final api = ApiService();
  final title = TextEditingController();
  final company = TextEditingController(text: api.currentUser.name);
  final description = TextEditingController();
  final requirements = TextEditingController();
  final contactUrl = TextEditingController();
  var type = 'Pasantía';
  var modality = 'Remoto';
  var busy = false;
  String? error;
  const textStyle = TextStyle(color: AppTheme.boneWhite, fontSize: 13);

  final result = await showTerminalSheet<bool>(
    context,
    title: 'PUBLICAR VACANTE',
    icon: Icons.add_business_outlined,
    builder: (ctx, setSheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('PUESTO:'),
        TextField(controller: title, style: textStyle, decoration: terminalInput('Ej. Pasantía Backend Node.js')),
        const FieldLabel('EMPRESA O PUBLICADOR:'),
        TextField(controller: company, style: textStyle, decoration: terminalInput('Ej. BitLab Studios')),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('TIPO:'),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    dropdownColor: AppTheme.darkSilicon,
                    style: textStyle,
                    decoration: terminalInput(''),
                    items: const ['Pasantía', 'Junior', 'Freelance']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setSheet(() => type = v ?? 'Pasantía'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('MODALIDAD:'),
                  DropdownButtonFormField<String>(
                    initialValue: modality,
                    dropdownColor: AppTheme.darkSilicon,
                    style: textStyle,
                    decoration: terminalInput(''),
                    items: const ['Remoto', 'Híbrido', 'Presencial']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setSheet(() => modality = v ?? 'Remoto'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const FieldLabel('DESCRIPCIÓN:'),
        TextField(
            controller: description,
            minLines: 3,
            maxLines: 6,
            style: textStyle,
            decoration: terminalInput('¿Qué hará la persona?')),
        const FieldLabel('REQUISITOS (UNO POR LÍNEA):'),
        TextField(
            controller: requirements,
            minLines: 2,
            maxLines: 5,
            style: textStyle,
            decoration: terminalInput('Dart básico\nGit')),
        const FieldLabel('ENLACE EXTERNO (OPCIONAL):'),
        TextField(controller: contactUrl, style: textStyle, decoration: terminalInput('https://... o mailto:...')),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: const TextStyle(color: AppTheme.alertRed, fontSize: 12.5)),
          ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.solderGold,
              foregroundColor: AppTheme.solderMask,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: busy
                ? null
                : () async {
                    if (title.text.trim().isEmpty || company.text.trim().isEmpty || description.text.trim().isEmpty) {
                      setSheet(() => error = 'Puesto, empresa y descripción son obligatorios.');
                      return;
                    }
                    setSheet(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await api.createJob(
                        title: title.text.trim(),
                        companyOrPoster: company.text.trim(),
                        type: type,
                        modality: modality,
                        description: description.text.trim(),
                        requirements:
                            requirements.text.split('\n').map((r) => r.trim()).where((r) => r.isNotEmpty).toList(),
                        contactUrl: contactUrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      setSheet(() {
                        busy = false;
                        error = e.toString();
                      });
                    }
                  },
            child: const Text('PUBLICAR', style: TextStyle(fontFamily: AppTheme.monoFont, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );
  if (result == true && context.mounted) showSysSnack(context, 'Vacante publicada.');
  return result == true;
}
