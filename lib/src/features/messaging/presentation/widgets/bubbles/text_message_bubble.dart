import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:url_launcher/url_launcher.dart';

import '../shared/message_reply_preview.dart';
import '../shared/message_status_indicator.dart';

/// Styled text message bubble with:
/// - Messenger/iMessage-style grouped border radius
/// - Emoji-only enlargement (48px, no background)
/// - Link detection and tap handling
/// - Animated timestamp reveal on tap
/// - Sent/Seen status indicator
///
/// Reusable — no hard-coded brand colors. Sent bubbles use a purple gradient
/// (brand accent); received bubbles use the theme's surfaceContainerHigh.
class TextMessageBubble extends StatelessWidget {
  const TextMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.groupStatus,
    this.showTimestamp = false,
    this.contactName = 'Contact',
    this.isLastOutgoing = false,
    this.contactAvatarUrl,
    this.onLinkTap,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onReplyTap,
    /// Pass the resolved contact avatar URL so it renders next to received msgs
    this.resolvedContactAvatarUrl,
  });

  // ─── Pre-compiled emoji regex ─────────────────────────────────────────────

  static final RegExp _emojiRegex = RegExp(
    r'^[\u{1F600}-\u{1F64F}'
    r'\u{1F300}-\u{1F5FF}'
    r'\u{1F680}-\u{1F6FF}'
    r'\u{1F1E0}-\u{1F1FF}'
    r'\u{2600}-\u{26FF}'
    r'\u{2700}-\u{27BF}'
    r'\u{FE00}-\u{FE0F}'
    r'\u{1F900}-\u{1F9FF}'
    r'\u{1FA00}-\u{1FA6F}'
    r'\u{1FA70}-\u{1FAFF}'
    r'\u{200D}'
    r'\s]+$',
    unicode: true,
  );

  static final RegExp _whitespaceRegex = RegExp(r'\s');

  // ─── Props ────────────────────────────────────────────────────────────────

  final types.TextMessage message;
  final bool isSentByMe;
  final types.MessageGroupStatus? groupStatus;
  final bool showTimestamp;
  final String contactName;
  final bool isLastOutgoing;
  final String? contactAvatarUrl;
  final String? resolvedContactAvatarUrl;
  final void Function(String url)? onLinkTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onMessageLongPress;
  final VoidCallback? onReplyTap;

  // ─── Computed ────────────────────────────────────────────────────────────

  bool get _isEmojiOnly {
    final text = message.text.trim();
    if (text.isEmpty) return false;
    return _emojiRegex.hasMatch(text) &&
        text.replaceAll(_whitespaceRegex, '').length <= 12;
  }

  bool get _isFirstInGroup =>
      groupStatus == null || groupStatus!.isFirst;

  bool get _isLastInGroup =>
      groupStatus == null || groupStatus!.isLast;

  // ─── Border radius (iMessage / Messenger style) ───────────────────────────

  BorderRadius _getGroupedBorderRadius(bool isSingleLine) {
    const double large = 18.0;
    const double small = 4.0;
    final double pill = isSingleLine ? 50.0 : large;

    if (groupStatus == null) return BorderRadius.circular(pill);

    final isFirst = groupStatus!.isFirst;
    final isLast = groupStatus!.isLast;

    if (isFirst && isLast) return BorderRadius.circular(pill);

    if (isSentByMe) {
      if (isFirst) {
        return BorderRadius.only(
          topLeft: Radius.circular(large),
          topRight: Radius.circular(large),
          bottomLeft: Radius.circular(large),
          bottomRight: Radius.circular(small),
        );
      } else if (isLast) {
        return BorderRadius.only(
          topLeft: Radius.circular(large),
          topRight: Radius.circular(small),
          bottomLeft: Radius.circular(large),
          bottomRight: Radius.circular(large),
        );
      } else {
        return BorderRadius.only(
          topLeft: Radius.circular(large),
          topRight: Radius.circular(small),
          bottomLeft: Radius.circular(large),
          bottomRight: Radius.circular(small),
        );
      }
    } else {
      if (isFirst) {
        return BorderRadius.only(
          topLeft: Radius.circular(large),
          topRight: Radius.circular(large),
          bottomLeft: Radius.circular(small),
          bottomRight: Radius.circular(large),
        );
      } else if (isLast) {
        return BorderRadius.only(
          topLeft: Radius.circular(small),
          topRight: Radius.circular(large),
          bottomLeft: Radius.circular(large),
          bottomRight: Radius.circular(large),
        );
      } else {
        return BorderRadius.only(
          topLeft: Radius.circular(small),
          topRight: Radius.circular(large),
          bottomLeft: Radius.circular(small),
          bottomRight: Radius.circular(large),
        );
      }
    }
  }

  // ─── Link spans ───────────────────────────────────────────────────────────

  List<InlineSpan> _buildTextSpans(
      String text, TextStyle base, Color linkColor) {
    final spans = <InlineSpan>[];
    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    int cursor = 0;

    for (final match in urlRegex.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start), style: base));
      }
      final url = match.group(0)!;
      spans.add(
        WidgetSpan(
          child: GestureDetector(
            onTap: () => _handleLinkTap(url),
            child: Text(
              url,
              style: base.copyWith(
                color: linkColor,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
              ),
            ),
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return spans.isEmpty ? [TextSpan(text: text, style: base)] : spans;
  }

  void _handleLinkTap(String url) {
    if (onLinkTap != null) {
      onLinkTap!(url);
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // ─── Sub-widgets ─────────────────────────────────────────────────────────

  Widget _buildTimestampRow(Color textColor) {
    final dt = _formatDateTime(message.createdAt);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: showTimestamp ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: showTimestamp ? 36 : 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 8, top: 12),
          child: Center(
            child: Text(
              dt,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() => MessageReplyPreview(
        message: message,
        isSentByMe: isSentByMe,
        contactName: contactName,
        onReplyTap: onReplyTap,
      );

  Widget _buildStatusIndicator() => MessageStatusIndicator(
        isSentByMe: isSentByMe,
        isLastOutgoing: isLastOutgoing,
        isSeen: message.seenAt != null,
        messageId: message.id,
        contactAvatarUrl: contactAvatarUrl,
      );

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = cs.onSurface;
    final linkColor = isSentByMe ? Colors.white.withValues(alpha: 0.9) : cs.primary;

    // Received bubble fill: distinct on both light and dark themes
    // Light: a soft grey (never invisible); Dark: slightly lighter surface
    final receivedBubbleColor = isDark
        ? const Color(0xFF2A2A2F)
        : const Color(0xFFEEEEF2);

    final isEmojiOnly = _isEmojiOnly;

    // Emoji-only: large text, no bubble
    if (isEmojiOnly) {
      return Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReplyPreview(),
            GestureDetector(
              onTap: onMessageTap,
              onLongPress: onMessageLongPress,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(
                  message.text,
                  style: TextStyle(fontSize: 48, color: onSurface),
                ),
              ),
            ),
            _buildTimestampRow(onSurface),
          ],
        ),
      );
    }

    final baseTextStyle = TextStyle(
      color: isSentByMe ? Colors.white : onSurface,
      fontSize: 16,
      height: 1.4,
    );

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;
    final estimatedCharsPerLine = ((maxBubbleWidth - 28) / 8).floor();
    final isSingleLine = message.text.length <= estimatedCharsPerLine &&
        !message.text.contains('\n');

    final bubble = GestureDetector(
      onTap: onMessageTap,
      onLongPress: onMessageLongPress,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        margin: EdgeInsets.only(
          // Leave room for avatar on received side
          left: isSentByMe ? 12 : 4,
          right: 12,
          top: _isFirstInGroup ? 6 : 1,
          bottom: _isLastInGroup ? 6 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSentByMe ? null : receivedBubbleColor,
          gradient: isSentByMe
              ? const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                )
              : null,
          borderRadius: _getGroupedBorderRadius(isSingleLine),
        ),
        child: RichText(
          text: TextSpan(
            children: _buildTextSpans(message.text, baseTextStyle, linkColor),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment:
          isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimestampRow(onSurface),
        _buildReplyPreview(),
        // Row: avatar + bubble (received) OR just bubble (sent)
        if (!isSentByMe)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Small contact avatar ───────────────────────────────────
              if (_isLastInGroup)
                _ContactAvatar(
                  name: contactName,
                  avatarUrl: resolvedContactAvatarUrl ?? contactAvatarUrl,
                )
              else
                const SizedBox(width: 28), // exact match: CircleAvatar(radius:14) = 28px
              const SizedBox(width: 4),
              bubble,
            ],
          )
        else
          bubble,
        _buildStatusIndicator(),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatDateTime(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$hour:$min';
}

// ─── Contact Avatar ───────────────────────────────────────────────────────────

/// Small circular avatar shown to the left of received messages.
/// Shows network image if available, otherwise initials, otherwise icon.
class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.name, this.avatarUrl});
  final String name;
  final String? avatarUrl;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 14,
      backgroundColor: cs.primaryContainer,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              _initials,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}
