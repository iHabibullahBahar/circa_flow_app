import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:url_launcher/url_launcher.dart';

import '../shared/message_reply_preview.dart';

/// File message bubble that shows the file name, extension badge, size and a
/// download icon. Tapping the bubble opens the URL with [url_launcher].
///
/// File icon and color are derived from the file extension.
class FileMessageBubble extends StatelessWidget {
  const FileMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.groupStatus,
    this.showTimestamp = false,
    this.onTap,
    this.contactName = 'Contact',
    this.onReplyTap,
  });

  final types.FileMessage message;
  final bool isSentByMe;
  final types.MessageGroupStatus? groupStatus;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final String contactName;
  final VoidCallback? onReplyTap;

  bool get _isFirst => groupStatus == null || groupStatus!.isFirst;
  bool get _isLast => groupStatus == null || groupStatus!.isLast;

  // ─── File icon / color ───────────────────────────────────────────────────

  IconData _iconFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'                                     => Icons.picture_as_pdf_rounded,
      'doc' || 'docx'                           => Icons.description_rounded,
      'xls' || 'xlsx'                           => Icons.table_chart_rounded,
      'ppt' || 'pptx'                           => Icons.slideshow_rounded,
      'txt'                                     => Icons.article_rounded,
      'zip' || 'rar' || '7z' || 'tar' || 'gz'  => Icons.folder_zip_rounded,
      'html' || 'css' || 'js' || 'json' || 'xml'
          || 'dart' || 'py' || 'java' || 'kt' || 'swift'
                                                => Icons.code_rounded,
      _                                         => Icons.insert_drive_file_rounded,
    };
  }

  Color _colorFor(String name, Color fallback) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'            => const Color(0xFFE53935),
      'doc' || 'docx'  => const Color(0xFF1565C0),
      'xls' || 'xlsx'  => const Color(0xFF2E7D32),
      'ppt' || 'pptx'  => const Color(0xFFE65100),
      'zip' || 'rar' || '7z' => const Color(0xFF6D4C41),
      'txt'            => const Color(0xFF455A64),
      _                => fallback,
    };
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _open() async {
    final uri = Uri.parse(message.source);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildTimestamp(Color textColor) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: showTimestamp ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: showTimestamp ? 24 : 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 4),
          child: Center(
            child: Text(
              _fmtDt(message.createdAt),
              style:
                  TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxW = MediaQuery.of(context).size.width * 0.70;
    final name = message.name;
    final size = message.size != null ? _formatSize(message.size!) : '';
    final icon = _iconFor(name);
    final iconFallback = isSentByMe ? Colors.white : cs.primary;
    final iconColor = isSentByMe ? Colors.white : _colorFor(name, iconFallback);
    final textColor = isSentByMe ? Colors.white : cs.onSurface;
    final subtitleColor = textColor.withValues(alpha: 0.7);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildTimestamp(cs.onSurface),
        MessageReplyPreview(
          message: message,
          isSentByMe: isSentByMe,
          contactName: contactName,
          onReplyTap: onReplyTap,
        ),
        GestureDetector(
          onTap: onTap,
          child: Align(
            alignment:
                isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxW),
              margin: EdgeInsets.only(
                left: 12,
                right: 12,
                top: _isFirst ? 8 : 1,
                bottom: _isLast ? 8 : 1,
              ),
              decoration: BoxDecoration(
                color: isSentByMe ? null : cs.surfaceContainerHigh,
                gradient: isSentByMe
                    ? const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _open,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSentByMe
                                ? Colors.white.withValues(alpha: 0.2)
                                : iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon,
                              color: isSentByMe ? Colors.white : iconColor,
                              size: 26),
                        ),
                        const SizedBox(width: 12),
                        // Name + size
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSentByMe
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      name.split('.').last.toUpperCase(),
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (size.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(size,
                                        style: TextStyle(
                                            color: subtitleColor, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.download_rounded,
                            color: textColor.withValues(alpha: 0.6), size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _fmtDt(DateTime? dt) {
  if (dt == null) return '';
  final l = dt.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
