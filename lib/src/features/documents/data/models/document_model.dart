import 'package:flutter/material.dart' show IconData, Icons;

/// Data model for a Document, typed against DocumentResource from the backend.
class DocumentModel {
  final int id;
  final String title;
  final String? description;
  final String? fileType;
  final int? fileSizeBytes;
  final int downloadsCount;
  final String? downloadUrl;
  final String? publishedAt;
  final List<DocumentAttachment> attachments;

  const DocumentModel({
    required this.id,
    required this.title,
    this.description,
    this.fileType,
    this.fileSizeBytes,
    this.downloadsCount = 0,
    this.downloadUrl,
    this.publishedAt,
    this.attachments = const [],
  });

  factory DocumentModel.fromJson(Map<String, dynamic> j) => DocumentModel(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        description: j['description'] as String?,
        fileType: j['file_type'] as String?,
        fileSizeBytes: (j['file_size_bytes'] as num?)?.toInt(),
        downloadsCount: (j['downloads_count'] as num?)?.toInt() ?? 0,
        downloadUrl: j['download_url'] as String?,
        publishedAt: j['published_at'] as String?,
        attachments: (j['attachments'] as List?)
                ?.map((e) => DocumentAttachment.fromJson(e))
                .toList() ??
            [],
      );

  String get fileSizeFormatted {
    if (fileSizeBytes == null) return '';
    final kb = fileSizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  IconData get fileIcon => _getIcon(fileType);

  static IconData _getIcon(String? type) => switch (type?.toLowerCase()) {
        'pdf' => Icons.picture_as_pdf_outlined,
        'doc' || 'docx' => Icons.description_outlined,
        'xls' || 'xlsx' => Icons.table_chart_outlined,
        'ppt' || 'pptx' => Icons.slideshow_outlined,
        'zip' || 'rar' => Icons.folder_zip_outlined,
        'jpg' || 'jpeg' || 'png' => Icons.image_outlined,
        _ => Icons.insert_drive_file_outlined,
      };
}

class DocumentAttachment {
  final String name;
  final String url;
  final String type;

  const DocumentAttachment({
    required this.name,
    required this.url,
    required this.type,
  });

  factory DocumentAttachment.fromJson(Map<String, dynamic> json) =>
      DocumentAttachment(
        name: json['name'] as String? ?? 'Untitled',
        url: json['url'] as String? ?? '',
        type: json['type'] as String? ?? '',
      );

  IconData get icon => DocumentModel._getIcon(type);
}
