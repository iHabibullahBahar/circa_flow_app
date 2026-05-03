import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_card.dart';

class CommunitiesScreen extends GetView<CommunityController> {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            preferredSize: const Size.fromHeight(110),
            child: Column(
              children: [
                _buildSearchBar(context),
                TabBar(
                  indicatorColor: cs.primary,
                  indicatorWeight: 3,
                  labelColor: cs.primary,
                  labelStyle:
                      tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  unselectedLabelColor: cs.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'My Communities'),
                    Tab(text: 'Discover'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context, isMine: true),
            _buildList(context, isMine: false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showJoinByCodeSheet(context),
          icon: const Icon(Icons.add_link_rounded),
          label: const Text('Join via Code'),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search communities...',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: context.contextTheme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
        return const Center(child: CircularProgressIndicator.adaptive());
      }

      if (list.isEmpty) {
        return _buildEmptyState(context, isMine);
      }

      return RefreshIndicator(
        onRefresh: () async => controller.refreshData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
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
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_rounded,
                size: 80, color: cs.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              isMine ? 'No Communities Yet' : 'No Communities Found',
              style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: const Color(0xFF1A334D)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isMine
                  ? 'You haven\'t joined any communities yet.\nCheck the Discover tab or use an invite code.'
                  : 'Try adjusting your search or use an invite code if you have one.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinByCodeSheet(BuildContext context) {
    final codeController = TextEditingController();
    final cs = context.contextTheme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join via Code',
                style: context.contextTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Get.back<void>();
                  controller.lookupAndJoinCode(codeController.text);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lookup & Join'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
