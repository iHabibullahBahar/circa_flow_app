import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;

/// Graceful fallback bubble for message types that cannot be rendered.
///
/// Uses the [metadata]['messageType'] hint to show a contextual icon and
/// description rather than a blank or crashing UI.
class UnsupportedMessageBubble extends StatelessWidget {
  const UnsupportedMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.showTimestamp = false,
    this.onTap,
  });

  final types.UnsupportedMessage message;
  final bool isSentByMe;
  final bool showTimestamp;
  final VoidCallback? onTap;

  // ─── Icon / description ──────────────────────────────────────────────────

  IconData _icon(String type) => switch (type.toLowerCase()) {
        'reaction'    => Icons.emoji_emotions_outlined,
        'location'    => Icons.location_on_outlined,
        'contacts'    => Icons.contact_page_outlined,
        'sticker'     => Icons.sticky_note_2_outlined,
        'interactive' => Icons.touch_app_outlined,
        'button'      => Icons.smart_button_outlined,
        'order'       => Icons.shopping_cart_outlined,
        'system'      => Icons.info_outline,
        'template'    => Icons.article_outlined,
        'list'        => Icons.list_alt_outlined,
        _             => Icons.help_outline,
      };

  String _description(String type) => switch (type.toLowerCase()) {
        'reaction'    => 'Reaction messages are not supported',
        'location'    => 'Location sharing is not supported',
        'contacts'    => 'Contact sharing is not supported',
        'sticker'     => 'This sticker cannot be displayed',
        'interactive' => 'Interactive message not supported',
        'button'      => 'Button message not supported',
        'order'       => 'Order message not supported',
        'system'      => 'System message not supported',
        'template'    => 'Template message not supported',
        'list'        => 'List message not supported',
        _             => 'This message type is not supported',
      };

  // ─── Timestamp ──────────────────────────────────────────────────────────

  Widget _buildTimestamp(Color textColor) {
    final dt = message.createdAt;
    final label = dt == null
        ? ''
        : '${dt.toLocal().hour.toString().padLeft(2, '0')}:'
            '${dt.toLocal().minute.toString().padLeft(2, '0')}';

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
              label,
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.6), fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxW = MediaQuery.of(context).size.width * 0.70;
    final msgType =
        (message.metadata?['messageType'] as String?) ?? 'unknown';
    final textColor = isSentByMe ? Colors.white : cs.onSurface;
    final subtitleColor = textColor.withValues(alpha: 0.7);
    final iconBg = isSentByMe
        ? Colors.white.withValues(alpha: 0.2)
        : cs.surfaceContainerHigh;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildTimestamp(cs.onSurface),
        GestureDetector(
          onTap: onTap,
          child: Align(
            alignment:
                isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxW),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSentByMe ? null : cs.surfaceContainerHigh,
                gradient: isSentByMe
                    ? const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        _icon(msgType),
                        color: textColor.withValues(alpha: 0.8),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Unsupported Message',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _description(msgType),
                          style: TextStyle(
                              color: subtitleColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
