import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/attachment_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/social_api.dart';
import '../widgets/social_widgets.dart';

/// RF-16 Bandeja de mensajes privados (contratación o contacto personal).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _api = ApiService();
  List<ConversationModel>? _conversations;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Polling: la bandeja se refresca sola (sin WebSockets, SRS §2)
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_api.isOfflineMode || !_api.hasSession) {
      setState(() => _error = 'Los mensajes necesitan conexión con el servidor e iniciar sesión.');
      return;
    }
    try {
      final list = await _api.getConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && _conversations == null) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _conversations;
    return Scaffold(
      appBar: AppBar(title: const Text('MENSAJES')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _error != null && conversations == null
              ? EmptyState(message: _error!, icon: Icons.cloud_off_rounded)
              : conversations == null
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen))
                  : RefreshIndicator(
                      color: AppTheme.phosphorGreen,
                      backgroundColor: AppTheme.darkSilicon,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (conversations.isEmpty)
                            const EmptyState(
                              icon: Icons.chat_bubble_outline_rounded,
                              message:
                                  '// Sin conversaciones todavía.\nEntra al perfil de alguien y toca "MENSAJE", o postúlate a una vacante.',
                            ),
                          ...conversations.map((c) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSilicon,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: c.unreadCount > 0 ? AppTheme.phosphorGreen : AppTheme.circuitTrace,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => ChatScreen(conversation: c)),
                                    );
                                    _load();
                                  },
                                  leading:
                                      UserAvatar(name: c.otherUser.name, avatarUrl: c.otherUser.avatarUrl, size: 40),
                                  title: Text(
                                    c.otherUser.name,
                                    style: TextStyle(
                                      fontFamily: AppTheme.monoFont,
                                      fontSize: 13,
                                      color: AppTheme.boneWhite,
                                      fontWeight: c.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    c.lastMessage ?? 'Conversación nueva',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.greenishGray),
                                  ),
                                  trailing: c.unreadCount > 0
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.phosphorGreen,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${c.unreadCount}',
                                            style: const TextStyle(
                                              fontFamily: AppTheme.monoFont,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.solderMask,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          _shortTime(c.lastMessageAt),
                                          style: const TextStyle(
                                              fontFamily: AppTheme.monoFont,
                                              fontSize: 10,
                                              color: AppTheme.greenishGray),
                                        ),
                                ),
                              )),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

String _shortTime(String iso) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  if (t.year == now.year && t.month == now.month && t.day == now.day) return '${two(t.hour)}:${two(t.minute)}';
  return '${two(t.day)}/${two(t.month)}';
}

/// Chat 1 a 1 con polling cada 5 s (SRS RF-16) y adjuntos (RF-12).
class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<MessageModel> _messages = [];
  final List<AttachmentModel> _pending = [];
  Timer? _timer;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _poll(initial: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _poll({bool initial = false}) async {
    try {
      final after = _messages.isEmpty ? null : _messages.last.createdAt;
      final fresh = await _api.getMessages(widget.conversation.id, after: after);
      if (!mounted) return;
      final known = _messages.map((m) => m.id).toSet();
      final added = fresh.where((m) => !known.contains(m.id)).toList();
      setState(() {
        _messages.addAll(added);
        _loading = false;
      });
      if (added.isNotEmpty || initial) _scrollToBottom();
    } catch (e) {
      if (mounted && initial) {
        setState(() => _loading = false);
        showApiError(context, e);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty && _pending.isEmpty) return;
    setState(() => _sending = true);
    try {
      final msg = await _api.sendMessage(widget.conversation.id, text, attachments: List.of(_pending));
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _pending.clear();
        _input.clear();
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.conversation.otherUser;
    final myId = _api.currentUser.id;
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => openProfile(context, other.id),
          child: Row(
            children: [
              UserAvatar(name: other.name, avatarUrl: other.avatarUrl, size: 28),
              const SizedBox(width: 10),
              Flexible(child: Text(other.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen))
                    : _messages.isEmpty
                        ? EmptyState(
                            icon: Icons.waving_hand_outlined,
                            message: '// Escríbele a ${other.name} para contacto o una propuesta de trabajo.',
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final m = _messages[i];
                              final mine = m.senderId == myId;
                              return Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  decoration: BoxDecoration(
                                    color: mine ? AppTheme.phosphorGreen.withValues(alpha: 0.12) : AppTheme.darkSilicon,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: mine ? AppTheme.phosphorGreen : AppTheme.circuitTrace),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (m.body.isNotEmpty)
                                        SelectableText(m.body,
                                            style: const TextStyle(color: AppTheme.boneWhite, fontSize: 13.5)),
                                      if (m.attachments.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        AttachmentList(attachments: m.attachments),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        _shortTime(m.createdAt) + (mine && m.readAt != null ? ' · visto' : ''),
                                        style: const TextStyle(
                                            fontFamily: AppTheme.monoFont, fontSize: 9.5, color: AppTheme.greenishGray),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              if (_pending.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AttachmentList(
                      attachments: _pending,
                      onRemove: (a) => setState(() => _pending.remove(a)),
                    ),
                  ),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Adjuntar archivo',
                        icon: const Icon(Icons.attach_file_rounded, color: AppTheme.phosphorGreen),
                        onPressed: _sending || _pending.length >= 4
                            ? null
                            : () async {
                                final added = await pickAndUploadFiles(context, maxFiles: 4 - _pending.length);
                                if (mounted) setState(() => _pending.addAll(added));
                              },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sending ? null : _send(),
                          style: const TextStyle(color: AppTheme.boneWhite, fontSize: 13.5),
                          decoration: terminalInput('Escribe un mensaje...'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.phosphorGreen,
                          foregroundColor: AppTheme.solderMask,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.solderMask),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        onPressed: _sending ? null : _send,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
