import '../../../../imports/imports.dart';
import '../../data/models/document_model.dart';

class DocumentDetailScreen extends StatelessWidget {
  final DocumentModel doc;
  const DocumentDetailScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back<void>(),
        ),
        title: Text(
          'Document Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Hero Header with Icon ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.03),
                border: Border(
                  bottom: BorderSide(color: context.appColors.border),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(doc.fileIcon, color: cs.primary, size: 48),
                  ),
                  const Gap(24),
                  Text(
                    doc.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  if (doc.fileType != null || doc.fileSizeBytes != null) ...[
                    const Gap(12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (doc.fileType != null)
                          _buildBadge(cs, doc.fileType!.toUpperCase()),
                        if (doc.fileType != null && doc.fileSizeBytes != null)
                          const Gap(12),
                        if (doc.fileSizeBytes != null)
                          Text(
                            doc.fileSizeFormatted,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Description ---
                  if (doc.description != null &&
                      doc.description!.isNotEmpty) ...[
                    Text(
                      'About this Document',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      doc.description!,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.black87.withValues(alpha: 0.7),
                        height: 1.6,
                      ),
                    ),
                    const Gap(32),
                  ],

                  // --- Files Section ---
                  Text(
                    'Files',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const Gap(16),

                  // Primary Download Button
                  if (doc.downloadUrl != null)
                    _FileDownloadCard(
                      title: 'Primary Document',
                      url: doc.downloadUrl!,
                      type: doc.fileType ?? 'FILE',
                      isPrimary: true,
                    ),

                  // Attachments
                  if (doc.attachments.isNotEmpty) ...[
                    if (doc.downloadUrl != null) const Gap(12),
                    ...doc.attachments.map((file) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FileDownloadCard(
                            title: file.name,
                            url: file.url,
                            type: file.type,
                          ),
                        )),
                  ],

                  const Gap(40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(ColorScheme cs, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _FileDownloadCard extends StatelessWidget {
  final String title;
  final String url;
  final String type;
  final bool isPrimary;

  const _FileDownloadCard({
    required this.title,
    required this.url,
    required this.type,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return InkWell(
      onTap: () => _handleDownload(url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? cs.primary.withValues(alpha: 0.05) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? cs.primary.withValues(alpha: 0.2)
                : context.appColors.border,
            width: isPrimary ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(type),
                color: cs.primary,
                size: 22,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove_red_eye,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) => switch (type.toLowerCase()) {
        'pdf' => Icons.picture_as_pdf_rounded,
        'doc' || 'docx' => Icons.description_rounded,
        'xls' || 'xlsx' => Icons.table_chart_rounded,
        _ => Icons.insert_drive_file_rounded,
      };

  void _handleDownload(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
