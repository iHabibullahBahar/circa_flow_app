import 'package:circa_flow_main/src/imports/imports.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_card.dart';

class CommunitiesScreen extends GetView<CommunityController> {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Communities',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A334D),
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(105),
          child: Column(
            children: [
              _buildSearchBar(context),
              Obx(() => Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _TabItem(
                          label: 'My Communities',
                          isSelected: controller.currentTab.value ==
                              CommunityTab.myCommunities,
                          onTap: () =>
                              controller.setTab(CommunityTab.myCommunities),
                        ),
                        _TabItem(
                          label: 'Discover',
                          isSelected: controller.currentTab.value ==
                              CommunityTab.discover,
                          onTap: () => controller.setTab(CommunityTab.discover),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
      body: Obx(() {
        final isMine =
            controller.currentTab.value == CommunityTab.myCommunities;
        return _buildList(context, isMine: isMine);
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJoinByCodeSheet(context),
        icon: const Icon(Icons.add_link_rounded),
        label: const Text('Join via Code'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: TextField(
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search communities...',
            hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 14.sp),
            prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, {required bool isMine}) {
    return Obx(() {
      final isLoading = isMine
          ? controller.isLoadingMine.value
          : controller.isLoadingAll.value;
      final list = isMine
          ? controller.filteredMyCommunities
          : controller.filteredAllCommunities;

      if (isLoading && list.isEmpty) {
        return AppShimmer(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => Container(
              height: 180.h,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        );
      }

      if (list.isEmpty) {
        return _buildEmptyState(context, isMine);
      }

      return RefreshIndicator(
        onRefresh: () async => controller.refreshData(),
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 100.h),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final community = list[index];
            return CommunityCard(
              community: community,
              onJoin: () => controller.joinCommunity(community),
              onLeave: () => controller.leaveCommunity(community),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, bool isMine) {
    return Center(
      child: AppEmptyState(
        icon: Icons.groups_rounded,
        title: isMine ? 'No Communities Yet' : 'No Communities Found',
        subtitle: isMine
            ? 'You haven\'t joined any communities yet.\nCheck the Discover tab or use an invite code.'
            : 'Try adjusting your search or use an invite code if you have one.',
        onAction: isMine ? null : controller.refreshData,
        actionLabel: isMine ? null : 'Refresh',
      ),
    );
  }

  void _showJoinByCodeSheet(BuildContext context) {
    final codeController = TextEditingController();
    final cs = context.contextTheme.colorScheme;
    
    // Reset state when opening
    controller.lookupError.value = '';
    controller.foundCommunity.value = null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: Obx(() {
            final community = controller.foundCommunity.value;
            
            return AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  if (community == null) ...[
                    Text(
                      'Join via Code',
                      style: context.contextTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A334D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the secret code or slug to join a hidden community.',
                      style: context.contextTheme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: codeController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Community Code',
                        hintText: 'e.g., vip-members-2026',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.key_rounded),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                      ),
                      onChanged: (_) => controller.lookupError.value = '',
                      onSubmitted: (_) => controller.lookupAndJoinCode(codeController.text),
                    ),
                    if (controller.lookupError.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          controller.lookupError.value,
                          style: TextStyle(color: cs.error, fontSize: 12.sp, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Lookup Community',
                      isLoading: controller.isLookingUp.value,
                      onPressed: () => controller.lookupAndJoinCode(codeController.text),
                      variant: ButtonVariant.primary,
                      isFullWidth: true,
                    ),
                  ] else ...[
                    Text(
                      'Community Found!',
                      style: context.contextTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A334D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    CommunityCard(
                      community: community,
                      onJoin: () {
                        Get.back<void>();
                        controller.joinCommunity(community);
                      },
                      onLeave: () => controller.leaveCommunity(community),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Try another code',
                      variant: ButtonVariant.ghost,
                      onPressed: () {
                        controller.foundCommunity.value = null;
                        codeController.clear();
                      },
                      isFullWidth: true,
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                label,
                style: tt.titleSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
