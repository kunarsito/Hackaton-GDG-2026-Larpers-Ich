import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import '../widgets/social_widgets.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

/// Ranking (RF-13: Top Usuarios y Top Creadores por Karma) y
/// búsqueda de talento para reclutadores (RF-17).
class TalentScreen extends StatefulWidget {
  /// 'users' | 'creators' | 'talent'
  final String initialTab;
  const TalentScreen({super.key, this.initialTab = 'users'});

  @override
  State<TalentScreen> createState() => _TalentScreenState();
}

class _TalentScreenState extends State<TalentScreen> {
  final ApiService _api = ApiService();
  late String _tab = widget.initialTab;
  final _skill = TextEditingController();
  final _university = TextEditingController();
  final _query = TextEditingController();
  bool _openOnly = true;
  Future<List<UserModel>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (_api.isOfflineMode) {
      setState(() => _future = Future.value(<UserModel>[]));
      return;
    }
    setState(() {
      _future = switch (_tab) {
        'creators' => _api.searchUsers(role: 'creator'),
        'talent' => _api.searchUsers(
            q: _query.text.trim(),
            skill: _skill.text.trim(),
            university: _university.text.trim(),
            openToWorkOnly: _openOnly,
            limit: 50,
          ),
        _ => _api.searchUsers(),
      };
    });
  }

  Future<void> _message(UserModel user) async {
    if (!requireOnline(context)) return;
    try {
      final conv = await _api.openConversation(user.id);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTalent = _tab == 'talent';
    return Scaffold(
      appBar: AppBar(title: Text(isTalent ? 'BUSCAR TALENTO' : 'RANKING DE KARMA')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ChoiceChipsRow(
                options: const ['users', 'creators', 'talent'],
                labels: const ['Top usuarios', 'Top creadores', 'Buscar talento'],
                selected: _tab,
                onSelected: (v) {
                  _tab = v;
                  _load();
                },
              ),
              if (isTalent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _skill,
                  style: const TextStyle(color: AppTheme.boneWhite, fontSize: 13),
                  decoration: terminalInput('Habilidad (ej. Flutter, SQL)'),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _university,
                        style: const TextStyle(color: AppTheme.boneWhite, fontSize: 13),
                        decoration: terminalInput('Universidad'),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _query,
                        style: const TextStyle(color: AppTheme.boneWhite, fontSize: 13),
                        decoration: terminalInput('Nombre o bio'),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _openOnly,
                  activeColor: AppTheme.solderGold,
                  onChanged: (v) {
                    _openOnly = v ?? false;
                    _load();
                  },
                  title: const Text(
                    'Sólo perfiles "Abiertos a oportunidades"',
                    style: TextStyle(color: AppTheme.boneWhite, fontSize: 13),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TerminalButton(label: 'BUSCAR', icon: Icons.search_rounded, onPressed: _load),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ordenado por Karma Técnico.',
                  style: TextStyle(fontFamily: AppTheme.monoFont, fontSize: 10.5, color: AppTheme.greenishGray),
                ),
              ],
              const SizedBox(height: 12),
              FutureBuilder<List<UserModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen)),
                    );
                  }
                  if (snap.hasError) {
                    return EmptyState(message: snap.error.toString(), icon: Icons.error_outline);
                  }
                  final users = snap.data ?? [];
                  if (users.isEmpty) {
                    return EmptyState(
                      icon: Icons.person_search_outlined,
                      message: _api.isOfflineMode
                          ? '// El ranking necesita conexión con el servidor.'
                          : '// No hay perfiles con esos filtros.',
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < users.length; i++)
                        UserTile(
                          user: users[i],
                          rank: isTalent ? null : i + 1,
                          onTap: () => openProfile(context, users[i].id),
                          trailing: isTalent && users[i].id != _api.currentUser.id
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    KarmaBadge(points: users[i].karmaPoints, compact: true),
                                    IconButton(
                                      tooltip: 'Enviar mensaje',
                                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                                          size: 18, color: Color(0xFF64B5F6)),
                                      onPressed: () => _message(users[i]),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
