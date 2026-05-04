import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;

import '../shared/chat_image_gallery.dart';
import '../shared/message_reply_preview.dart';
import '../shared/message_status_indicator.dart';

/// Styled image message bubble for chat.
///
/// Features:
/// - Single image (natural aspect ratio, max width 65 %)
/// - 2-image stacked Messenger layout
/// - 3-image diagonal cascade
/// - 4+ image 2×2 grid with "+N" overlay
/// - Tap to open [ChatImageGallery]
/// - Local file and network URL support
/// - Shimmer loading placeholders
class ImageMessageBubble extends StatelessWidget {
  // ── Layout constants ────────────────────────────────────────────────────────
  static const double _twoImageSizeRatio = 0.40;
  static const double _twoImageOverlapRatio = 0.80;
  static const double _twoImageWidthPadding = 20;
  static const double _twoImageBorderRadius = 16;

  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.groupStatus,
    this.showTimestamp = false,
    this.onTap,
    this.contactName = 'Contact',
    this.onReplyTap,
    this.isLastOutgoing = false,
    this.contactAvatarUrl,
  });

  final types.ImageMessage message;
  final bool isSentByMe;
  final types.MessageGroupStatus? groupStatus;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final String contactName;
  final VoidCallback? onReplyTap;
  final bool isLastOutgoing;
  final String? contactAvatarUrl;

  bool get _isFirstInGroup => groupStatus == null || groupStatus!.isFirst;
  bool get _isLastInGroup => groupStatus == null || groupStatus!.isLast;
  bool _isLocalFile(String uri) =>
      !uri.startsWith('http://') && !uri.startsWith('https://');

  List<String> _imageUris() {
    final grouped = message.metadata?['groupedImageUris'] as List<dynamic>?;
    if (grouped != null && grouped.isNotEmpty) {
      return grouped.map((e) => e.toString()).toList();
    }
    return [message.source];
  }

  // ─── Image builders ──────────────────────────────────────────────────────

  Widget _errorWidget(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _networkOrFile(BuildContext context, String uri,
      {BoxFit fit = BoxFit.cover}) {
    if (_isLocalFile(uri)) {
      final path = uri.startsWith('file://') ? Uri.parse(uri).path : uri;
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: (_, __, ___) => _errorWidget(context),
      );
    }
    return CachedNetworkImage(
      imageUrl: uri,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      memCacheWidth: 400,
      memCacheHeight: 400,
      useOldImageOnUrlChange: true,
      placeholder: (_, __) => Container(color: Colors.grey.shade900),
      errorWidget: (_, __, ___) => _errorWidget(context),
    );
  }

  Widget _constrainedSquare(BuildContext context, String uri, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: _networkOrFile(context, uri),
    );
  }

  // ─── Single image ─────────────────────────────────────────────────────────

  Widget _buildSingleImage(BuildContext context, String uri) {
    final maxWidth = MediaQuery.of(context).size.width * 0.65;
    final maxHeight = maxWidth * 1.5;

    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 3),
      child: GestureDetector(
        onTap: () => ChatImageGallery.open(
          context,
          imageUrls: [uri],
          initialIndex: 0,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_twoImageBorderRadius),
            child: _isLocalFile(uri)
                ? Image.file(
                    File(uri.startsWith('file://')
                        ? Uri.parse(uri).path
                        : uri),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _errorWidget(context),
                  )
                : CachedNetworkImage(
                    imageUrl: uri,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    memCacheWidth: 600,
                    useOldImageOnUrlChange: true,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => SizedBox(
                      width: maxWidth,
                      height: maxWidth * 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius:
                              BorderRadius.circular(_twoImageBorderRadius),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _errorWidget(context),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── 2-image stacked ─────────────────────────────────────────────────────

  Widget _buildTwoImageLayout(BuildContext context, List<String> uris) {
    final msgWidth = MediaQuery.of(context).size.width;
    final imgSize = msgWidth * _twoImageSizeRatio;
    final totalW = imgSize + _twoImageWidthPadding + 20;
    final totalH = imgSize + imgSize * _twoImageOverlapRatio;

    return SizedBox(
      height: totalH,
      width: totalW,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Back image
          Positioned(
            bottom: 0,
            left: isSentByMe ? null : 0,
            right: isSentByMe ? 0 : null,
            child: GestureDetector(
              onTap: () => ChatImageGallery.open(context,
                  imageUrls: uris, initialIndex: 1),
              child: _clippedImage(context, uris[1], imgSize),
            ),
          ),
          // Front image
          Positioned(
            top: 0,
            left: isSentByMe ? 0 : null,
            right: isSentByMe ? null : 0,
            child: GestureDetector(
              onTap: () => ChatImageGallery.open(context,
                  imageUrls: uris, initialIndex: 0),
              child:
                  _clippedImage(context, uris[0], imgSize, shadowOpacity: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clippedImage(BuildContext context, String uri, double size,
      {double shadowOpacity = 0.2}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_twoImageBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_twoImageBorderRadius),
        child: _constrainedSquare(context, uri, size),
      ),
    );
  }

  // ─── 3-image diagonal ────────────────────────────────────────────────────

  Widget _buildThreeImageLayout(BuildContext context, List<String> uris) {
    final msgWidth = MediaQuery.of(context).size.width;
    final imgSize = msgWidth * 0.38;
    const overlap = 30.0;
    const diagOffset = 25.0;
    final totalHeight = (imgSize * 3) - (overlap * 2);
    final totalWidth = imgSize + diagOffset * 2;

    return SizedBox(
      height: totalHeight,
      width: totalWidth,
      child: Stack(
        children: [
          for (int i = 0; i < 3; i++)
            Positioned(
              top: (imgSize - overlap) * i,
              right: isSentByMe ? (i == 1 ? null : 0) : null,
              left: isSentByMe ? (i == 1 ? 0 : null) : (i == 1 ? null : 0),
              child: GestureDetector(
                onTap: () => ChatImageGallery.open(context,
                    imageUrls: uris, initialIndex: i),
                child: _clippedImage(context, uris[i], imgSize),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 4+ grid ─────────────────────────────────────────────────────────────

  Widget _buildGridLayout(BuildContext context, List<String> uris) {
    final msgWidth = MediaQuery.of(context).size.width;
    final imgSize = msgWidth * 0.28;
    const gap = 5.0;
    final showOverlay = uris.length > 4;
    final remaining = uris.length - 4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          _tapImage(context, uris, 0, imgSize),
          const SizedBox(width: gap),
          _tapImage(context, uris, 1, imgSize),
        ]),
        const SizedBox(height: gap),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _tapImage(context, uris, 2, imgSize),
          const SizedBox(width: gap),
          _tapImageWithOverlay(
              context, uris, 3, imgSize, showOverlay, remaining),
        ]),
      ],
    );
  }

  Widget _tapImage(
      BuildContext context, List<String> uris, int i, double size) {
    return GestureDetector(
      onTap: () =>
          ChatImageGallery.open(context, imageUrls: uris, initialIndex: i),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_twoImageBorderRadius),
        child: _constrainedSquare(context, uris[i], size),
      ),
    );
  }

  Widget _tapImageWithOverlay(BuildContext context, List<String> uris, int i,
      double size, bool showOverlay, int remaining) {
    return GestureDetector(
      onTap: () =>
          ChatImageGallery.open(context, imageUrls: uris, initialIndex: i),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_twoImageBorderRadius),
              child: _constrainedSquare(context, uris[i], size),
            ),
            if (showOverlay)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(_twoImageBorderRadius),
                  ),
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Dispatch ─────────────────────────────────────────────────────────────

  Widget _buildImageContent(BuildContext context) {
    final uris = _imageUris();
    return switch (uris.length) {
      1 => _buildSingleImage(context, uris[0]),
      2 => _buildTwoImageLayout(context, uris),
      3 => _buildThreeImageLayout(context, uris),
      _ => _buildGridLayout(context, uris),
    };
  }

  // ─── Timestamp ────────────────────────────────────────────────────────────

  Widget _buildTimestampRow(Color textColor) {
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
              _formatDateTime(message.createdAt),
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.6), fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildTimestampRow(cs.onSurface),
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
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right:
                    0, // Always 12, sent messages don't have avatars on the right
                top: _isFirstInGroup ? 8 : 1,
                bottom: _isLastInGroup ? 8 : 1,
              ),
              child: _buildImageContent(context),
            ),
          ),
        ),
        Align(
          alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: MessageStatusIndicator(
            isSentByMe: isSentByMe,
            isLastOutgoing: isLastOutgoing,
            isSeen: message.seenAt != null,
            messageId: message.id,
            contactAvatarUrl: contactAvatarUrl,
          ),
        ),
      ],
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

String _formatDateTime(DateTime? dt) {
  if (dt == null) return '';
  final l = dt.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
