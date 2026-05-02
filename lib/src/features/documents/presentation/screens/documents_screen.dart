import 'package:circa_flow_main/src/imports/imports.dart';
import '../providers/documents_controller.dart';
import '../../data/models/document_model.dart';

class DocumentsScreen extends GetView<DocumentsController> {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.hasError.value) {
          return _ErrorView(onRetry: controller.refreshData);
        }

        if (controller.documents.isEmpty && !controller.isLoading.value) {
          return const _EmptyView();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: cs.primary,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.documents.length +
                  (controller.isLoading.value ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                if (i >= controller.documents.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.primary),
                    ),
                  );
                }
                return _DocumentTile(doc: controller.documents[i]);
              },
            ),
          ),
        );
      }),
    );
  }
}

// ── Document Tile ─────────────────────────────────────────────────────────────

class _DocumentTile extends StatefulWidget {
  final DocumentModel doc;
  const _DocumentTile({required this.doc});

  @override
  State<_DocumentTile> createState() => _DocumentTileState();
}

class _DocumentTileState extends State<_DocumentTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    final hasAttachments = widget.doc.attachments.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => Get.toNamed<void>(
              AppRoutes.documentDetail,
              arguments: widget.doc,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.doc.fileIcon, color: cs.primary, size: 24),
            ),
            title: Text(
              widget.doc.title,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  if (widget.doc.fileType != null) ...[
                    Text(
                      widget.doc.fileType!.toUpperCase(),
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.doc.fileSizeBytes != null)
                    Text(
                      widget.doc.fileSizeFormatted,
                      style:
                          tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  if (hasAttachments) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.doc.attachments.length} FILES',
                        style: tt.labelSmall?.copyWith(
                          fontSize: 8.sp,
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: cs.outline),
          ),
          if (_isExpanded && hasAttachments)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...widget.doc.attachments.map((file) => _AttachmentItem(
                        file: file,
                        onTap: () => _openFile(file.url, file.name),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openFile(String url, String title) {
    Get.toNamed<void>(
      AppRoutes.webview,
      arguments: WebViewArgs(
        url: url,
        title: title,
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final DocumentAttachment file;
  final VoidCallback onTap;

  const _AttachmentItem({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(file.icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file.name,
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.download_rounded, size: 16, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

// ── Empty & Error states ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 56, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No documents yet',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: cs.error),
          const SizedBox(height: 16),
          Text('Could not load documents',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry',
            onPressed: onRetry,
            variant: ButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
