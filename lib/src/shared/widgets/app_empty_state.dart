import 'package:circa_flow_main/src/imports/imports.dart';

/// Displays an empty state with an icon, title, optional subtitle, and action.
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.inbox_outlined,
///   title: 'No messages yet',
///   subtitle: 'Your inbox will appear here.',
///   actionLabel: 'Refresh',
///   onAction: _refresh,
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = HugeIcons.strokeRoundedInbox,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final dynamic icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon is IconData)
              Icon(icon, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.5))
            else
              HugeIcon(icon: icon, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text(
              title,
              style: tt.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: ButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
