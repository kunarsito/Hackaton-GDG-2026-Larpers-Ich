/// Archivo adjunto (RF-12). Sincronizado con `Attachment` (models.ts).
class AttachmentModel {
  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String url; // relativa al servidor: /uploads/<archivo>

  AttachmentModel({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.url,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory AttachmentModel.fromJson(Map<String, dynamic> json) => AttachmentModel(
        id: json['id'] as String? ?? '',
        fileName: json['fileName'] as String? ?? 'archivo',
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        url: json['url'] as String? ?? '',
      );

  static List<AttachmentModel> listFromJson(dynamic raw) =>
      raw is List ? raw.whereType<Map<String, dynamic>>().map(AttachmentModel.fromJson).toList() : <AttachmentModel>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'url': url,
      };
}
