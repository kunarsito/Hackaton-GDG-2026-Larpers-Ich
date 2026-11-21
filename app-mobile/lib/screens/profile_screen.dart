import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/challenge_model.dart';
import '../models/course_model.dart';
import '../models/forum_post_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import '../widgets/social_widgets.dart';
import 'challenge_detail_screen.dart';
import 'community_screen.dart';
import 'courses_screen.dart';
import 'messages_screen.dart';

/// RF-15 Perfil estilo Instagram: foto, bio, enlaces, habilidades, Karma visible,
/// seguidores y pestañas de contenido. [userId] null = mi perfil.
/// [embedded] = se muestra como pestaña (sin AppBar propia).
class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool embedded;

  const ProfileScreen({super.key, this.userId, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  UserModel? _user;
  String? _error;
  String _tab = 'posts'; // posts | courses | challenges | saved
  Future<List<Object>>? _tabFuture;
  bool _busy = false;

  bool get _isMe => widget.userId == null || widget.userId == _api.currentUser.id;
  String get _id => widget.userId ?? _api.currentUser.id;

  @override
  void initState() {
    super.initState();
    _api.userVersion.addListener(_onCurrentUserChanged);
    _load();
  }

  @override
  void dispose() {
    _api.userVersion.removeListener(_onCurrentUserChanged);
    super.dispose();
  }

  void _onCurrentUserChanged() {
    if (_isMe && mounted) setState(() => _user = _api.currentUser);
  }

  Future<void> _load() async {
    if (_api.isOfflineMode && _isMe) {
      setState(() => _user = _api.currentUser);
    } else {
      try {
        final user = await _api.getUserProfile(_id);
        if (!mounted) return;
        setState(() {
          _user = user;
          _error = null;
        });
        if (_isMe) _api.applyServerUser(user.toJson());
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          if (_isMe) _user = _api.currentUser; // sin conexión: lo que sabemos localmente
        });
      }
    }
    _loadTab();
  }

  void _loadTab() {
    setState(() {
      _tabFuture = switch (_tab) {
        'courses' => _api.getCourses(authorId: _id).catchError((Object _) => <CourseModel>[]),
        'challenges' => _api.getChallenges(authorId: _id),
        'saved' => _api.getForumPosts(savedOnly: true),
        _ => _api.getForumPosts(authorId: _id, sort: 'new'),
      };
    });
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

  Future<void> _toggleFollow() => _run(() async {
        final updated = await _api.setFollow(_id, !(_user?.isFollowing ?? false));
        setState(() => _user = updated);
      });

  Future<void> _message() => _run(() async {
        final conv = await _api.openConversation(_id);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
      });

  Future<void> _changeAvatar() async {
    final files =
        await pickAndUploadFiles(context, maxFiles: 1, extensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp']);
    if (files.isEmpty || !mounted) return;
    await _run(() async {
      final updated = await _api.updateMyProfile({'avatarUrl': files.first.url});
      setState(() => _user = updated);
      if (mounted) showSysSnack(context, 'Foto de perfil actualizada.');
    });
  }

  Future<void> _uploadCv() async {
    final files = await pickAndUploadFiles(context, maxFiles: 1, extensions: const ['pdf']);
    if (files.isEmpty || !mounted) return;
    await _run(() async {
      final updated = await _api.updateMyProfile({'cvUrl': files.first.url, 'openToWork': true});
      setState(() => _user = updated);
      if (mounted) showSysSnack(context, 'CV subido. Tu perfil aparece como "Abierto a oportunidades".');
    });
  }

  Future<void> _giftKarma() async {
    if (!requireOnline(context)) return;
    int remaining;
    try {
      remaining = await _api.remainingGiftToday();
    } catch (e) {
      if (mounted) showApiError(context, e);
      return;
    }
    if (!mounted) return;
    if (remaining <= 0) {
      showSysSnack(context, 'Ya regalaste tus 5 puntos de hoy. Vuelve mañana.', error: true);
      return;
    }
    var amount = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppTheme.darkSilicon,
          title: Text(
            'REGALAR KARMA A @${_user?.name}',
            style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 14, color: AppTheme.solderGold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Los puntos salen de tu saldo (${_api.currentUser.karmaPoints}). Hoy puedes regalar $remaining más.',
                style: const TextStyle(color: AppTheme.greenishGray, fontSize: 12.5),
              ),
              Slider(
                value: amount.toDouble(),
                min: 1,
                max: remaining.toDouble().clamp(1, 5),
                divisions: remaining > 1 ? remaining - 1 : null,
                activeColor: AppTheme.solderGold,
                label: '$amount',
                onChanged: remaining > 1 ? (v) => setD(() => amount = v.round()) : null,
              ),
              Center(
                child: Text(
                  '+$amount KARMA',
                  style: const TextStyle(
                      fontFamily: AppTheme.monoFont, fontWeight: FontWeight.bold, color: AppTheme.solderGold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Regalar')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      final updated = await _api.giftKarma(_id, amount);
      setState(() => _user = updated);
      if (mounted) showSysSnack(context, 'Le regalaste +$amount Karma a @${updated.name}.');
    });
  }

  Future<void> _showFollowList(bool followers) async {
    if (!requireOnline(context)) return;
    List<UserModel> users;
    try {
      users = await _api.getFollowList(_id, followers: followers);
    } catch (e) {
      if (mounted) showApiError(context, e);
      return;
    }
    if (!mounted) return;
    showTerminalSheet<void>(
      context,
      title: followers ? 'SEGUIDORES' : 'SIGUIENDO',
      icon: Icons.people_outline,
      builder: (ctx, _) => users.isEmpty
          ? const EmptyState(message: '// Nadie por aquí todavía.', icon: Icons.people_outline)
          : Column(
              children: users
                  .map((u) => UserTile(
                        user: u,
                        onTap: () {
                          Navigator.pop(ctx);
                          openProfile(context, u.id);
                        },
                      ))
                  .toList(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final body = user == null
        ? Center(
            child: _error != null
                ? EmptyState(message: _error!, icon: Icons.error_outline)
                : const CircularProgressIndicator(color: AppTheme.phosphorGreen),
          )
        : RefreshIndicator(
            color: AppTheme.phosphorGreen,
            backgroundColor: AppTheme.darkSilicon,
            onRefresh: _load,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _header(user),
                    const SizedBox(height: 16),
                    ChoiceChipsRow(
                      options: ['posts', 'courses', 'challenges', if (_isMe) 'saved'],
                      labels: ['Publicaciones', 'Cursos', 'Retos', if (_isMe) 'Guardados'],
                      selected: _tab,
                      onSelected: (v) {
                        _tab = v;
                        _loadTab();
                      },
                    ),
                    const SizedBox(height: 12),
                    _tabContent(),
                  ],
                ),
              ),
            ),
          );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(user == null ? 'PERFIL' : '@${user.name}')),
      body: body,
    );
  }

  Widget _header(UserModel user) {
    final isMe = _isMe;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.circuitTrace),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  UserAvatar(name: user.name, avatarUrl: user.avatarUrl, size: 76),
                  if (isMe)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: _busy ? null : _changeAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppTheme.phosphorGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.photo_camera_outlined, size: 14, color: AppTheme.solderMask),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _stat('${user.karmaPoints}', 'KARMA', AppTheme.solderGold, null),
                    _stat('${user.followers}', 'SEGUIDORES', AppTheme.boneWhite, () => _showFollowList(true)),
                    _stat('${user.following}', 'SIGUIENDO', AppTheme.boneWhite, () => _showFollowList(false)),
                    _stat('${user.solvedChallenges.length}', 'RETOS', AppTheme.phosphorGreen, null),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: const TextStyle(
                fontFamily: AppTheme.monoFont, fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.boneWhite),
          ),
          if (user.university.isNotEmpty)
            Text(user.university, style: const TextStyle(color: AppTheme.greenishGray, fontSize: 12.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (user.isCreator) _roleChip('CREADOR', AppTheme.phosphorGreen),
              if (user.isRecruiter) _roleChip('RECLUTADOR', const Color(0xFF64B5F6)),
              if (user.openToWork) _roleChip('ABIERTO A OPORTUNIDADES', AppTheme.solderGold),
            ],
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(user.bio, style: const TextStyle(color: AppTheme.boneWhite, fontSize: 13.5, height: 1.45)),
          ],
          if (user.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSiliconDeep,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.circuitTrace),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                fontFamily: AppTheme.monoFont, fontSize: 11, color: AppTheme.phosphorGreen)),
                      ))
                  .toList(),
            ),
          ],
          if (user.links.isNotEmpty || user.cvUrl != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              children: [
                for (final entry in user.links.entries)
                  TextButton.icon(
                    onPressed: () => openExternalUrl(context, entry.value),
                    icon: Icon(
                      entry.key == 'github'
                          ? Icons.code_rounded
                          : entry.key == 'linkedin'
                              ? Icons.work_outline_rounded
                              : Icons.link_rounded,
                      size: 15,
                      color: AppTheme.phosphorGreen,
                    ),
                    label: Text(
                      entry.key == 'github'
                          ? 'GitHub'
                          : entry.key == 'linkedin'
                              ? 'LinkedIn'
                              : 'Sitio web',
                      style: const TextStyle(color: AppTheme.phosphorGreen, fontSize: 12),
                    ),
                  ),
                if (user.cvUrl != null)
                  TextButton.icon(
                    onPressed: () => openExternalUrl(context, _api.fileUrl(user.cvUrl!)),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 15, color: AppTheme.solderGold),
                    label: const Text('Ver CV', style: TextStyle(color: AppTheme.solderGold, fontSize: 12)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: isMe
                ? [
                    TerminalButton(
                      label: 'EDITAR PERFIL',
                      icon: Icons.edit_outlined,
                      onPressed: _busy ? null : () => showEditProfileSheet(context),
                    ),
                    TerminalButton(
                      label: user.cvUrl == null ? 'SUBIR CV (PDF)' : 'CAMBIAR CV',
                      icon: Icons.upload_file_rounded,
                      color: AppTheme.solderGold,
                      onPressed: _busy ? null : _uploadCv,
                    ),
                  ]
                : [
                    TerminalButton(
                      label: (user.isFollowing ?? false) ? 'SIGUIENDO ✓' : 'SEGUIR',
                      icon:
                          (user.isFollowing ?? false) ? Icons.person_remove_outlined : Icons.person_add_alt_1_outlined,
                      color: (user.isFollowing ?? false) ? AppTheme.greenishGray : AppTheme.phosphorGreen,
                      onPressed: _busy ? null : _toggleFollow,
                    ),
                    TerminalButton(
                      label: 'MENSAJE',
                      icon: Icons.chat_bubble_outline_rounded,
                      color: const Color(0xFF64B5F6),
                      onPressed: _busy ? null : _message,
                    ),
                    TerminalButton(
                      label: 'REGALAR KARMA',
                      icon: Icons.volunteer_activism_outlined,
                      color: AppTheme.solderGold,
                      onPressed: _busy ? null : _giftKarma,
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 9.5, color: AppTheme.greenishGray)),
        ],
      ),
    );
  }

  Widget _roleChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 0.8),
        ),
        child: Text(label,
            style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
      );

  Widget _tabContent() {
    return FutureBuilder<List<Object>>(
      future: _tabFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen)),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return EmptyState(
            message: switch (_tab) {
              'courses' => '// Sin cursos publicados.',
              'challenges' => '// Sin retos publicados.',
              'saved' => '// Aún no guardas publicaciones.',
              _ => '// Sin publicaciones todavía.',
            },
          );
        }
        return Column(
          children: items.map((item) {
            if (item is ForumPostModel) return PostCard(post: item, onForked: _loadTab);
            if (item is CourseModel) return CourseCard(course: item, onChanged: _loadTab);
            if (item is ChallengeModel) return _challengeTile(item);
            return const SizedBox.shrink();
          }).toList(),
        );
      },
    );
  }

  Widget _challengeTile(ChallengeModel c) {
    final solved = _api.currentUser.solvedChallenges.contains(c.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: solved ? AppTheme.phosphorGreen : AppTheme.circuitTrace),
      ),
      child: ListTile(
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChallengeDetailScreen(challengeId: c.id))),
        leading: Icon(solved ? Icons.check_circle_rounded : Icons.code_rounded,
            color: solved ? AppTheme.phosphorGreen : AppTheme.solderGold),
        title: Text(c.title,
            style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 13, color: AppTheme.boneWhite)),
        subtitle: Text(
          '${c.difficulty} · ${c.category} · ${c.score} votos',
          style: const TextStyle(fontSize: 11, color: AppTheme.greenishGray),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.greenishGray),
      ),
    );
  }
}

/// Fila de usuario reutilizable (seguidores, ranking, talento, postulantes).
class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final Widget? trailing;
  final int? rank;

  const UserTile({super.key, required this.user, required this.onTap, this.trailing, this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSilicon,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.circuitTrace),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rank != null)
              SizedBox(
                width: 28,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontWeight: FontWeight.bold,
                    color: rank! <= 3 ? AppTheme.solderGold : AppTheme.greenishGray,
                  ),
                ),
              ),
            UserAvatar(name: user.name, avatarUrl: user.avatarUrl, size: 36),
          ],
        ),
        title: Text(user.name,
            style: const TextStyle(fontFamily: AppTheme.monoFont, fontSize: 13, color: AppTheme.boneWhite)),
        subtitle: Text(
          [
            if (user.university.isNotEmpty) user.university,
            if (user.skills.isNotEmpty) user.skills.take(3).join(' · '),
          ].join('  ·  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppTheme.greenishGray),
        ),
        trailing: trailing ?? KarmaBadge(points: user.karmaPoints),
      ),
    );
  }
}

/// Editar mi perfil: nombre, universidad, bio (300), enlaces, habilidades y "abierto a oportunidades".
Future<void> showEditProfileSheet(BuildContext context) {
  final api = ApiService();
  final u = api.currentUser;
  final name = TextEditingController(text: u.name);
  final university = TextEditingController(text: u.university);
  final bio = TextEditingController(text: u.bio);
  final github = TextEditingController(text: u.links['github'] ?? '');
  final linkedin = TextEditingController(text: u.links['linkedin'] ?? '');
  final website = TextEditingController(text: u.links['website'] ?? '');
  final skills = TextEditingController(text: u.skills.join(', '));
  var openToWork = u.openToWork;
  var busy = false;
  String? error;
  const textStyle = TextStyle(color: AppTheme.boneWhite, fontSize: 13);

  return showTerminalSheet<void>(
    context,
    title: 'EDITAR PERFIL',
    icon: Icons.manage_accounts_outlined,
    builder: (ctx, setSheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('NOMBRE:'),
        TextField(controller: name, style: textStyle, decoration: terminalInput('Tu nombre o usuario')),
        const FieldLabel('UNIVERSIDAD:'),
        TextField(controller: university, style: textStyle, decoration: terminalInput('Ej. UNAM')),
        const FieldLabel('BIOGRAFÍA (CÓMO TE DESCRIBES):'),
        TextField(
          controller: bio,
          maxLines: 3,
          maxLength: 300,
          style: textStyle,
          decoration: terminalInput('Ej. Backend con Node. Busco mi primera pasantía.'),
        ),
        const FieldLabel('HABILIDADES (SEPARADAS POR COMA):'),
        TextField(controller: skills, style: textStyle, decoration: terminalInput('Dart, Flutter, SQL')),
        const FieldLabel('ENLACES (https://...):'),
        TextField(controller: github, style: textStyle, decoration: terminalInput('GitHub')),
        const SizedBox(height: 6),
        TextField(controller: linkedin, style: textStyle, decoration: terminalInput('LinkedIn')),
        const SizedBox(height: 6),
        TextField(controller: website, style: textStyle, decoration: terminalInput('Portafolio / sitio web')),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: openToWork,
          activeThumbColor: AppTheme.solderGold,
          onChanged: (v) => setSheet(() => openToWork = v),
          title: const Text('Abierto a oportunidades', style: TextStyle(color: AppTheme.boneWhite, fontSize: 13)),
          subtitle: const Text(
            'Los reclutadores te encuentran en "Buscar talento".',
            style: TextStyle(color: AppTheme.greenishGray, fontSize: 11.5),
          ),
        ),
        if (error != null) Text(error!, style: const TextStyle(color: AppTheme.alertRed, fontSize: 12.5)),
        const SizedBox(height: 12),
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
                    if (!requireOnline(ctx)) return;
                    setSheet(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await api.updateMyProfile({
                        'name': name.text.trim(),
                        'university': university.text.trim(),
                        'bio': bio.text.trim(),
                        'skills': skills.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                        'links': {
                          'github': github.text.trim(),
                          'linkedin': linkedin.text.trim(),
                          'website': website.text.trim(),
                        },
                        'openToWork': openToWork,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) showSysSnack(context, 'Perfil actualizado.');
                    } catch (e) {
                      setSheet(() {
                        busy = false;
                        error = e.toString();
                      });
                    }
                  },
            child: const Text('GUARDAR', style: TextStyle(fontFamily: AppTheme.monoFont, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );
}
