import 'dart:ui';

import 'package:flutter/material.dart';

import 'chat_attachment_sheet.dart';

/// A Messenger / lazy-inbox-style message composer.
///
/// Designed as a pure widget — receives [onSend], [onGallery], [onCamera],
/// and [onAudio] explicitly so it has zero dependency on [flutter_chat_ui]'s
/// internal Provider setup. Safe across all future package upgrades.
///
/// Features:
/// - Dark pill-shaped text field with a subtle border ring
/// - Taller comfortable input (vertical padding 13px → ~48px default height)
/// - `+` button opens [ChatAttachmentSheet] (Gallery / Camera / Audio)
/// - Purple-gradient send arrow when text is present, mic otherwise
/// - Grows up to 4 lines then scrolls
/// - Glassmorphism background via BackdropFilter
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    this.hintText = 'Type a message...',
    this.controller,
    this.focusNode,
    this.onSend,
    this.onGallery,
    this.onCamera,
    this.onAudio,
    // Legacy: kept for backward-compat if you pass the old single callback.
    this.onAttachment,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Called with the trimmed text when the send button is pressed.
  final void Function(String text)? onSend;

  /// Called when the user taps "Gallery" in the attachment sheet.
  final VoidCallback? onGallery;

  /// Called when the user taps "Camera" in the attachment sheet.
  final VoidCallback? onCamera;

  /// Called when the user taps "Audio" in the attachment sheet.
  final VoidCallback? onAudio;

  /// Legacy single-callback for the + button (skips the sheet).
  /// Ignored if [onGallery], [onCamera], or [onAudio] are set.
  final VoidCallback? onAttachment;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? TextEditingController();
    _focus = widget.focusNode ?? FocusNode();
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    if (widget.controller == null) _ctrl.dispose();
    if (widget.focusNode == null) _focus.dispose();
    _hasText.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _hasText.value = _ctrl.text.trim().isNotEmpty;
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _ctrl.clear();
  }

  void _onPlusTap() {
    final hasSheet = widget.onGallery != null ||
        widget.onCamera != null ||
        widget.onAudio != null;

    if (hasSheet) {
      showChatAttachmentSheet(
        context,
        onGallery: widget.onGallery,
        onCamera: widget.onCamera,
        onAudio: widget.onAudio,
      );
    } else {
      widget.onAttachment?.call();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark: grey[850] fill; Light: slightly off-white surface variant
    final fieldFill =
        isDark ? const Color(0xFF2B2B35) : cs.surfaceContainerHigh;
    // Subtle border — visible but not harsh
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : cs.outline.withValues(alpha: 0.35);
    final hintColor = cs.onSurface.withValues(alpha: 0.45);
    final textColor = cs.onSurface;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: cs.surface.withValues(alpha: isDark ? 0.88 : 0.96),
          // SafeArea handles home-indicator padding on iPhone
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: _ComposerRow(
                ctrl: _ctrl,
                focus: _focus,
                hasText: _hasText,
                hintText: widget.hintText,
                fieldFill: fieldFill,
                borderColor: borderColor,
                hintColor: hintColor,
                textColor: textColor,
                onPlusTap: _onPlusTap,
                onSend: _send,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Row widget ───────────────────────────────────────────────────────────────

class _ComposerRow extends StatelessWidget {
  const _ComposerRow({
    required this.ctrl,
    required this.focus,
    required this.hasText,
    required this.hintText,
    required this.fieldFill,
    required this.borderColor,
    required this.hintColor,
    required this.textColor,
    required this.onPlusTap,
    required this.onSend,
  });

  final TextEditingController ctrl;
  final FocusNode focus;
  final ValueNotifier<bool> hasText;
  final String hintText;
  final Color fieldFill;
  final Color borderColor;
  final Color hintColor;
  final Color textColor;
  final VoidCallback onPlusTap;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── + attachment button ───────────────────────────────────────────────
        _PlusButton(onTap: onPlusTap),
        const SizedBox(width: 8),

        // ── text field ────────────────────────────────────────────────────────
        Expanded(
          child: TextField(
            controller: ctrl,
            focusNode: focus,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor, fontSize: 15),
              filled: true,
              fillColor: fieldFill,
              isDense: false,
              // Taller comfortable padding (vertical: 13 → ~48px single-line)
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(color: borderColor, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(color: borderColor, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(
                  color: const Color(0xFF8E2DE2).withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // ── send button ──────────────────────────────────────────────────────
        const SizedBox(width: 8),
        ValueListenableBuilder<bool>(
          valueListenable: hasText,
          builder: (_, hasT, __) =>
              _SendIconButton(hasText: hasT, onTap: onSend),
        ),
      ],
    );
  }
}

// ─── + button ─────────────────────────────────────────────────────────────────

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B2B35) : cs.surfaceContainerHigh,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : cs.outline.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          color: cs.onSurface.withValues(alpha: 0.75),
          size: 26,
        ),
      ),
    );
  }
}

// ─── Send icon button ────────────────────────────────────────────────────────

/// Always-visible send icon. When [hasText] is false the icon is muted gray;
/// when true it smoothly animates to the theme primary color.
/// Tapping while [hasText] is false is a no-op.
class _SendIconButton extends StatelessWidget {
  const _SendIconButton({required this.hasText, required this.onTap});
  final bool hasText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30);

    return GestureDetector(
      onTap: hasText ? onTap : null,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: hasText ? muted : primary,
              end: hasText ? primary : muted,
            ),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            builder: (_, color, __) => Image.asset(
              'assets/icons/send-icon.png',
              height: 36,
              color: color,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
