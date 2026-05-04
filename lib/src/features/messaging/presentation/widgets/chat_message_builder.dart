import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;

import 'bubbles/audio_message_bubble.dart';
import 'bubbles/file_message_bubble.dart';
import 'bubbles/image_message_bubble.dart';
import 'bubbles/text_message_bubble.dart';
import 'bubbles/unsupported_message_bubble.dart';
import 'bubbles/video_message_bubble.dart';

export 'bubbles/audio_message_bubble.dart';
export 'bubbles/file_message_bubble.dart';
export 'bubbles/image_message_bubble.dart';
export 'bubbles/text_message_bubble.dart';
export 'bubbles/unsupported_message_bubble.dart';
export 'bubbles/video_message_bubble.dart';
export 'shared/chat_image_gallery.dart';
export 'shared/global_audio_manager.dart';
export 'shared/message_reply_preview.dart';
export 'shared/message_status_indicator.dart';

/// Provides static factory methods that return builder functions compatible
/// with [flutter_chat_ui]'s [Builders] configuration.
///
/// Named `ChatBubbleBuilder` (not `ChatMessageBuilder`) to avoid a name
/// collision with `flutter_chat_core`'s own internal `ChatMessageBuilder`.
///
/// Usage in [ChatScreen]:
/// ```dart
/// builders: Builders(
///   textMessageBuilder: ChatBubbleBuilder.textBuilder(...),
///   imageMessageBuilder: ChatBubbleBuilder.imageBuilder(...),
/// ),
/// ```
class ChatBubbleBuilder {
  ChatBubbleBuilder._();

  // ─── Static builder factories ─────────────────────────────────────────────

  /// Builder for [types.TextMessage] compatible with [Builders.textMessageBuilder].
  static Widget Function(
    BuildContext,
    types.TextMessage,
    int, {
    required bool isSentByMe,
    types.MessageGroupStatus? groupStatus,
  }) textBuilder({
    String contactName = 'Contact',
    String? contactAvatarUrl,
  }) {
    return (context, message, index,
        {required isSentByMe, groupStatus}) {
      return _TimestampTapWrapper(
        builder: (ts) => TextMessageBubble(
          message: message,
          isSentByMe: isSentByMe,
          groupStatus: groupStatus,
          showTimestamp: ts,
          contactName: contactName,
          contactAvatarUrl: contactAvatarUrl,
        ),
      );
    };
  }

  /// Builder for [types.ImageMessage] compatible with [Builders.imageMessageBuilder].
  static Widget Function(
    BuildContext,
    types.ImageMessage,
    int, {
    required bool isSentByMe,
    types.MessageGroupStatus? groupStatus,
  }) imageBuilder({
    String contactName = 'Contact',
    String? contactAvatarUrl,
  }) {
    return (context, message, index,
        {required isSentByMe, groupStatus}) {
      return ImageMessageBubble(
        message: message,
        isSentByMe: isSentByMe,
        groupStatus: groupStatus,
        contactName: contactName,
        contactAvatarUrl: contactAvatarUrl,
      );
    };
  }

  /// Builder for [types.AudioMessage] compatible with [Builders.audioMessageBuilder].
  static Widget Function(
    BuildContext,
    types.AudioMessage,
    int, {
    required bool isSentByMe,
    types.MessageGroupStatus? groupStatus,
  }) audioBuilder({
    String contactName = 'Contact',
    String? contactAvatarUrl,
  }) {
    return (context, message, index,
        {required isSentByMe, groupStatus}) {
      return AudioMessageBubble(
        message: message,
        isSentByMe: isSentByMe,
        groupStatus: groupStatus,
        contactName: contactName,
        contactAvatarUrl: contactAvatarUrl,
      );
    };
  }

  /// Builder for [types.VideoMessage] compatible with [Builders.videoMessageBuilder].
  static Widget Function(
    BuildContext,
    types.VideoMessage,
    int, {
    required bool isSentByMe,
    types.MessageGroupStatus? groupStatus,
  }) videoBuilder({String contactName = 'Contact'}) {
    return (context, message, index,
        {required isSentByMe, groupStatus}) {
      return VideoMessageBubble(
        message: message,
        isSentByMe: isSentByMe,
        groupStatus: groupStatus,
        contactName: contactName,
      );
    };
  }

  /// Builder for [types.FileMessage] compatible with [Builders.fileMessageBuilder].
  static Widget Function(
    BuildContext,
    types.FileMessage,
    int, {
    required bool isSentByMe,
    types.MessageGroupStatus? groupStatus,
  }) fileBuilder({String contactName = 'Contact'}) {
    return (context, message, index,
        {required isSentByMe, groupStatus}) {
      return FileMessageBubble(
        message: message,
        isSentByMe: isSentByMe,
        groupStatus: groupStatus,
        contactName: contactName,
      );
    };
  }

  /// Builder for [types.UnsupportedMessage].
  static Widget Function(
    BuildContext,
    types.UnsupportedMessage,
    int, {
    required bool isSentByMe,
    types.MessageGroupStatus? groupStatus,
  }) unsupportedBuilder() {
    return (context, message, index,
        {required isSentByMe, groupStatus}) {
      return UnsupportedMessageBubble(
        message: message,
        isSentByMe: isSentByMe,
      );
    };
  }
}

// ─── Tap-to-reveal timestamp wrapper ─────────────────────────────────────────

/// Wraps any bubble in a gesture that toggles the timestamp.
/// The [builder] receives the current [showTimestamp] state.
class _TimestampTapWrapper extends StatefulWidget {
  const _TimestampTapWrapper({required this.builder});

  final Widget Function(bool showTimestamp) builder;

  @override
  State<_TimestampTapWrapper> createState() => _TimestampTapWrapperState();
}

class _TimestampTapWrapperState extends State<_TimestampTapWrapper> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _show = !_show),
      child: widget.builder(_show),
    );
  }
}
