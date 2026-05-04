import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;

/// Shows the "replied-to" preview above a message bubble.
///
/// Supports:
/// - Text message previews
/// - Image thumbnail for image replies
/// - Generic file type label for other media
///
/// Reusable: colors are pulled from [Theme.of(context)].
class MessageReplyPreview extends StatelessWidget {
  const MessageReplyPreview({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.maxWidth = 280.0,
    this.contactName = 'Contact',
    this.onReplyTap,
  });

  /// The message that carries [metadata]['replyTo'].
  final types.Message message;

  final bool isSentByMe;
  final double maxWidth;

  /// Display name of the other participant.
  final String contactName;

  /// Scroll-to-original callback.
  final VoidCallback? onReplyTap;

  // ─── Helpers ───────────────────────────────────────────────────────────────

  bool get _hasReplyTo => message.metadata?['replyTo'] != null;

  bool get _hasImagePreview {
    final r = message.metadata?['replyTo'];
    if (r == null) return false;
    final hasFiles = r['hasFiles'] == true;
    final fileType = r['fileType'] as String?;
    final fileUrl = r['fileUrl'] as String?;
    return hasFiles && fileType?.toLowerCase() == 'image' && fileUrl != null;
  }

  String? get _imageUrl => message.metadata?['replyTo']?['fileUrl'] as String?;

  String _replyContext() {
    final r = message.metadata?['replyTo'];
    if (r == null) return '';
    final t = r['type'] as String?;
    if (isSentByMe) {
      return t == 'outgoing' ? 'You replied to yourself' : 'You replied to $contactName';
    } else {
      return t == 'outgoing'
          ? '$contactName replied to you'
          : '$contactName replied to themselves';
    }
  }

  String _previewText() {
    final r = message.metadata?['replyTo'];
    if (r == null) return '';
    final hasFiles = r['hasFiles'] == true;
    final fileType = r['fileType'] as String?;
    if (hasFiles && fileType != null) {
      return switch (fileType.toLowerCase()) {
        'image' => '📷 Photo',
        'video' => '🎥 Video',
        'audio' => '🎵 Audio',
        _ => '📎 File',
      };
    }
    return (r['text'] as String?) ?? 'Message';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_hasReplyTo) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final textColor = cs.onSurface;

    return GestureDetector(
      onTap: onReplyTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: isSentByMe ? 0 : 12,
          right: isSentByMe ? 12 : 0,
        ),
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, 20),
              child: Column(
                crossAxisAlignment:
                    isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Context label (e.g. "You replied to Contact")
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reply, size: 12, color: textColor),
                        const SizedBox(width: 4),
                        Text(
                          _replyContext(),
                          style: TextStyle(fontSize: 11, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  // Preview content
                  _hasImagePreview
                      ? _ImagePreview(imageUrl: _imageUrl!)
                      : Container(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          padding: const EdgeInsets.only(
                              left: 14, right: 14, top: 10, bottom: 25),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _previewText(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        memCacheWidth: 240,
        memCacheHeight: 240,
        placeholder: (_, __) => Container(
          width: 120,
          height: 120,
          color: Colors.grey[700],
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white54),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 120,
          height: 120,
          color: Colors.grey[700],
          child: const Icon(Icons.broken_image, color: Colors.white54, size: 32),
        ),
      ),
    );
  }
}
