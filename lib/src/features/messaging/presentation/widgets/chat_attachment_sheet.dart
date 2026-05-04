import 'package:flutter/material.dart';

/// Shows the LazyChat-style attachment bottom sheet.
///
/// Reusable — pass only the callbacks you need. null = item hidden.
/// Currently supports: Gallery, Camera, Audio.
void showChatAttachmentSheet(
  BuildContext context, {
  VoidCallback? onGallery,
  VoidCallback? onCamera,
  VoidCallback? onAudio,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AttachmentSheet(
      onGallery: onGallery,
      onCamera: onCamera,
      onAudio: onAudio,
    ),
  );
}

// ─── Sheet widget ─────────────────────────────────────────────────────────────

class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet({this.onGallery, this.onCamera, this.onAudio});
  final VoidCallback? onGallery;
  final VoidCallback? onCamera;
  final VoidCallback? onAudio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C1C22) : cs.surface;

    final items = <_SheetItem>[
      if (onGallery != null)
        _SheetItem(
          icon: Icons.photo_library_rounded,
          label: 'Gallery',
          color: const Color(0xFF4A00E0),
          onTap: () {
            Navigator.pop(context);
            onGallery!();
          },
        ),
      if (onCamera != null)
        _SheetItem(
          icon: Icons.camera_alt_rounded,
          label: 'Camera',
          color: const Color(0xFF0097A7),
          onTap: () {
            Navigator.pop(context);
            onCamera!();
          },
        ),
      if (onAudio != null)
        _SheetItem(
          icon: Icons.mic_rounded,
          label: 'Audio',
          color: const Color(0xFF388E3C),
          onTap: () {
            Navigator.pop(context);
            onAudio!();
          },
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Item grid — always a single row for now (3 items max)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.map((item) => _AttachmentItem(item: item)).toList(),
          ),

          // Respect bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ─── Item model ───────────────────────────────────────────────────────────────

class _SheetItem {
  const _SheetItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

// ─── Single attachment item ────────────────────────────────────────────────────

class _AttachmentItem extends StatelessWidget {
  const _AttachmentItem({required this.item});
  final _SheetItem item;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: item.onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular icon container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withValues(alpha: 0.15),
                border: Border.all(
                  color: item.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
