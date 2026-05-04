import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a Messenger-style delivery / seen indicator below outgoing bubbles.
///
/// - If [isLastOutgoing] is false → renders nothing (only the last sent
///   message shows a status).
/// - If seen → shows [contactAvatarUrl] (small circle, like Messenger).
/// - If not seen → shows "Sent" label.
///
/// Reusable: no hard-coded colors — all pulled from [Theme.of(context)].
class MessageStatusIndicator extends StatelessWidget {
  const MessageStatusIndicator({
    super.key,
    required this.isSentByMe,
    required this.isLastOutgoing,
    required this.isSeen,
    this.messageId,
    this.contactAvatarUrl,
  });

  /// Whether this message was sent by the current user.
  final bool isSentByMe;

  /// Only the last outgoing message shows a status.
  final bool isLastOutgoing;

  /// Whether the message has been seen by the recipient.
  final bool isSeen;

  /// Optional message ID (for debugging).
  final String? messageId;

  /// Contact's avatar URL — shown when [isSeen] is true (Messenger style).
  final String? contactAvatarUrl;

  @override
  Widget build(BuildContext context) {
    if (!isSentByMe || !isLastOutgoing) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isSeen)
            _SeenAvatar(
              avatarUrl: contactAvatarUrl,
              primaryContainer: cs.primaryContainer,
              onPrimaryContainer: cs.onPrimaryContainer,
            )
          else
            Text(
              'Sent',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeenAvatar extends StatelessWidget {
  const _SeenAvatar({
    required this.avatarUrl,
    required this.primaryContainer,
    required this.onPrimaryContainer,
  });

  final String? avatarUrl;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  static const double _size = 14.0;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallback(),
          errorWidget: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: _size * 0.7,
          color: onPrimaryContainer,
        ),
      );
}
