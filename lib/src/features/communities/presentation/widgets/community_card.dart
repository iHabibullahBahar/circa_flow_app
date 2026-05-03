import 'package:circa_flow_main/src/imports/imports.dart';
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image with Badges
            Stack(
              children: [
                if (community.coverImageUrl != null &&
                    community.coverImageUrl!.isNotEmpty)
                  AppCachedImage(
                    imageUrl: community.coverImageUrl!,
                    height: 120.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  _buildPlaceholder(cs),
                
                // Visibility Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildVisibilityBadge(cs, tt),
                ),

                // Role Badge (if member)
                if (community.myRole != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildRoleBadge(cs, tt),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      fontSize: 18.sp,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (community.description != null &&
                      community.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      community.description!,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(height: 1),
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
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Container(
      height: 120.h,
      width: double.infinity,
      color: cs.primaryContainer.withValues(alpha: 0.3),
      child: Center(
        child: Icon(Icons.groups_rounded,
            size: 40, color: cs.primary.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildVisibilityBadge(ColorScheme cs, TextTheme tt) {
    final isPublic = community.type == 'public';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: tt.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(ColorScheme cs, TextTheme tt) {
    final role = community.myRole?.toLowerCase();
    Color badgeColor = cs.secondary;
    if (role == 'owner') badgeColor = Colors.amber.shade700;
    if (role == 'moderator') badgeColor = Colors.blue.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        role?.toUpperCase() ?? 'MEMBER',
        style: tt.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 9.sp,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMemberCount(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.people_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            '${community.memberCount} members',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    
    if (community.isMember) {
      return AppButton(
        label: 'Leave',
        onPressed: community.isDefault ? null : onLeave,
        variant: ButtonVariant.ghost,
        textColor: cs.error,
        height: ButtonSize.small,
      );
    }

    if (community.isPending) {
      return AppButton(
        label: 'Withdraw',
        onPressed: onLeave,
        variant: ButtonVariant.ghost,
        textColor: cs.error,
        height: ButtonSize.small,
      );
    }

    if (community.myStatus == 'blocked') {
      return const SizedBox.shrink();
    }

    if (community.joinType == 'invite_only') {
      return const AppButton(
        label: 'Invite Only',
        onPressed: null,
        variant: ButtonVariant.secondary,
        height: ButtonSize.small,
      );
    }

    if (community.isRejected) {
      return AppButton(
        label: 'Request Again',
        onPressed: onJoin,
        variant: ButtonVariant.primary,
        height: ButtonSize.small,
      );
    }

    return AppButton(
      label: community.joinType == 'open' ? 'Join' : 'Request',
      onPressed: onJoin,
      variant: ButtonVariant.primary,
      height: ButtonSize.small,
    );
  }
}
