import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../models/attachment_model.dart';
import '../screens/profile_screen.dart';
import '../services/api_service.dart';

/// Piezas de UI compartidas por la red social. Todas funcionan igual en móvil y web
/// (SRS §4: equivalencia de capacidades).

const List<String> kAllowedUploadExtensions = [
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'pdf',
  'zip',
  'txt',
  'md',
  'csv',
  'json',
  'dart',
  'ts',
  'py',
  'java',
  'c',
  'cpp',
  'kt',
  'go',
  'rs',
  'sql',
];

void showSysSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppTheme.darkSilicon,
      content: Text(
        error ? '[ERROR]: $message' : '[SYS_MSG]: $message',
        style: TextStyle(
          color: error ? AppTheme.alertRed : AppTheme.phosphorGreen,
          fontFamily: AppTheme.monoFont,
          fontSize: 12.5,
        ),
      ),
    ),
  );
}

/// Muestra el error de una acción de la API como SnackBar.
void showApiError(BuildContext context, Object error) {
  showSysSnack(context, error is ApiException ? error.message : 'Algo salió mal: $error', error: true);
}

/// Las funciones de la red social necesitan backend y sesión. Devuelve false y avisa si no.
bool requireOnline(BuildContext context) {
  final api = ApiService();
  if (api.isOfflineMode || !api.hasSession) {
    showSysSnack(context, 'Esta función necesita conexión con el servidor e iniciar sesión.', error: true);
    return false;
  }
  return true;
}

Future<void> openExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) showSysSnack(context, 'No se pudo abrir el enlace.', error: true);
  }
}

void openProfile(BuildContext context, String userId) {
  if (userId.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
  );
}

InputDecoration terminalInput(String hint, {String? label}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: AppTheme.darkSilicon,
    labelStyle: const TextStyle(color: AppTheme.greenishGray, fontSize: 12),
    hintStyle: const TextStyle(color: AppTheme.circuitTrace, fontSize: 12.5),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppTheme.circuitTrace),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppTheme.circuitTrace),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppTheme.phosphorGreen),
    ),
  );
}

/// Cabecera de módulo con el estilo "chip de circuito" de la app.
class ModuleHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Widget? action;

  const ModuleHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.color = AppTheme.phosphorGreen,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.greenishGray),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

/// Botón compacto de acción principal (CREAR, PUBLICAR...).
class TerminalButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const TerminalButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppTheme.phosphorGreen,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppTheme.solderMask,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 34),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de chips de selección única (pestañas Oficial/Comunidad, Top/Recientes...).
class ChoiceChipsRow extends StatelessWidget {
  final List<String> options;
  final List<String>? labels;
  final String selected;
  final ValueChanged<String> onSelected;

  const ChoiceChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  (labels?[i] ?? options[i]).toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected == options[i] ? AppTheme.solderMask : AppTheme.boneWhite,
                  ),
                ),
                selected: selected == options[i],
                selectedColor: AppTheme.phosphorGreen,
                backgroundColor: AppTheme.darkSilicon,
                showCheckmark: false,
                side: BorderSide(
                  color: selected == options[i] ? AppTheme.phosphorGreen : AppTheme.circuitTrace,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onSelected: (sel) {
                  if (sel) onSelected(options[i]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;

  const UserAvatar({super.key, required this.name, this.avatarUrl, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = Text(
      initial,
      style: TextStyle(
        fontFamily: AppTheme.monoFont,
        fontWeight: FontWeight.bold,
        fontSize: size * 0.42,
        color: AppTheme.phosphorGreen,
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.darkSiliconDeep,
        border: Border.all(color: AppTheme.phosphorGreen, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? fallback
          : Image.network(
              ApiService().fileUrl(avatarUrl!),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

class KarmaBadge extends StatelessWidget {
  final int points;
  final bool compact;

  const KarmaBadge({super.key, required this.points, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.solderGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.solderGold, width: 0.8),
      ),
      child: Text(
        compact ? '${points}K' : 'KARMA $points',
        style: TextStyle(
          fontFamily: AppTheme.monoFont,
          fontSize: compact ? 9.5 : 10.5,
          fontWeight: FontWeight.bold,
          color: AppTheme.solderGold,
        ),
      ),
    );
  }
}

/// Insignia "OFICIAL" o "@autor" (§1.1: el origen del contenido siempre visible).
class SourceBadge extends StatelessWidget {
  final bool isOfficial;
  final String? authorId;
  final String? authorName;

  const SourceBadge({super.key, required this.isOfficial, this.authorId, this.authorName});

  @override
  Widget build(BuildContext context) {
    if (isOfficial) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.phosphorGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.phosphorGreen, width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 11, color: AppTheme.phosphorGreen),
            SizedBox(width: 3),
            Text(
              'OFICIAL',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.phosphorGreen,
              ),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: authorId == null ? null : () => openProfile(context, authorId!),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(name: authorName ?? '?', size: 16),
            const SizedBox(width: 4),
            Text(
              '@${authorName ?? 'creador'}',
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.solderGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Votos ▲ puntaje ▼ (RF-11, RF-13). Tocar el voto actual lo quita.
class VoteBar extends StatelessWidget {
  final int score;
  final int myVote;
  final ValueChanged<int> onVote;
  final bool allowDownvote;

  const VoteBar({
    super.key,
    required this.score,
    required this.myVote,
    required this.onVote,
    this.allowDownvote = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, int value, Color activeColor) {
      final active = myVote == value;
      return InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => onVote(active ? 0 : value),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: active ? activeColor : AppTheme.greenishGray),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSiliconDeep,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.circuitTrace),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Voto positivo',
            child: arrow(Icons.arrow_upward_rounded, 1, AppTheme.phosphorGreen),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: myVote == 1
                  ? AppTheme.phosphorGreen
                  : myVote == -1
                      ? AppTheme.alertRed
                      : AppTheme.boneWhite,
            ),
          ),
          if (allowDownvote)
            Tooltip(
              message: 'Voto negativo',
              child: arrow(Icons.arrow_downward_rounded, -1, AppTheme.alertRed),
            )
          else
            const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Lista de adjuntos: imágenes con miniatura; el resto como ficha que se abre/descarga.
class AttachmentList extends StatelessWidget {
  final List<AttachmentModel> attachments;
  final void Function(AttachmentModel)? onRemove;

  const AttachmentList({super.key, required this.attachments, this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final api = ApiService();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((a) {
        void open() => openExternalUrl(context, api.fileUrl(a.url));
        final removeButton = onRemove == null
            ? null
            : InkWell(
                onTap: () => onRemove!(a),
                child: const Icon(Icons.close, size: 14, color: AppTheme.alertRed),
              );
        if (a.isImage && onRemove == null) {
          return InkWell(
            onTap: open,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                api.fileUrl(a.url),
                height: 120,
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fileChip(a, null),
              ),
            ),
          );
        }
        return InkWell(onTap: open, child: _fileChip(a, removeButton));
      }).toList(),
    );
  }

  Widget _fileChip(AttachmentModel a, Widget? trailing) {
    final icon = a.isImage
        ? Icons.image_outlined
        : a.isPdf
            ? Icons.picture_as_pdf_outlined
            : a.fileName.endsWith('.zip')
                ? Icons.folder_zip_outlined
                : Icons.description_outlined;
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkSiliconDeep,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.circuitTrace),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.phosphorGreen),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              a.fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 11,
                color: AppTheme.boneWhite,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            a.readableSize,
            style: const TextStyle(fontSize: 10, color: AppTheme.greenishGray),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
        ],
      ),
    );
  }
}

/// Elige archivos y los sube (RF-12). Devuelve los adjuntos creados (vacío si se cancela).
Future<List<AttachmentModel>> pickAndUploadFiles(
  BuildContext context, {
  int maxFiles = 4,
  List<String> extensions = kAllowedUploadExtensions,
}) async {
  if (!requireOnline(context)) return [];
  final api = ApiService();
  final List<PlatformFile> picked;
  try {
    picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: extensions);
  } catch (e) {
    if (context.mounted) showSysSnack(context, 'No se pudo abrir el selector de archivos.', error: true);
    return [];
  }
  if (picked.isEmpty) return [];
  if (picked.length > maxFiles && context.mounted) {
    showSysSnack(context, 'Sólo se adjuntan los primeros $maxFiles archivos.');
  }
  final result = <AttachmentModel>[];
  for (final file in picked.take(maxFiles)) {
    try {
      final bytes = await file.readAsBytes();
      result.add(await api.uploadFile(fileName: file.name, bytes: bytes));
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }
  return result;
}

/// Mensaje centrado para listas vacías o sin conexión.
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.circuitTrace, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 11.5,
              color: AppTheme.greenishGray,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja inferior estándar con título y cierre (formularios de creación).
Future<T?> showTerminalSheet<T>(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Widget Function(BuildContext sheetContext, StateSetter setSheetState) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.solderMask,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      side: BorderSide(color: AppTheme.circuitTrace, width: 1),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
          left: 20,
          right: 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppTheme.phosphorGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFont,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.phosphorGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.greenishGray),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 16),
                builder(ctx, setSheetState),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Etiqueta de campo de formulario en mayúsculas monoespaciadas.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 11,
            color: AppTheme.greenishGray,
          ),
        ),
      );
}
