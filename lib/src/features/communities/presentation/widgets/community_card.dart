import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import '../../data/models/community_model.dart';

class CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const CommunityCard({
    super.key,
    required this.community,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.appColors.border.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover Image
          if (community.coverImageUrl != null &&
              community.coverImageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: community.coverImageUrl!,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 120,
                color: cs.surfaceContainerHighest,
                child:
                    const Center(child: CircularProgressIndicator.adaptive()),
              ),
              errorWidget: (context, url, error) => _buildPlaceholder(cs),
            )
          else
            _buildPlaceholder(cs),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        community.name,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A334D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildVisibilityBadge(cs, tt),
                  ],
                ),
                if (community.description != null &&
                    community.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    community.description!,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMemberCount(cs, tt),
                    _buildActionButton(context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Container(
      height: 120,
      color: cs.primary.withValues(alpha: 0.05),
      child: Center(
        child: Icon(Icons.groups_rounded,
            size: 48, color: cs.primary.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildVisibilityBadge(ColorScheme cs, TextTheme tt) {
    final isPublic = community.type == 'public';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublic
            ? cs.primary.withValues(alpha: 0.1)
            : cs.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPublic ? 'Public' : 'Private',
        style: tt.labelSmall?.copyWith(
          color: isPublic ? cs.primary : cs.tertiary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMemberCount(ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Icon(Icons.people_outline_rounded,
            size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '${community.memberCount} members',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (community.isMember) {
      return TextButton(
        onPressed: community.isDefault ? null : onLeave,
        style: TextButton.styleFrom(
          foregroundColor: context.contextTheme.colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Leave'),
      );
    }

    if (community.isPending) {
      return OutlinedButton(
        onPressed: null, // Disabled
        child: const Text('Requested'),
      );
    }

    if (community.myStatus == 'blocked') {
      return const SizedBox.shrink(); // Hide button completely
    }

    if (community.joinType == 'invite_only') {
      return OutlinedButton(
        onPressed: null,
        child: const Text('Invite Only'),
      );
    }

    if (community.isRejected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.contextTheme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Rejected',
              style: context.contextTheme.textTheme.labelSmall?.copyWith(
                color: context.contextTheme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onJoin,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Request Again'),
          ),
        ],
      );
    }

    // Can request or join instantly
    return FilledButton(
      onPressed: onJoin,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(community.joinType == 'open' ? 'Join' : 'Request'),
    );
  }
}
